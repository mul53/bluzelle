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

        @cosmos = Cosmos.new(mnemonic: @mnemonic, endpoint: @endpoint, address: @address, chain_id: @chain_id)
      end

      # Create a field in the database
      #
      # @param [String] key
      # @param [String] value
      # @param [Hash] lease
      def create(key, value, lease = nil)
        validate_string(key, 'Key must be a string.')
        validate_string(value, 'Value must be a string.')

        blocks = Utils.convert_lease(lease)
        raise ArgumentError, 'Invalid lease time' if blocks.to_i.negative?

        @cosmos.send_transaction(
          'post',
          'crud/create',
          build_params({ Key: key, Value: value, Lease: blocks }),
          @gas_info
        )
      end

      # Update a field in the database
      #
      # @param [String] key
      # @param [String] value
      # @param [Hash] lease
      def update(key, value, lease = nil)
        raise ArgumentError, 'Key must be a string' unless key.is_a?(String)
        raise ArgumentError, 'Value must be a string' unless value.is_a?(String)

        blocks = Utils.convert_lease(lease)
        raise ArgumentError, 'Invalid lease time' if blocks.to_i.negative?

        @cosmos.send_transaction(
          'post',
          'crud/update',
          build_params({ Key: key, Value: value, Lease: blocks }),
          @gas_info
        )
      end

      # Retrieve the value of a key without consensus verification
      #
      # @param [String] key
      # @param [Boolean] prove
      #
      # @return [String]
      def read(key, prove)
        raise ArgumentError, 'Key must be a string' unless key.is_a?(String)

        url = prove ? "#{@app_service}/pread/#{@uuid}/#{key}" : "#{@app_service}/read/#{@uuid}/#{key}"
        @cosmos.query(url)
               .dig('result', 'value')
      end

      # Retrieve the value of a key via a transaction (i.e uses consensus)
      #
      # @param [String] key
      #
      # @return [String]
      def tx_read(key)
        raise ArgumentError, 'Key must be a string' unless key.is_a?(String)

        @cosmos.send_transaction(
          'post',
          'crud/read',
          build_params({ Key: key }),
          @gas_info
        ).dig('value')
      end

      # Delete a field from the database
      #
      # @param [String] key
      def delete(key)
        raise ArgumentError, 'Key must be a string' unless key.is_a?(String)

        @cosmos.send_transaction(
          'post',
          'crud/delete',
          build_params({ Key: key }),
          @gas_info
        )
      end

      # Query to see if a key is in the database. This function bypasses
      # the consensus and cryptography mechanisms in favour of speed.
      #
      # @param [String] key
      #
      # @return [Boolean]
      def has(key)
        raise ArgumentError, 'Key must be a string' unless key.is_a?(String)

        @cosmos.query("#{@app_service}/has/#{@uuid}/#{key}")
               .dig('result', 'has')
      end

      # Query to see if a key is in the database via a transaction (i.e uses consensus)
      #
      # @param [String] key
      #
      # @return [Boolean]
      def tx_has(key)
        raise ArgumentError, 'Key must be a string' unless key.is_a?(String)

        @cosmos.send_transaction(
          'post',
          'crud/has',
          build_params({ Key: key }),
          @gas_info
        ).dig('has')
      end

      # Retrieve a list of all keys. This function bypasses the consensus
      # and cryptography mechanisms in favour of speed.
      #
      # @return [Array]
      def keys
        @cosmos.query("#{@app_service}/keys/#{@uuid}")
               .dig('result', 'keys') || []
      end

      # Retrieve a list of all keys via a transaction (i.e use consensus)
      #
      # @return [Array]
      def tx_keys
        @cosmos.send_transaction(
          'post',
          'crud/keys',
          build_params({}),
          @gas_info
        ).dig('keys') || []
      end

      # Change the name of an existing key
      #
      # @param [String] key
      # @param [String] new_key
      def rename(key, new_key)
        raise ArgumentError, 'Key must be a string' unless key.is_a?(String)
        unless new_key.is_a?(String)
          raise ArgumentError, 'New key must be a string'
        end

        @cosmos.send_transaction(
          'post',
          'crud/rename',
          build_params({ Key: key, NewKey: new_key }),
          @gas_info
        )
      end

      # Retrieve the number of keys in the current database/uuid.
      # This function bypasses the consensus and cryptography
      # mechanisms in favor of speed
      #
      # @return [Fixnum]
      def count
        @cosmos.query("#{app_service}/count/#{@uuid}")
               .dig('result', 'count')
      end

      # Retrieve the number of keys in the current database/uuid via a transaction
      #
      # @return [Fixnum]
      def tx_count
        @cosmos.send_transaction(
          'post',
          'crud/count',
          build_params({}),
          @gas_info
        ).dig('count')
      end

      # Remove all keys in the current database/uuid
      def delete_all
        @cosmos.send_transaction(
          'post',
          'crud/deleteall',
          build_params({}),
          @gas_info
        )
      end

      # Enumerate all keys and values in the current database/uuid.
      # This function bypasses the consensus and cryptography mechanisms in favor of speed
      #
      # @return [Array]
      def key_values
        @cosmos.query("#{app_service}/keyvalues/#{@uuid}")
               .dig('result', 'keyvalues') || []
      end

      # Enumerate all keys and values in the current database/uuid via a transaction
      #
      # @return [Array]
      def tx_key_values
        @cosmos.send_transaction(
          'post',
          'crud/keyvalues',
          build_params({}),
          @gas_info
        ).dig('keyvalues') || []
      end

      # Update multiple fields in the database
      #
      # @param [Array]
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
          'crud/multiupdate',
          build_params({ KeyValues: key_values }),
          @gas_info
        )
      end

      # Retrieve the minimum time remaining on the lease for a key.
      # This function bypasses the consensus and cryptography mechanisms in favor of speed
      #
      # @param [String] key
      #
      # @return [String]
      def get_lease(key)
        raise ArgumentError, 'Key must be a string' unless key.is_a?(String)

        @cosmos.query("#{@app_service}/getlease/#{@uuid}/#{key}")
               .dig('result', 'lease').to_i * Constants::BLOCK_TIME_IN_SECONDS
      end

      # Retrieve the minimum time remaining on the lease for a key, using a transaction
      #
      # @param [String] key
      #
      # @return [String]
      def tx_get_lease(key)
        raise ArgumentError, 'Key must be a string' unless key.is_a?(String)

        @cosmos.send_transaction(
          'post',
          'crud/getlease',
          build_params({ Key: key }),
          @gas_info
        ).dig('lease').to_i * Constants::BLOCK_TIME_IN_SECONDS
      end

      # Update the minimum time remaining on the lease for a key
      #
      # @param [String] key
      # @param [Hash] lease
      def renew_lease(key, lease = nil)
        raise ArgumentError, 'Key must be a string' unless key.is_a?(String)

        blocks = Utils.convert_lease(lease)
        raise ArgumentError, 'Invalid lease time' if blocks.to_i.negative?

        @cosmos.send_transaction(
          'post',
          'crud/renewlease',
          build_params({ Key: key, Lease: blocks }),
          @gas_info
        )
      end

      # Update the minimum time remaining on the lease for all keys
      #
      # @param [Hash] lease
      def renew_lease_all(lease = nil)
        blocks = Utils.convert_lease(lease)

        raise ArgumentError, 'Invalid lease time' if blocks.to_i.negative?

        @cosmos.send_transaction(
          'post',
          'crud/renewleaseall',
          build_params({ Lease: blocks }),
          @gas_info
        )
      end

      # Retrieve a list of the n keys in the database with the shortest leases.
      # This function bypasses the consensus and cryptography mechanisms in favor of speed
      #
      # @param [Fixnum] n
      #
      # @return [Array]
      def get_n_shortest_lease(n)
        raise ArgumentError, 'Invalid valid specified' if n.negative?

        @cosmos.query("#{@app_service}/getnshortestlease/#{@uuid}/#{n}")
               .dig('result', 'keyleases')
      end

      # Retrieve a list of the N keys/values in the database with the shortest leases,
      # using a transaction
      #
      # @param [Fixnum] n
      #
      # @return [Array]
      def tx_get_n_shortest_lease(n)
        raise ArgumentError, 'Invalid value specified' if n.negative?

        @cosmos.send_transaction(
          'post',
          'crud/getnshortestlease',
          build_params({ N: n }),
          @gas_info
        ).dig('keyleases')
      end

      # Retrieve information about the currently active Bluzelle account
      #
      # @return [Hash]
      def account
        @cosmos.query("auth/accounts/#{@address}")
               .dig('result', 'value')
      end

      # Retrieve the version of the Bluzelle service
      #
      # @return [String]
      def version
        @cosmos.query('node_info')
               .dig('application_version', 'version')
      end

      private

      def validate_string(arg, msg)
        raise ArgumentError, msg unless arg.is_a?(String)
      end

      def build_params(params)
        {
          'BaseReq' => {
            'chain_id' => @chain_id,
            'from' => @address
          },
          'Owner' => @address,
          'UUID' => @uuid
        }.merge(params)
      end
    end
  end
end
