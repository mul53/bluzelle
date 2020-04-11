module Bluzelle
    module Swarm
        class Client
            attr_reader :address, :mnemonic, :uuid, :chain_id, :endpoint

            def initialize(options = {})
                @address = options[:address]
                @mnemonic = options[:mnemonic]
                @uuid = options[:uuid]
                @chain_id = options[:chain_id] || 'bluzelle'
                @endpoint = options[:endpoint] || 'http://localhost:1317'
            end
        end
    end
end