module Bluzelle
    module Swarm
        class Client
            attr_reader :address, :mnemonic, :uuid, :chain_id, :endpoint

            # Initializes a new client object

            # @param options [Hash]
            # @return [Bluzelle::Swarm::Client]
            def initialize(options = {})
                if options[:address].nil? || options[:mnemonic].nil?
                    raise ArgumentError
                end
                
                @address = options[:address]
                @mnemonic = options[:mnemonic]
                @uuid = options[:uuid] || @address
                @chain_id = options[:chain_id] || 'bluzelle'
                @endpoint = options[:endpoint] || 'http://localhost:1317'
            end
        end
    end
end