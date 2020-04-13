require 'bluzelle/utils'
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

                Bluzelle::Utils.validate_address(@address, @mnemonic)

                send_account_query
            end

            def send_account_query
                r = RestClient.get("#{@endpoint}/auth/accounts/#{@address}")
                @account_info = JSON.parse(r.body).dig('result', 'value')
            end
        end
    end
end