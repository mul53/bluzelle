# frozen_string_literal: true

module Bluzelle
  module Error
    class Error < StandardError
      def initialize(msg = 'Error occurred')
        super(msg)
      end
    end

    class ApiError < Error
      def initialize(msg)
        super("Api: #{msg}")
      end
    end
  end
end
