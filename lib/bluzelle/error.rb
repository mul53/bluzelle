module Bluzelle
    module Error
        class Error < StandardError
            attr_reader :code
            attr_reader :message

            def initialize(message = '', code = nil)
                super(message)
                @code = code
            end
        end

        class ApiError < Error
        end
    end
end