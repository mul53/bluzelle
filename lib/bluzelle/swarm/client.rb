# frozen_string_literal: true

module Bluzelle
  module Swarm
    class Client
      attr_reader :address, :mnemonic, :uuid, :chain_id, :endpoint
      attr_reader :cosmos

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

        @cosmos = Cosmos.new(mnemonic: @mnemonic, endpoint: @endpoint, address: @address)
      end

      def create(key, value, _gas_info = nil)
        validate_string(key, 'Key must be a string.')
        validate_string(value, 'Value must be a string.')
      end

      def verison
        res = @cosmos.query('node_info')
        res.dig('application', 'version')
      end

      private
      def validate_string(arg, msg)
        raise ArgumentError, msg unless arg.is_a?(String)
      end

      def build_params(key, value)
        {
          BaseReq: {
            from: @address,
            chain_id: @chain_id
          },
          UUID: @uuid,
          Key: key,
          Value: value,
          Owner: @address
        }
      end
    end
  end
end
