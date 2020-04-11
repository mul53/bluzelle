module Bluzelle
    module Swarm
        class Client
            attr_reader :address, :mnemonic, :uuid, :chain_id, :endpoint

            # Initializes a new client object

            # @param options [Hash]
            # @return [Bluzelle::Swarm::Client]
            def initialize(options = {})
                validate_string(options[:address], 'Address must be a string.')
                validate_string(options[:mnemonic], 'Mnemonic must be a string.')
                
                @address = options[:address]
                @mnemonic = options[:mnemonic]
                @uuid = options[:uuid] || @address
                @chain_id = options[:chain_id] || 'bluzelle'
                @endpoint = options[:endpoint] || 'http://localhost:1317'
            end

            private
            def validate_string(arg, msg)
                raise ArgumentError.new(msg) unless arg.is_a?(String)
            end
        end
    end
end