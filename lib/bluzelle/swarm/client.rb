module Bluzelle
    module Swarm
        class Client
            attr_reader :address, :mnemonic, :uuid, :chain_id, :endpoint

            # Initializes a new client object

            # @param options [Hash]
            # @return [Bluzelle::Swarm::Client]
            def initialize(options = {})
                raise ArgumentError.new('Address must be a string') unless options[:address].is_a?(String)
                raise ArgumentError.new('Mnemonic must be a string') unless options[:mnemonic].is_a?(String)
                
                @address = options[:address]
                @mnemonic = options[:mnemonic]
                @uuid = options[:uuid] || @address
                @chain_id = options[:chain_id] || 'bluzelle'
                @endpoint = options[:endpoint] || 'http://localhost:1317'
            end
        end
    end
end