module Bluzelle
    module Swarm
        class Transaction
            attr_reader :method, :endpoint, :data
            attr_accessor :gas_price, :max_gas, :max_fee, :memo, :retries_left

            def initialize(method, endpoint, data)
                @method = method
                @endpoint = endpoint
                @data = data
                @gas_price = 0
                @max_gas = 0
                @max_fee = 0
                @retries_left = 10
            end

            def set_gas(gas_info = nil)
                if gas_info != nil || (gas_info.class == Hash && gas_info.empty?)
                    if gas_info.has_key?(:gas_price)
                        @gas_price = gas_info[:gas_price].to_f
                    end

                    if gas_info.has_key?(:max_gas)
                        @max_gas = gas_info[:max_gas].to_f
                    end

                    if gas_info.has_key?(:max_fee)
                        @max_fee = gas_info[:max_fee].to_f
                    end
                end
            end
        end
    end
end