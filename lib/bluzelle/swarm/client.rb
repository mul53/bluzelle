# frozen_string_literal: true

module Bluzelle
  module Swarm
    class Client
      attr_reader :address, :mnemonic, :uuid, :chain_id, :endpoint, :app_service
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
        @app_service = 'crud'
        @gas_info = options[:gas_info]

        @cosmos = Cosmos.new(mnemonic: @mnemonic, endpoint: @endpoint, address: @address)
      end

      def create(key, value, lease = nil)
        validate_string(key, 'Key must be a string.')
        validate_string(value, 'Value must be a string.')

        blocks = Utils.convert_lease(lease)
        raise ArgumentError, 'Invalid lease time' if blocks.to_i.negative?

        @cosmos.send_transaction(
          'post',
          'create',
          build_params({ Key: key, Value: value, Lease: blocks }),
          @gas_info
        )
      end

      def update(key, value, lease = nil)
        raise ArgumentError, 'Key must be a string' unless key.is_a?(String)
        raise ArgumentError, 'Value must be a string' unless value.is_a?(String)

        blocks = Utils.convert_lease(lease)
        raise ArgumentError, 'Invalid lease time' if blocks.to_i.negative?

        @cosmos.send_transaction(
          'post',
          'update',
          build_params({ Key: key, Value: value, Lease: blocks }),
          @gas_info
        )
      end

      def read(key, prove)
        raise ArgumentError, 'Key must be a string' unless key.is_a?(String)

        url = prove ? "#{@app_service}/pread/#{@uuid}/#{key}" : "#{@app_service}/read/#{@uuid}/#{key}"
        @cosmos.query(url)
               .dig('result', 'value')
      end

      def tx_read(key)
        raise ArgumentError, 'Key must be a string' unless key.is_a?(String)

        @cosmos.send_transaction(
          'post',
          'read',
          build_params({ Key: key }),
          @gas_info
        ).dig('value')
      end

      def delete(key)
        raise ArgumentError, 'Key must be a string' unless key.is_a?(String)

        @cosmos.send_transaction(
          'post',
          'delete',
          build_params({ Key: key }),
          @gas_info
        )
      end

      def has(key)
        raise ArgumentError, 'Key must be a string' unless key.is_a?(String)

        @cosmos.query("#{@app_service}/has/#{@uuid}/#{key}")
               .dig('result', 'has')
      end

      def tx_has(key)
        raise ArgumentError, 'Key must be a string' unless key.is_a?(String)

        @cosmos.send_transaction(
          'post',
          'has',
          build_params({ Key: key }),
          @gas_info
        ).dig('has')
      end

      def keys
        @cosmos.query("#{@app_service}/keys/#{@uuid}")
               .dig('result', 'keys') || []
      end

      def tx_keys
        @cosmos.send_transaction(
          'post',
          'keys',
          build_params({}),
          @gas_info
        ).dig('keys') || []
      end

      def rename(key, new_key)
        raise ArgumentError, 'Key must be a string' unless key.is_a?(String)
        unless new_key.is_a?(String)
          raise ArgumentError, 'New key must be a string'
        end

        @cosmos.send_transaction(
          'post',
          'rename',
          build_params({ Key: key, NewKey: new_key }),
          @gas_info
        )
      end

      def count
        @cosmos.query("#{app_service}/count/#{@uuid}")
               .dig('result', 'count')
      end

      def tx_count
        @cosmos.send_transaction(
          'post',
          'count',
          build_params({}),
          @gas_info
        ).dig('count')
      end

      def delete_all
        @cosmos.send_transaction(
          'post',
          'deleteall',
          build_params({}),
          @gas_info
        )
      end

      def key_values
        @cosmos.query("#{app_service}/keyvalues/#{@uuid}")
               .dig('result', 'keyvalues')
      end

      def tx_key_values
        @cosmos.send_transaction(
          'post',
          'keyvalues',
          build_params({}),
          @gas_info
        ).dig('keyvalues')
      end

      def multi_update(key_values)
        unless key_values.is_a?(Array)
          raise ArgumentError, 'key_values must be an array'
        end

        key_values.each do |key_value|
          unless key_value.dig('key').is_a?(String)
            raise ArgumentError, 'All keys must be strings'
          end
          unless key_value.dig('value').is_a?(String)
            raise ArgumentError, 'All values must be string'
          end
        end

        @cosmos.send_transaction(
          'post',
          'multiupdate',
          build_params({ KeyValues: key_values }),
          @gas_info
        )
      end

      def get_lease(key)
        raise ArgumentError, 'Key must be a string' unless key.is_a?(String)

        @cosmos.query("#{@app_service}/getlease/#{@uuid}/#{key}")
               .dig('result', 'lease').to_i * Utils::BLOCK_TIME_IN_SECONDS
      end

      def tx_get_lease(key)
        raise ArgumentError, 'Key must be a string' unless key.is_a?(String)

        @cosmos.send_transaction(
          'post',
          'getlease',
          build_params({ Key: key }),
          @gas_info
        ).dig('lease').to_i * Utils::BLOCK_TIME_IN_SECONDS
      end

      def renew_lease(key, lease = nil)
        raise ArgumentError, 'Key must be a string' unless key.is_a?(String)

        blocks = Utils.convert_lease(lease)
        raise ArgumentError, 'Invalid lease time' if blocks.to_i.negative?

        @cosmos.send_transaction(
          'post',
          'renewlease',
          build_params({ Key: key, Lease: blocks }),
          @gas_info
        )
      end

      def renew_lease_all(lease = nil)
        blocks = Utils.convert_lease(lease)

        raise ArgumentError, 'Invalid lease time' if blocks.to_i.negative?

        @cosmos.send_transaction(
          'post',
          'renewleaseall',
          build_params({ Lease: blocks }),
          @gas_info
        )
      end

      def get_n_shortest_lease(n)
        raise ArgumentError, 'Invalid valud specified' if n.negative?

        @cosmos.query("#{@app_service}/getnshortestlease/#{@uuid}/#{n}")
               .dig('result', 'keyleases')
      end

      def tx_get_n_shortest_lease(n)
        raise ArgumentError, 'Invalid value specified' if n.negative?

        @cosmos.send_transaction(
          'post',
          'getnshortestlease',
          build_params({ N: n }),
          @gas_info
        ).dig('keyleases')
      end

      def account
        @cosmos.query("auth/accounts/#{@address}")
               .dig('result', 'value')
      end

      def version
        @cosmos.query('node_info')
               .dig('application', 'version')
      end

      private
      def validate_string(arg, msg)
        raise ArgumentError, msg unless arg.is_a?(String)
      end

      def build_params(params)
        {
          BaseReq: {
            from: @address,
            chain_id: @chain_id
          },
          UUID: @uuid,
          Owner: @address
        }.merge(params)
      end
    end
  end
end
