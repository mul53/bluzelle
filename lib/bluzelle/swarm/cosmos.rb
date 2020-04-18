# frozen_string_literal: true

require 'rest-client'
require 'json'

module Bluzelle
  module Swarm
    class Cosmos
      attr_reader :mnemonic, :endpoint, :address
      attr_accessor :account_info

      def initialize(options = {})
        @mnemonic = options[:mnemonic]
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

      def send_initial_transaction(txn)
        url = "#{@endpoint}/#{txn.endpoint}"

        data = Request.new(txn.method, url, txn.data, headers: { 'Content-Type': 'application/x-www-form-urlencoded' }).execute

        data = set_fee_gas(txn, data)

        set_fee_amount(txn, data)
      end

      # Broadcasts a transaction
      #
      # @param [Bluzelle::Swarm::Transaction] txn
      def broadcast_transaction(txn)
        data = send_initial_transaction(txn)

        raise ArgumentError('Invalid Transaction') if data.nil?

        url = "#{@endpoint}/#{Constants::TX_COMMAND}"
        res = Request.new('post', url, sign(data)).execute

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
        account_number = data.dig('result', 'value', 'account_number')
        sequence = data.dig('result', 'value', 'sequence')

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
          raise Error::ApiError, res['raw_log']
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

        sig = Utils.sign_transaction(Utils.get_ec_private_key(@mnemonic), data, chain_id)

        res['value']['signatures'] << sig
        res['value']['signature'] = sig

        res
      end

      # Set fee gas
      def set_fee_gas(txn, data)
        res = data.clone

        if res.dig('value', 'fee', 'gas').to_i > txn.max_gas
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
