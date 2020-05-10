# frozen_string_literal: true

require 'rest-client'
require 'json'
require 'secp256k1'
require 'bluzelle/utils'
require 'bluzelle/constants'

module Bluzelle
  module Swarm
    class Cosmos
      include Bluzelle::Constants
      include Bluzelle::Utils

      attr_reader :mnemonic, :endpoint, :address, :chain_id
      attr_accessor :account_info

      def initialize(options = {})
        @mnemonic = options[:mnemonic]
        @chain_id = options[:chain_id]
        @endpoint = options[:endpoint]
        @address = options[:address]
        @account_info = {}

        validate_address

        fetch_account
      end

      def query(endpoint)
        Request.execute(method: 'get', url: "#{@endpoint}/#{endpoint}")
      end

      def send_transaction(method, endpoint, data, gas_info)
        txn = Transaction.new(method, endpoint, data)
        txn.set_gas(gas_info)

        # fetch skeleton
        skeleton = fetch_txn_skeleton(txn)
        # set gas
        skeleton = update_gas(txn, skeleton)
        skeleton = update_fee_amount(txn, skeleton)
        # set memo
        skeleton = update_memo(skeleton)
        # sort
        skeleton = sort_hash(skeleton)

        # sign txn
        skeleton['signatures'] = [{
          'account_number' => @account_info['account_number'].to_s,
          'pub_key' => {
            'type' => 'tendermint/PubKeySecp256k1',
            'value' => to_base64(
              [compressed_pub_key(open_key(@private_key))].pack('H*')
            )
          },
          'sequence' => @account_info['sequence'].to_s,
          'signature' => sign_transaction(skeleton)
        }]

        broadcast_transaction(Transaction.new('post', TX_COMMAND, skeleton))
      end

      private

      # Account query
      def fetch_account
        url = "#{@endpoint}/auth/accounts/#{@address}"
        res = Request.execute(method: 'get', url: url)

        update_account_details(res.dig('result', 'value'))
      end

      # Broadcasts a transaction
      #
      # @param [Bluzelle::Swarm::Transaction] txn
      def broadcast_transaction(txn)
        url = "#{@endpoint}/#{txn.endpoint}"
        payload = { 'mode' => 'block', 'tx' => txn.data }
        res = Request.execute(method: txn.method, url: url, payload: payload)

        if res.dig('code').nil?
          update_sequence
          parse_json_str(hex_to_str(res.dig('data'))) if res.key?('data')
        else
          handle_broadcast_error(res.dig('raw_log'), txn)
        end
      end

      # Updates account sequence and retries broadcast
      #
      # @param [Bluzelle::Swarm::Transaction] txn
      def update_account_sequence(txn)
        if txn.retries_left != 0
          retry_broadcast(txn)
        else
          raise Error::ApiError, 'Invalid chain id'
        end
      end

      # Fetch transaction skeleton
      def fetch_txn_skeleton(txn)
        url = "#{@endpoint}/#{txn.endpoint}"

        data = Request.execute(
          method: txn.method,
          url: url,
          payload: txn.data,
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
        )

        data['value']
      end

      # Check if address and mnemonic are valid
      def validate_address
        priv_key = get_ec_private_key(@mnemonic)
        pub_key = get_ec_public_key_from_priv(priv_key)

        if get_address(pub_key) != @address
          raise ArgumentError, 'Bad credentials - verify your address and mnemonic'
        end

        set_private_key(priv_key)
      end

      # Set private key
      #
      # @param [String] key
      def set_private_key(key)
        @private_key = key
      end

      # Updates account details
      #
      # @param [Hash] data
      def update_account_details(data)
        account_number = data.dig('account_number')
        sequence = data.dig('sequence')

        @account_info['account_number'] = account_number

        if @account_info['sequence'] != sequence
          @account_info['sequence'] = sequence
          return true
        end

        false
      end

      # Retry broadcast after failure
      #
      # @param [Bluzelle::Swarm::Transaction]
      def retry_broadcast(txn)
        txn.retries_left -= 1

        sleep BROADCAST_RETRY_SECONDS

        broadcast_transaction(txn)
      end

      # Handle broadcast error
      #
      # @param [String] raw_log
      # @param [Bluzelle::Swarm::Transaction] txn
      def handle_broadcast_error(raw_log, txn)
        if raw_log.include?('signature verification failed')
          update_account_sequence(txn)
        else
          raise Error::ApiError, raw_log
        end
      end

      # Update account sequence
      def update_sequence
        @account_info['sequence'] = @account_info['sequence'].to_i + 1
      end

      # Signs a transaction
      #
      # @param txn
      def sign_transaction(txn)
        payload = {
          'account_number' => @account_info['account_number'].to_s,
          'chain_id' => @chain_id,
          'fee' => txn['fee'],
          'memo' => txn['memo'],
          'msgs' => txn['msg'],
          'sequence' => @account_info['sequence'].to_s
        }

        to_base64(ecdsa_sign(json_str(payload)))
      end

      # Returns a ECDSA signature
      #
      # @param [Hash] payload
      def ecdsa_sign(payload)
        # TODO: Change method of signature retrival
        pk = Secp256k1::PrivateKey.new(privkey: hex_encoded_private_key, raw: true)
        rs = pk.ecdsa_sign(payload)
        r = rs.slice(0, 32).read_string.reverse
        s = rs.slice(32, 32).read_string.reverse
        "#{r}#{s}"
      end

      # TODO: Move Utility functions to utility module

      # Returns a hex encoded private key
      def hex_encoded_private_key
        hex_to_str(@private_key)
      end

      # Returns a json string from hash
      #
      # @param [Hash] hash
      def json_str(hash)
        JSON.generate(hash)
      end

      # Returns a Hash from a json string
      #
      # @param [String] str
      def parse_json_str(str)
        JSON.parse(str)
      end

      # Returns a hex encoded string
      def hex_to_str(hex_str)
        [hex_str].pack('H*')
      end

      # Set fee gas
      def update_gas(txn, data)
        res = data.clone

        if res.dig('fee', 'gas').to_i > txn.max_gas && txn.max_gas != 0
          res['fee']['gas'] = txn.max_gas.to_s
        end

        res
      end

      # Set fee amount
      def update_fee_amount(txn, data)
        res = data.clone

        if !txn.max_fee.nil?
          res['fee']['amount'] = [{
            'denom': TOKEN_NAME,
            'amount': txn.max_fee.to_s
          }]
        elsif !txn.gas_price.nil?
          res['fee']['amount'] = [{
            'denom': TOKEN_NAME,
            'amount': (res['fee']['gas'] * txn.gas_price).to_s
          }]
        end

        res
      end

      def update_memo(txn)
        txn['memo'] = make_random_string
        txn
      end
    end
  end
end
