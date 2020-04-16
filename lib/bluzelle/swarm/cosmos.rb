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
                r = RestClient.get("#{@endpoint}/auth/accounts/#{@address}")
                data = JSON.parse(r.body).dig('result', 'value')

                account_number = data.dig('result', 'value', 'account_number')
                sequence = data.dig('result', 'value', 'sequence')

                @account_info[:account_number] = account_number
                
                if @account_info[:sequence] != sequence
                    @account_info[:sequence] = sequence
                    return true
                end

                return false
            end

            def query(endpoint)
                begin
                    r = RestClient.get("#{@endpoint}/#{endpoint}")
                rescue RestClient::ExceptionWithResponse => err
                    res = JSON.generate(err.response)
                    if res.is_a?(String)
                        raise Error::ApiError.new(res, err.http_code)
                    elsif res.dig('error', 'message').is_a?(String)
                        raise Error::ApiError.new(res.dig('error', 'message'), err.http_code)
                    else
                        raise Error::ApiError.new('error occurred', err.http_code)
                    end
                else
                    return JSON.parse(r.body)
                end
            end

            def send_transaction(method, endpoint, data, gas_info)
                tx = Transaction.new(method, endpoint, data)
                tx.set_gas(gas_info)
                broadcast_transaction(tx)
            end

            def send_initial_transaction(tx)
                url = "#{@endpoint}/#{tx.endpoint}"
                chain_id = tx.data.dig('BaseReq', 'chain_id')

                data = nil

                begin
                    r = RestClient::Request.execute(method: tx.method, 
                      url: url, payload: tx.data,
                        headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
                    )
                rescue RestClient::ExceptionWithResponse => err
                    raise Error:ApiError.new('error occurred', err.http_code)
                else
                    data = JSON.parse(r.body)

                    if data.dig('value', 'fee', 'gas').to_i > tx.max_gas
                        data['value']['fee']['gas'] = tx.max_gas.to_s
                    end

                    if not tx.max_fee.nil?
                        data['value']['fee']['amount'] = [{
                            'denom': "#{Utils::TOKEN_NAME}", 
                            'amount': "#{tx.max_fee}"
                        }]
                    elsif not tx.gas_price.nil?
                        data['value']['fee']['amount'] = [{
                            'denom': "#{Utils::TOKEN_NAME}",
                            'amount': "#{data['value']['fee']['gas'] * tx.gas_price}"
                        }]
                    end

                    return data
                end
            end

            def broadcast_transaction(tx)
                data = send_initial_transaction(tx)
                chain_id = data.dig('BaseReq', 'chain_id')

                if data.nil?
                    raise ArgumentError('Invalid Transaction')
                end

                data.dig('value')

                data['value']['signatures'] = []
                data['value']['memo'] = Utils.make_random_string

                sig = Utils.sign_transaction(Utils.get_ec_private_key(@mnemonic), data, chain_id)

                data['value']['signatures'] << sig
                data['value']['signature'] = sig

                res = nil

                begin
                    r = RestClient.post("#{@endpoint}/#{Utils::TX_COMMAND}", data)
                rescue RestClient::ExceptionWithResponse => err
                    raise Error::ApiError.new(err.message)
                else
                    res = JSON.parse(r.body)
                end

                if res['code'].nil?
                    @account_info['sequence'] = (@account_info['sequence'].to_i) + 1;
                    return res
                else
                    if res['raw_log'].include?('signature verification failed')
                        update_account_sequence(tx)
                    else
                        raise Error::ApiError.new(res['raw_log'])
                    end 
                end
            end

            def update_account_sequence(tx)
                if tx.retries_left != 0
                    sleep Utils::BROADCAST_RETRY_SECONDS

                    changed = send_account_query

                    if changed
                        broadcast_transaction(tx)
                    else
                        tx.retries_left -= 1
                        update_account_sequence(tx) 
                    end
                else
                    raise Error::ApiError.new('Invalid chain id')
                end
            end
        end
    end
end