module Bluzelle
    module Swarm
        class Transaction
            attr_reader :type, :ep, :data
            attr_accessor :gas_price, :max_gas, :max_fee, :retries_left

            def initialize(type, ep, data)
                @type = type
                @ep = ep
                @data = data
                @gas_price = 0
                @max_gas = 0
                @max_fee = 0
                @retries_left = 10
            end
        end
    end
end