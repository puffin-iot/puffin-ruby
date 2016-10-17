# Puffin Ruby Bindings
# View api docs here: api-docs.puffin.ly
# Much of the connection logic was borrowed from Stripe's Ruby client
# because it's excellent and fitted our needs nicely with few adaptions
# require 'cgi'
# require 'openssl'
# require 'rbconfig'
require 'set'
# require 'socket'

require 'rest-client'
require 'json'

require 'puffin/api_operations/create'
require 'puffin/api_operations/save'
require 'puffin/api_operations/delete'
require 'puffin/api_operations/list'
require 'puffin/api_operations/request'

require 'puffin/puffin_object'
require 'puffin/list_object'
require 'puffin/api_resource'
require 'puffin/device'
require 'puffin/operation'
require 'puffin/version'
require 'puffin/util'

require 'puffin/errors/puffin_error'
require 'puffin/errors/authentication_error'
require 'puffin/errors/connection_error'
require 'puffin/errors/api_error'

module Puffin
  @api_base = ENV['API_HOST'] || 'https://api.puffin.ly'
  puts "Setting API Base to #{@api_base}"

  @max_network_retries = 10
  @verify_ssl_certs = true
  @open_timeout = 30
  @read_timeout = 80

  RETRY_EXCEPTIONS = [
    # Destination refused the connection. This could occur from a single
    # saturated server, so retry in case it's intermittent.
    Errno::ECONNREFUSED,

    # Connection reset. This occasionally occurs on a server problem, and
    # deserves a retry because the server should terminate all requests
    # properly even if they were invalid.
    Errno::ECONNRESET,

    # Timed out making the connection. It's worth retrying under this
    # circumstance.
    Errno::ETIMEDOUT,

    # Retry on timeout-related problems. This shouldn't be lumped in with HTTP
    # exceptions, but with RestClient it is.
    RestClient::RequestTimeout,
  ].freeze

  class << self
    attr_accessor :puffin_account, :verify_ssl_certs, :api_token,
                  :open_timeout, :read_timeout, :puffin_env, :api_base,
                  :puffin_host
  end

  def self.api_url(url='', api_base_url=nil)
    (api_base_url || @api_base) + url
  end

  def self.request(method, url, api_token, params={}, headers={}, api_base_url=nil)
    api_base_url = api_base_url || @api_base

    unless api_token ||= @api_token
      raise AuthenticationError.new('No API key provided. ' \
        'Set your API token using "Puffin.api_token = [YOUR-API-TOKEN]". ' \
        'You generate API keys from the Puffing interface. If in double, '\
        'double check the docs :- docs.puffin.ly')
    end

    if api_token =~ /\s/
      raise AuthenticationError.new('Your API token contains whitespace' \
        'Please check your token again.')
    end

    if verify_ssl_certs
      request_opts = { verify_ssl: OpenSSL::SSL::VERIFY_PEER }
    else
      request_opts = {:verify_ssl => false}
      unless @verify_ssl_warned
        @verify_ssl_warned = true
        $stderr.puts("WARNING: Running without SSL cert verification is not cool. " \
          "You should never do this in production!!" \
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
      'User-Agent' => "Puffin/v1 Ruby/#{Puffin::VERSION}",
      'Authorization' => "Bearer #{api_token}",
      'Content-Type' => 'application/x-www-form-urlencoded'
    }
    headers['Puffin-Env']     = puffin_env if puffin_env

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
    ### We sometimes send 204s back from the API when something is deleted
    ### Perhaps we should change all these to 200s rather than updating the
    ### entire function and faking an error
    begin
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

  def self.should_retry?(e, retry_count)
    retry_count < self.max_network_retries &&
      RETRY_EXCEPTIONS.any? { |klass| e.is_a?(klass) }
  end

  def self.handle_api_error(resp)
    begin
      error_obj = JSON.parse(resp.body)
      error_obj = Util.symbolize_names(error_obj)
      error = error_obj[:error]
      raise PuffinError.new unless error && error.is_a?(Hash)

    rescue JSON::ParserError, PuffinError
      raise general_api_error(resp.code, resp.body)
    end

    case resp.code
    when 400, 404, 422
      raise invalid_request_error(error, resp, error_obj)
    when 401
      raise authentication_error(error, resp, error_obj)
    when 429
      raise rate_limit_error(error, resp, error_obj)
    else
      raise api_error(error, resp, error_obj)
    end
  end

  def self.invalid_request_error(error, resp, error_obj)
    InvalidRequestError.new(error[:message], error[:param], resp.code,
                            resp.body, error_obj, resp.headers)
  end

  def self.authentication_error(error, resp, error_obj)
    AuthenticationError.new(error[:message], resp.code, resp.body, error_obj,
                            resp.headers)
  end

  def self.rate_limit_error(error, resp, error_obj)
    RateLimitError.new(error[:message], resp.code, resp.body, error_obj,
                       resp.headers)
  end

  def self.api_error(error, resp, error_obj)
    APIError.new(error[:message], resp.code, resp.body, error_obj, resp.headers)
  end

  def self.general_api_error(rcode, rbody)
    APIError.new("Invalid response object from API: #{rbody.inspect} " +
                 "(HTTP response code was #{rcode})", rcode, rbody)
  end

  def self.handle_restclient_error(e, request_opts, retry_count, api_base_url=nil)

    api_base_url = @api_base unless api_base_url
    connection_message = "Please check your internet connection and try again. " \
      "If this problem persists, you should check the service status."

    case e
    when RestClient::RequestTimeout
      message = "Could not connect to Puffin (#{api_base_url}). #{connection_message}"

    when RestClient::ServerBrokeConnection
      message = "The connection to the server (#{api_base_url}) broke before the " \
        "request completed. #{connection_message}"

    when OpenSSL::SSL::SSLError
      message = "Could not establish a secure connection, you may " \
                "need to upgrade your OpenSSL version. To check, try running " \
                "'openssl s_client -connect api.puffin.com:443' from the " \
                "command line."

    when RestClient::SSLCertificateNotVerified
      message = "Could not verify the SSL certificate. " \
        "Please make sure that your network is not intercepting certificates."

    when SocketError
      message = "Unexpected error communicating when trying to connect to Puffin. " \
        "You may be seeing this message because your DNS is not working. " \
        "To check, try running 'host stripe.com' from the command line."

    else
      message = "Unexpected error communicating with Puffin. " \
        "If this problem persists, let us know at help@puffin.ly."
    end

    if retry_count > 0
      message += " Request was retried #{retry_count} times."
    end

    raise ConnectionError.new(message + "\n\n(Network error: #{e.message})")
  end
end
