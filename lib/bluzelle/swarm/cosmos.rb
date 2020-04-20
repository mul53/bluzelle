# frozen_string_literal: true

require 'rest-client'
require 'json'

module Bluzelle
  module Swarm
    class Cosmos
      attr_reader :mnemonic, :endpoint, :address, :chain_id
      attr_accessor :account_info

      def initialize(options = {})
        @mnemonic = options[:mnemonic]
        @chain_id = options[:chain_id]
        @endpoint = options[:endpoint]
        @address = options[:address]
        @account_info = {}

        Utils.validate_address(@address, @mnemonic)

        send_account_query
      end

      def send_account_query
        url = "#{@endpoint}/auth/accounts/#{@address}"

        res = Request.new('get', url).execute
        data = res.dig('result', 'value')

        update_account_details(data)
      end

      def query(endpoint)
        Request.new('get', "#{@endpoint}/#{endpoint}")
               .execute
      end

      def send_transaction(method, endpoint, data, gas_info)
        txn = Transaction.new(method, endpoint, data)

        txn.set_gas(gas_info)

        broadcast_transaction(txn)
      end

      def validate_transaction(txn)
        url = "#{@endpoint}/#{txn.endpoint}"

        data = Request.new(txn.method, url, txn.data, headers: { 'Content-Type': 'application/x-www-form-urlencoded' }).execute

        data = set_fee_gas(txn, data)

        set_fee_amount(txn, data)
      end

      # Broadcasts a transaction
      #
      # @param [Bluzelle::Swarm::Transaction] txn
      def broadcast_transaction(txn)
        data = validate_transaction(txn)

        raise ArgumentError('Invalid Transaction') if data.nil?

        url = "#{@endpoint}/#{Constants::TX_COMMAND}"
        
        payload = { tx: sign(data).dig('value'), mode: 'block' }
        
        res = Request.new('post', url, payload).execute

        if res.dig('code').nil?
          update_sequence
          res
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

      private

      # Updates account details
      #
      # @param [Hash] data
      def update_account_details(data)
        account_number = data.dig('account_number')
        sequence = data.dig('sequence')

        @account_info[:account_number] = account_number

        if @account_info[:sequence] != sequence
          @account_info[:sequence] = sequence
          return true
        end

        false
      end

      # Retry broadcast after failure
      #
      # @param [Bluzelle::Swarm::Transaction]
      def retry_broadcast(txn)
        sleep Constants::BROADCAST_RETRY_SECONDS

        changed = send_account_query

        if changed
          broadcast_transaction(txn)
        else
          txn.retries_left -= 1
          update_account_sequence(txn)
        end
      end

      # Handle broadcast error
      #
      # @param [String] raw_log
      # @param [Bluzelle::Swarm::Transaction] txn
      def handle_broadcast_error(raw_log, txn)
        if raw_log.include?('signature verification failed')
          update_account_sequence(txn)
        else
          puts raw_log
          raise Error::ApiError, raw_log
        end
      end

      def update_sequence
        @account_info[:sequence] = @account_info[:sequence].to_i + 1
      end

      # Signs data
      #
      # @param [Hash] data
      def sign(data)
        res = data.clone
        chain_id = res.dig('BaseReq', 'chain_id') || ''

        res['value']['signatures'] = []
        res['value']['memo'] = Utils.make_random_string

        sig = Utils.sign_transaction(
            Utils.get_ec_private_key(@mnemonic), data, chain_id, @account_info[:account_number], @account_info[:sequence])

        res['value']['signatures'] << sig

        res
      end

      def sign_transaction(txn)
        payload = {
          'account_number' => @account_info[:account_number],
          'chain_id' => @chain_id,
          'fee' => txn['fee'],
          'memo' => txn['memo'],
          'msgs' => @account_info[:sequence].to_s
        }

        payload = JSON.generate(payload)

        pk = Secp256k1::PrivateKey.new(privkey: private_key.to_bytes, raw: true)
        rs = pk.ecdsa_sign payload
        r = rs.slice(0, 32).read_string.reverse
        s = rs.slice(32, 32).read_string.reverse
        sig = "#{r}#{s}"
        Utils.to_base64(sig)
      end

      def build_signature(txn)
        [{
          'account_number' => @account_info[:account_number].to_s,
          'pub_key' => {
            'type' => '',
            'value' => Utils.to_base64(private_key),
          },
          'sequence' => @account_info['sequence'].to_s,
          'signature' => sign_transaction(txn)
        }]
      end

      # Set fee gas
      def set_fee_gas(txn, data)
        res = data.clone

        if res.dig('value', 'fee', 'gas').to_i > txn.max_gas && txn.max_gas != 0
          res['value']['fee']['gas'] = txn.max_gas.to_s
        end

        res
      end

      # Set fee amount
      def set_fee_amount(txn, data)
        res = data.clone

        if !txn.max_fee.nil?
          res['value']['fee']['amount'] = [{
            'denom': Constants::TOKEN_NAME.to_s,
            'amount': txn.max_fee.to_s
          }]
        elsif !txn.gas_price.nil?
          res['value']['fee']['amount'] = [{
            'denom': Constants::TOKEN_NAME.to_s,
            'amount': (res['value']['fee']['gas'] * txn.gas_price).to_s
          }]
        end

        res
      end
    end
  end
end
