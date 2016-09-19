# Puffin Ruby Bindings
# View api docs here: api-docs.puffin.ly
# Much of the connection logic was borrowed from Stripe's Ruby client
# because it's excellent and fitted our needs nicely with few adaptions
require 'cgi'
require 'openssl'
require 'rbconfig'
require 'set'
require 'socket'

require 'rest-client'
require 'json'

require 'puffin/version'
require 'puffin/util'

module Puffin

  @api_base = 'https://api.puffin.ly'
  @max_network_retries = 10
  @verify_ssl_certs = true
  @open_timeout = 30
  @read_timeout = 80

  class << self
    attr_accessor :puffin_account, :verify_ssl_certs, :api_token,
                  :open_timeout, :read_timeout, :puffin_env
  end

  def self.api_url(url='', api_base_url=nil)
    (api_base_url || @api_base) + url
  end

  def self.request(method, url, api_token, params={}, headers={}, api_base_url=nil)
    api_base_url = api_base_url || @api_base

    unless api_token ||= @api_token
      raise AuthenticationError.new('No API key provided. ' \
        'Set your API token using "Puffing.api_token = <API-TOKEN>". ' \
        'You generate API keys from the Puffing interface. ')
    end

    if api_token =~ /\s/
      raise AuthenticationError.new('Your API key is invalid, as it contains ' \
        'whitespace.')
    end

    if verify_ssl_certs
      request_opts = { verify_ssl: OpenSSL::SSL::VERIFY_PEER }
      # request_opts = {:verify_ssl => OpenSSL::SSL::VERIFY_PEER,
      #                 :ssl_cert_store => ca_store}
    else
      request_opts = {:verify_ssl => false}
      unless @verify_ssl_warned
        @verify_ssl_warned = true
        $stderr.puts("WARNING: Running without SSL cert verification. " \
          "You should never do this in production. " \
          "Execute 'Puffin.verify_ssl_certs = true' to enable verification.")
      end
    end

    params = Util.objects_to_ids(params)
    url = api_url(url, api_base_url)

    case method.to_s.downcase.to_sym
    when :get, :head, :delete
      # Make params into GET parameters
      url += "#{URI.parse(url).query ? '&' : '?'}#{Util.encode_parameters(params)}" if params && params.any?
      payload = nil
    else
      if headers[:content_type] && headers[:content_type] == "multipart/form-data"
        payload = params
      else
        payload = Util.encode_parameters(params)
      end
    end

    request_opts.update(:headers => request_headers(api_token, method).update(headers),
                        :method => method, :open_timeout => open_timeout,
                        :payload => payload, :url => url, :timeout => read_timeout)

    response = execute_request_with_rescues(request_opts, api_base_url)

    [parse(response), api_token]
  end

  def self.max_network_retries
    @max_network_retries
  end

  def self.max_network_retries=(val)
    @max_network_retries = val.to_i
  end

  def self.request_headers(api_token, method)
    headers = {
      'User-Agent' => "Puffin/v1 RubyBindings/#{Puffin::VERSION}",
      'Authorization' => "Bearer #{api_token}",
      'Content-Type' => 'application/x-www-form-urlencoded'
    }

    headers['Puffin-Env']     = puffin_env if puffin_env
    headers['Puffin-Account'] = puffin_account if puffin_account

    begin
      headers.update('X-Puffin-Client-User-Agent' => JSON.generate(user_agent))
    rescue => e
      headers.update('X-Puffin-Client-Raw-User-Agent' => user_agent.inspect,
                     :error => "#{e} (#{e.class})")
    end
  end

  private

  def self.user_agent
    @uname ||= get_uname
    lang_version = "#{RUBY_VERSION} p#{RUBY_PATCHLEVEL} (#{RUBY_RELEASE_DATE})"

    {
      :bindings_version => Puffin::VERSION,
      :lang => 'ruby',
      :lang_version => lang_version,
      :platform => RUBY_PLATFORM,
      :engine => defined?(RUBY_ENGINE) ? RUBY_ENGINE : '',
      :publisher => 'puffin',
      :uname => @uname,
      :hostname => Socket.gethostname,
    }
  end

  def self.get_uname
    if File.exist?('/proc/version')
      File.read('/proc/version').strip
    else
      case RbConfig::CONFIG['host_os']
      when /linux|darwin|bsd|sunos|solaris|cygwin/i
        _uname_uname
      when /mswin|mingw/i
        _uname_ver
      else
        "unknown platform"
      end
    end
  end

  def self._uname_uname
    (`uname -a 2>/dev/null` || '').strip
  rescue Errno::ENOMEM # couldn't create subprocess
    "uname lookup failed"
  end

  def self.parse(response)
    begin
      # Would use :symbolize_names => true, but apparently there is
      # some library out there that makes symbolize_names not work.
      response = JSON.parse(response.body)
    rescue JSON::ParserError
      raise general_api_error(response.code, response.body)
    end

    Util.symbolize_names(response)
  end

  def self.execute_request_with_rescues(request_opts, api_base_url, retry_count = 0)
    begin
      response = execute_request(request_opts)

    # We rescue all exceptions from a request so that we have an easy spot to
    # implement our retry logic across the board. We'll re-raise if it's a type
    # of exception that we didn't expect to handle.
    rescue => e
      if should_retry?(e, retry_count)
        retry_count = retry_count + 1
        sleep sleep_time(retry_count)
        retry
      end

      case e
      when SocketError
        response = handle_restclient_error(e, request_opts, retry_count, api_base_url)

      when RestClient::ExceptionWithResponse
        if e.response
          handle_api_error(e.response)
        else
          response = handle_restclient_error(e, request_opts, retry_count, api_base_url)
        end

      when RestClient::Exception, Errno::ECONNREFUSED, OpenSSL::SSL::SSLError
        response = handle_restclient_error(e, request_opts, retry_count, api_base_url)

      # Only handle errors when we know we can do so, and re-raise otherwise.
      # This should be pretty infrequent.
      else
        raise
      end
    end

    response
  end

  def self.execute_request(opts)
    RestClient::Request.execute(opts)
  end
end
