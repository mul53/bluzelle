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

    let(:data) {
        {
            BaseReq: {
                from: params.dig(:address),
                chain_id: params.dig(:chain_id)
            },
            UUID: params.dig(:address),
            Key: "key!@#$%^<>",
            Value: "value&*()_+",
            Owner: params.dig(:address)
        }
    }

    let(:tx_create_skeleton) {
        {
            type: "cosmos-sdk/StdTx",
            value: {
                msg: [
                    {
                        type: "crud/create",
                        value: {
                            UUID: params.dig(:address),
                            Key: data.dig(:Key),
                            Value: data.dig(:Value),
                            Owner: params.dig(:address)
                        }
                    }
                ],
                fee: {
                    amount: [],
                    gas: "100000"
                },
                signatures: nil,
                memo: ""
            }
        }
    }

    let(:gas_params) {
        {
            gas_price: '0.01', 
            max_gas: '20000'
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

    describe '#send_initial_transaction' do
        before do
            get_account_request
        end

        it 'should send transaction successfully and return data' do
            get_skeleton_request(JSON.generate(tx_create_skeleton))
            
            tx = Bluzelle::Swarm::Transaction.new('post', 'crud/create', data)
            tx.set_gas(gas_params)
            data = cosmos.send_initial_transaction(tx)

            expect(data).not_to eq(nil)
        end

        it 'should catch errors from request' do
            get_skeleton_request

            expect{
                cosmos.send_initial_transaction(
                    Bluzelle::Swarm::Transaction.new('post', 'crud/create', data)
                )}.to raise_error
        end
    end

    describe '#broadcast_transaction' do
        before do
            @account_request_stub = get_account_request
            get_skeleton_request(JSON.generate(tx_create_skeleton))
        end

        it 'should send broadcast successfully' do
            stub_request(:post, "http://localhost:1317/txs").
                with(
                    body: hash_including({"type"=>"cosmos-sdk/StdTx"}),
                ).
                to_return(status: 200, body: JSON.generate(response_data), headers: {})


            tx = Bluzelle::Swarm::Transaction.new('post', 'crud/create', data)
            tx.set_gas(gas_params)

            res = cosmos.broadcast_transaction(tx)

            expect(res).not_to be_nil
        end

        it 'should handle invalid chain id' do
            stub_request(:post, "http://localhost:1317/txs").
                with(
                    body: hash_including({"type"=>"cosmos-sdk/StdTx"}),
                ).
                to_return(status: 200, body: JSON.generate({ code: 4, raw_log: 'signature verification failed' }), headers: {})


            tx = Bluzelle::Swarm::Transaction.new('post', 'crud/create', data)
            tx.set_gas(gas_params)

            expect{
                cosmos.broadcast_transaction(tx)
            }.to raise_error 'Invalid chain id'
        end

        it 'should retry request 10 times' do
            stub_request(:post, "http://localhost:1317/txs").
                with(
                    body: hash_including({"type"=>"cosmos-sdk/StdTx"}),
                ).
                to_return(status: 200, body: JSON.generate({ code: 4, raw_log: 'signature verification failed' }), headers: {})


            tx = Bluzelle::Swarm::Transaction.new('post', 'crud/create', data)
            tx.set_gas(gas_params)

            expect{
                cosmos.broadcast_transaction(tx)
            }.to raise_error 'Invalid chain id'
            expect(@account_request_stub).to have_been_made.times(11) 
        end
    end

    describe '#query' do
        before do
            get_account_request
        end

        it 'should do basic query' do
            stub_request(:get, "http://localhost:1317/test")
                .to_return(status: 200, body: JSON.generate(response_data), headers: {})

            res = cosmos.query('test')
            
            expect(res).not_to be_nil
        end

        it '404 query' do
            stub_request(:get, "http://localhost:1317/test")
                .to_return(status: 404, body: 'not found', headers: {})

            expect{cosmos.query('test')}.to raise_error Bluzelle::Error::ApiError
        end

        it 'should handle key not found query' do
            stub_request(:get, "http://localhost:1317/test")
                .to_return(status: 404, body: JSON.generate({ 'error': { 'codespace': 'sdk', 'code': '6', 'message': 'could not read key' } }), headers: {})

            expect{cosmos.query('test')}.to raise_error Bluzelle::Error::ApiError
        end

        it 'should handle unexpected exception' do
            stub_request(:get, "http://localhost:1317/test")
                .to_return(status: 404, body: JSON.generate({ 'error': { 'codespace': 'sdk', 'code': '6' } }), headers: {})

            expect{cosmos.query('test')}.to raise_error Bluzelle::Error::ApiError
        end
    end

    def get_account_request
        stub_request(:get, "http://localhost:1317/auth/accounts/bluzelle1xhz23a58mku7ch3hx8f9hrx6he6gyujq57y3kp").
        to_return(
            status: 200, 
            body: JSON.generate(response_data), 
            headers: { 'Content-Type': 'application/json' }
        )
    end

    def get_skeleton_request(data = '')
        stub_request(:post, "http://localhost:1317/crud/create").
                with(
                  body: {
                        "BaseReq"=>{   
                            "from"=>"bluzelle1lgpau85z0hueyz6rraqqnskzmcz4zuzkfeqls7", 
                            "chain_id"=>"bluzelle"
                        }, 
                        "Key"=>"key!@\#$%^<>", 
                        "Owner"=>"bluzelle1lgpau85z0hueyz6rraqqnskzmcz4zuzkfeqls7", 
                        "UUID"=>"bluzelle1lgpau85z0hueyz6rraqqnskzmcz4zuzkfeqls7", 
                        "Value"=>"value&*()_+"
                    }
                ).to_return(status: 200, body: data, headers: {})
    end
end