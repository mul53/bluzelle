# frozen_string_literal: true

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
        if !gas_info.nil? || (gas_info.class == Hash && gas_info.empty?)
          @gas_price = gas_info[:gas_price].to_i if gas_info.key?(:gas_price)

          @max_gas = gas_info[:max_gas].to_i if gas_info.key?(:max_gas)

          @max_fee = gas_info[:max_fee].to_i if gas_info.key?(:max_fee)
        end
      end
    end
  end
end
