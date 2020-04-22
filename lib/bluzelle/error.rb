# frozen_string_literal: true

module Bluzelle
  module Error
    class Error < StandardError
      attr_reader :code

      def initialize(msg = 'Error occurred', code = nil)
        super(msg)
        @code = code
      end
    end

    class ApiError < Error
    end
  end
end
