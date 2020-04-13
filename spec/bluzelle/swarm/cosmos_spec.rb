require 'spec_helper'

RSpec.describe Bluzelle::Swarm::Cosmos do
    let(:cosmos) {
        Bluzelle::Swarm::Cosmos.new(
            mnemonic: 'volcano arrest ceiling physical concert sunset absent hungry tobacco canal census era pretty car code crunch inside behind afraid express giraffe reflect stadium luxury',
            endpoint: 'http://localhost:1317',
            address: 'bluzelle1xhz23a58mku7ch3hx8f9hrx6he6gyujq57y3kp'
        )
    }

    let(:params) {
        {
            address: 'bluzelle1lgpau85z0hueyz6rraqqnskzmcz4zuzkfeqls7',
            mnemonic: 'panic cable humor almost reveal artist govern sample segment effort today start cotton canoe icon panel rain donkey brown swift suit extra sick valve',
            endpoint: "http://localhost:1317",
            chain_id: "bluzelle",
            pub_key: "A7KDYwh5wY2Fp3zMpvkdS6Jz+pNtqE5MkN9J5fqLPdzD",
            priv_key: "",
            account_number: "0",
            sequence_number: "1"
        }
    }

    let(:response_data) {
        {
            result: {
                value: {
                    account_number: params[:account_number],
                    sequence: params[:sequence_number],
                    fee: {},
                    memo: ""
                }
            }
        }
    }

    describe '#initialize' do
        before do
            stub_request(:get, "http://localhost:1317/auth/accounts/bluzelle1xhz23a58mku7ch3hx8f9hrx6he6gyujq57y3kp").
                to_return(
                    status: 200, 
                    body: JSON.generate(response_data), 
                    headers: { 'Content-Type': 'application/json' }
                )
        end

        it 'should throw error if address is bad' do
            expect{
                Bluzelle::Swarm::Cosmos.new(
                    mnemonic: cosmos.mnemonic,
                    endpoint: cosmos.endpoint,
                    address: "#{cosmos.address}x"
                )
            }.to raise_error('Bad credentials - verify your address and mnemonic')
        end

        
        it 'should throw error if mnemonic is bad' do
            expect{
                Bluzelle::Swarm::Cosmos.new(
                    mnemonic: "#{cosmos.mnemonic}x",
                    endpoint: cosmos.endpoint,
                    address: cosmos.address
                )
            }.to raise_error('Bad credentials - verify your address and mnemonic')
        end
        
        it 'should not throw error if address and mnemonic is valid' do
            expect{
                Bluzelle::Swarm::Cosmos.new(
                    mnemonic: cosmos.mnemonic,
                    endpoint: cosmos.endpoint,
                    address: cosmos.address
                )
            }.not_to raise_error('Bad credentials - verify your address and mnemonic')
        end

        it 'retrieves account information' do
            api = Bluzelle::Swarm::Cosmos.new(
                mnemonic: cosmos.mnemonic,
                endpoint: cosmos.endpoint,
                address: cosmos.address
            )

            expect(api.account_info).not_to be_nil
        end
    end
end