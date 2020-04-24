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
        case e.http_code
        when 404, 500
          raise Error::ApiError, e.response.body
        else
          error(e)
        end
      else
        success(resp)
      end

      private

      def error(err)
        body = JSON.parse(err.response.body)
        error_message = body.dig('error', 'message')

        if error_message.is_a?(String)
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
