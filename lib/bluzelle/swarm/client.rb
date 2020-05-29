# frozen_string_literal: true
require 'bluzelle/utils'
require 'bluzelle/constants'

module Bluzelle
  module Swarm
    class Client
      include Bluzelle::Constants
      include Bluzelle::Utils

      attr_reader :address, :mnemonic, :uuid, :chain_id, :endpoint, :app_service
      attr_reader :cosmos

      # Creates a new Bluzelle connection.

      # @param options [Hash]
      # @return [Bluzelle::Swarm::Client]
      def initialize(options = {})
        options = stringify_keys(options)

        validate_string(options['mnemonic'], 'Mnemonic must be a string.')
        validate_string(options['uuid'], 'UUID must be a string.')

        @mnemonic = options['mnemonic']
        @uuid = options['uuid']
        @chain_id = options['chain_id'] || 'bluzelle'
        @endpoint = options['endpoint'] || 'http://localhost:1317'
        @app_service = 'crud'

        @cosmos = Cosmos.new(
          mnemonic: @mnemonic,
          endpoint: @endpoint,
          chain_id: @chain_id
        )

        @address = @cosmos.address
      end

      # Create a field in the database
      #
      # @param [String] key The name of the key to create
      # @param [String] value The string value to set the key
      # @param [Hash] gas_info Hash containing gas parameters
      # @param [Hash] lease_info Minimum time for key to remain in database
      #
      # @return [void]
      def create(key, value, gas_info, lease_info = nil)
        validate_string(key, 'key must be a string')
        validate_string(value, 'value must be a string')

        lease = convert_lease(lease_info)

        validate_lease(lease, 'invalid lease time')

        @cosmos.send_transaction(
          'post',
          "#{@app_service}/create",
          build_params({ 'Key' => key, 'Value' => value, 'Lease' => lease }),
          gas_info
        )
      end

      # Update a field in the database
      #
      # @param [String] key The name of the key to update
      # @param [String] value The string value to set the key
      # @param [Hash] gas_info Hash containing gas parameters
      # @param [Hash] lease_info Minimum time for key to remain in database
      #
      # @return [void]
      def update(key, value, gas_info, lease_info = nil)
        validate_string(key, 'Key must be a string')
        validate_string(value, 'Value must be a string')

        lease = convert_lease(lease_info)

        validate_lease(lease, 'invalid lease time')

        @cosmos.send_transaction(
          'post',
          "#{@app_service}/update",
          build_params({ Key: key, Value: value, Lease: lease }),
          gas_info
        )
      end

      # Retrieve the value of a key without consensus verification
      #
      # @param [String] key The key to retrieve
      # @param [Boolean] prove
      #
      # @return [String] String value of the key
      def read(key, prove = false)
        validate_string(key, 'Key must be a string')

        path = prove ? 'pread' : 'read'
        url = "#{@app_service}/#{path}/#{@uuid}/#{key}"

        @cosmos.query(url)
               .dig('result', 'value')
      end

      # Retrieve the value of a key via a transaction (i.e uses consensus)
      #
      # @param [String] key The key to retrieve
      # @param [Hash] gas_info Hash containing gas parameters
      #
      # @return [String] String value of the key
      def tx_read(key, gas_info)
        validate_string(key, 'Key must be a string')

        @cosmos.send_transaction(
          'post',
          "#{@app_service}/read",
          build_params({ Key: key }),
          gas_info
        ).dig('value')
      end

      # Delete a field from the database
      #
      # @param [String] key The name of the key to delete
      # @param [Hash] gas_info Hash containing gas parameters
      #
      # @return [void]
      def delete(key, gas_info)
        validate_string(key, 'Key must be a string')

        @cosmos.send_transaction(
          'delete',
          "#{@app_service}/delete",
          build_params({ Key: key }),
          gas_info
        )
      end

      # Query to see if a key is in the database. This function bypasses
      # the consensus and cryptography mechanisms in favour of speed.
      #
      # @param [String] key The name of the key to query
      #
      # @return [Boolean]
      def has(key)
        validate_string(key, 'Key must be a string')

        @cosmos.query("#{@app_service}/has/#{@uuid}/#{key}")
               .dig('result', 'has')
      end

      # Query to see if a key is in the database via a transaction (i.e uses consensus)
      #
      # @param [String] key The name of the key to query
      # @param [Hash] gas_info Hash containing gas parameters
      #
      # @return [Boolean]
      def tx_has(key, gas_info)
        validate_string(key, 'Key must be a string')

        @cosmos.send_transaction(
          'post',
          "#{@app_service}/has",
          build_params({ Key: key }),
          gas_info
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
      # @param [Hash] gas_info Hash containing gas parameters
      #
      # @return [Array]
      def tx_keys(gas_info)
        @cosmos.send_transaction(
          'post',
          "#{@app_service}/keys",
          build_params({}),
          gas_info
        ).dig('keys') || []
      end

      # Change the name of an existing key
      #
      # @param [String] key
      # @param [String] new_key
      # @param [Hash] gas_info Hash containing gas parameters
      #
      # @return [void]
      def rename(key, new_key, gas_info)
        validate_string(key, 'key must be a string')
        validate_string(new_key, 'new_key must be a string')

        @cosmos.send_transaction(
          'post',
          "#{@app_service}/rename",
          build_params({ Key: key, NewKey: new_key }),
          gas_info
        )
      end

      # Retrieve the number of keys in the current database/uuid.
      # This function bypasses the consensus and cryptography
      # mechanisms in favor of speed
      #
      # @return [Integer]
      def count
        @cosmos.query("#{app_service}/count/#{@uuid}")
               .dig('result', 'count')
      end

      # Retrieve the number of keys in the current database/uuid via a transaction
      #
      # @param [Hash] gas_info Hash containing gas parameters
      #
      # @return [Integer]
      def tx_count(gas_info)
        @cosmos.send_transaction(
          'post',
          "#{@app_service}/count",
          build_params({}),
          gas_info
        ).dig('count')
      end

      # Remove all keys in the current database/uuid
      #
      # @param [Hash] gas_info Hash containing gas parameters
      #
      # @return [void]
      def delete_all(gas_info)
        @cosmos.send_transaction(
          'post',
          "#{@app_service}/deleteall",
          build_params({}),
          gas_info
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
      # @param [Hash] gas_info Hash containing gas parameters
      #
      # @return [Array]
      def tx_key_values(gas_info)
        @cosmos.send_transaction(
          'post',
          "#{@app_service}/keyvalues",
          build_params({}),
          gas_info
        ).dig('keyvalues') || []
      end

      # Update multiple fields in the database
      #
      # @param [Array]
      # @param [Hash] gas_info Hash containing gas parameters
      def multi_update(key_values, gas_info)
        validate_array(key_values, 'key_values must be an array')

        key_values.each do |key_value|
          validate_string(key_value.dig('key'), 'All keys must be strings')
          validate_string(key_value.dig('value'), 'All values must be string')
        end

        @cosmos.send_transaction(
          'post',
          "#{@app_service}/multiupdate",
          build_params({ KeyValues: key_values }),
          gas_info
        )
      end

      # Retrieve the minimum time remaining on the lease for a key.
      # This function bypasses the consensus and cryptography mechanisms in favor of speed
      #
      # @param [String] key
      #
      # @return [String]
      def get_lease(key)
        validate_string(key, 'key must be a string')

        @cosmos.query("#{@app_service}/getlease/#{@uuid}/#{key}")
               .dig('result', 'lease').to_i * BLOCK_TIME_IN_SECONDS
      end

      # Retrieve the minimum time remaining on the lease for a key, using a transaction
      #
      # @param [String] key The key to retrieve the lease information for
      # @param [Hash] gas_info Hash containing gas parameters
      #
      # @return [String]
      def tx_get_lease(key, gas_info)
        validate_string(key, 'key must be a string')

        @cosmos.send_transaction(
          'post',
          "#{@app_service}/getlease",
          build_params({ Key: key }),
          gas_info
        ).dig('lease').to_i * BLOCK_TIME_IN_SECONDS
      end

      # Update the minimum time remaining on the lease for a key
      #
      # @param [String] key The key to retrieve the lease information for
      # @param [Hash] gas_info Hash containing gas parameters
      # @param [Hash] lease Minimum time for key to remain in database
      def renew_lease(key, lease, gas_info)
        validate_string(key, 'key must be a string')

        lease = convert_lease(lease)

        validate_lease(lease, 'invalid lease time')

        @cosmos.send_transaction(
          'post',
          "#{@app_service}/renewlease",
          build_params({ Key: key, Lease: lease }),
          gas_info
        )
      end

      # Update the minimum time remaining on the lease for all keys
      #
      # @param [Hash] gas_info Hash containing gas parameters
      # @param [Hash] lease Minimum time for key to remain in database
      def renew_lease_all(lease, gas_info)
        lease = convert_lease(lease)

        validate_lease(lease, 'invalid lease time')

        @cosmos.send_transaction(
          'post',
          "#{@app_service}/renewleaseall",
          build_params({ Lease: lease }),
          gas_info
        )
      end

      # Retrieve a list of the n keys in the database with the shortest leases.
      # This function bypasses the consensus and cryptography mechanisms in favor of speed
      #
      # @param [Integer] n The number of keys to retrieve the lease information for
      #
      # @return [Array]
      def get_n_shortest_leases(n)
        validate_lease(n, 'invalid value specified')

        @cosmos.query("#{@app_service}/getnshortestleases/#{@uuid}/#{n}")
               .dig('result', 'keyleases')
               .map do |key_lease|
          {
            'key' => key_lease['key'],
            'lease' => key_lease['lease'].to_i * BLOCK_TIME_IN_SECONDS
          }
        end
      end

      # Retrieve a list of the N keys/values in the database with the shortest leases,
      # using a transaction
      #
      # @param [Integer] n The number of keys to retrieve the lease information for
      # @param [Hash] gas_info Hash containing lize(options = {})gas parameters
      #
      # @return [Array]
      def tx_get_n_shortest_leases(n, gas_info)
        validate_lease(n, 'invalid value specified')

        @cosmos.send_transaction(
          'post',
          "#{@app_service}/getnshortestleases",
          build_params({ N: n.to_s }),
          gas_info
        ).dig('keyleases')
               .map do |key_lease|
          {
            'key' => key_lease['key'],
            'lease' => key_lease['lease'].to_i * BLOCK_TIME_IN_SECONDS
          }
        end
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

      def validate_array(arg, msg)
        raise ArgumentError, msg unless arg.is_a?(Array)
      end

      def validate_string(arg, msg)
        raise ArgumentError, msg unless arg.is_a?(String)
      end

      def validate_lease(arg, msg)
        raise ArgumentError, msg if arg.is_a?(Integer) && arg.negative?
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
