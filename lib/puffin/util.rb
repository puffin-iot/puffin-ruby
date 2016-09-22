module Puffin
  module Util
    def self.objects_to_ids(h)
      case h
      when APIResource
        h.id
      when Hash
        res = {}
        h.each { |k, v| res[k] = objects_to_ids(v) unless v.nil? }
        res
      when Array
        h.map { |v| objects_to_ids(v) }
      else
        h
      end
    end

    def self.url_encode(key)
      CGI.escape(key.to_s).
        # Don't use strict form encoding by changing the square bracket control
        # characters back to their literals. This is fine by the server, and
        # makes these parameter strings easier to read.
        gsub('%5B', '[').gsub('%5D', ']')
    end

    # Encodes a hash of parameters in a way that's suitable for use as query
    # parameters in a URI or as form parameters in a request body. This mainly
    # involves escaping special characters from parameter keys and values (e.g.
    # `&`).
    def self.encode_parameters(params)
      Util.flatten_params(params).
        map { |k,v| "#{url_encode(k)}=#{url_encode(v)}" }.join('&')
    end

    def self.flatten_params(params, parent_key=nil)
      result = []

      # do not sort the final output because arrays (and arrays of hashes
      # especially) can be order sensitive, but do sort incoming parameters
      params.each do |key, value|
        calculated_key = parent_key ? "#{parent_key}[#{key}]" : "#{key}"
        if value.is_a?(Hash)
          result += flatten_params(value, calculated_key)
        elsif value.is_a?(Array)
          check_array_of_maps_start_keys!(value)
          result += flatten_params_array(value, calculated_key)
        else
          result << [calculated_key, value]
        end
      end

      result
    end

    def self.symbolize_names(object)
      case object
      when Hash
        new_hash = {}
        object.each do |key, value|
          key = (key.to_sym rescue key) || key
          new_hash[key] = symbolize_names(value)
        end
        new_hash
      when Array
        object.map { |value| symbolize_names(value) }
      else
        object
      end
    end

    def self.normalize_opts(opts)
      case opts
      when String
        { api_token: opts }
      when Hash
        check_api_token!(opts.fetch(:api_token)) if opts.has_key?(:api_token)
        opts.clone
      else
        raise TypeError.new('normalize_opts expects a string or a hash')
      end
    end

    def self.normalize_id(id)
      if id.kind_of?(Hash) # overloaded id
        params_hash = id.dup
        id = params_hash.delete(:id)
      else
        params_hash = {}
      end
      [id, params_hash]
    end

    def self.convert_to_puffin_object(resp, opts)
      case resp
      when Array
        resp.map { |i| convert_to_puffin_object(i, opts) }
      when Hash
        object_classes.fetch(resp[:object], PuffinObject).construct_from(resp, opts)
      else
        resp
      end
    end

    def self.check_api_token!(token)
      raise TypeError.new("api_token must be a string") unless token.is_a?(String)
      token
    end

    def self.object_classes
      @object_classes ||= {
        'list' => ListObject,
        'device' => Device,
        'operation' => Operation
      }
    end
  end
end
