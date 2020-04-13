require 'bluzelle/utils'

module Bluzelle
    module Swarm
        class Cosmos
            attr_reader :mnemonic, :endpoint, :address

            def initialize(options = {})
                @mnemonic = options[:mnemonic]
                @endpoint = options[:endpoint]
                @address = options[:address]

                Bluzelle::Utils.validate_address(@address, @mnemonic)
            end
        end
    end
end