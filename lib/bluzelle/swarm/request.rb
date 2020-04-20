# frozen_string_literal: true

require 'rest-client'

module Bluzelle
  module Swarm
    class Request
      def initialize(method, url, payload = {}, options = {})
        @method = method
        @url = url
        @payload = JSON.generate(payload)
        @headers = options.dig(:headers)
      end

      def execute
        resp = RestClient::Request.execute(
          method: @method,
          url: @url,
          payload: @payload,
          headers: @headers
        )
      rescue RestClient::ExceptionWithResponse => e
        error(e)
      else
        success(resp)
      end

      def error(e)
        res = JSON.generate(e.response)
        error_message = res.dig('error', 'message') if res.is_a?(Hash)

        if res.is_a?(String)
          raise Error::ApiError, res
        elsif res.dig('error', 'message').is_a?(String)
          raise Error::ApiError, error_message
        else
          raise Error::ApiError, 'error occurred'
        end
      end

      def success(resp)
        JSON.parse(resp.body)
      end
    end
  end
end
