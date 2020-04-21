# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bluzelle::Swarm::Cosmos do
  let(:cosmos) do
    Bluzelle::Swarm::Cosmos.new(
      mnemonic: 'volcano arrest ceiling physical concert sunset absent hungry tobacco canal census era pretty car code crunch inside behind afraid express giraffe reflect stadium luxury',
      endpoint: 'http://localhost:1317',
      address: 'bluzelle1xhz23a58mku7ch3hx8f9hrx6he6gyujq57y3kp'
    )
  end

  let(:params) do
    {
      address: 'bluzelle1lgpau85z0hueyz6rraqqnskzmcz4zuzkfeqls7',
      mnemonic: 'panic cable humor almost reveal artist govern sample segment effort today start cotton canoe icon panel rain donkey brown swift suit extra sick valve',
      endpoint: 'http://localhost:1317',
      chain_id: 'bluzelle',
      pub_key: 'A7KDYwh5wY2Fp3zMpvkdS6Jz+pNtqE5MkN9J5fqLPdzD',
      priv_key: '',
      account_number: '0',
      sequence_number: '1'
    }
  end

  let(:data) do
    {
      BaseReq: {
        from: params.dig(:address),
        chain_id: params.dig(:chain_id)
      },
      UUID: params.dig(:address),
      Key: "key!@\#$%^<>",
      Value: 'value&*()_+',
      Owner: params.dig(:address)
    }
  end

  let(:tx_create_skeleton) do
    {
      type: 'cosmos-sdk/StdTx',
      value: {
        msg: [
          {
            type: 'crud/create',
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
          gas: '100000'
        },
        signatures: nil,
        memo: ''
      }
    }
  end

  let(:gas_params) do
    {
      gas_price: '0.01',
      max_gas: '20000'
    }
  end

  let(:response_data) do
    {
      result: {
        value: {
          account_number: params[:account_number],
          sequence: params[:sequence_number],
          fee: {},
          memo: ''
        }
      }
    }
  end

  describe '#initialize' do
    before do
      stub_request(:get, 'http://localhost:1317/auth/accounts/bluzelle1xhz23a58mku7ch3hx8f9hrx6he6gyujq57y3kp')
        .to_return(
          status: 200,
          body: JSON.generate(response_data),
          headers: { 'Content-Type': 'application/json' }
        )
    end

    it 'should throw error if address is bad' do
      expect do
        Bluzelle::Swarm::Cosmos.new(
          mnemonic: cosmos.mnemonic,
          endpoint: cosmos.endpoint,
          address: "#{cosmos.address}x"
        )
      end.to raise_error('Bad credentials - verify your address and mnemonic')
    end

    it 'should throw error if mnemonic is bad' do
      expect do
        Bluzelle::Swarm::Cosmos.new(
          mnemonic: "#{cosmos.mnemonic}x",
          endpoint: cosmos.endpoint,
          address: cosmos.address
        )
      end.to raise_error('Bad credentials - verify your address and mnemonic')
    end

    it 'should not throw error if address and mnemonic is valid' do
      expect do
        Bluzelle::Swarm::Cosmos.new(
          mnemonic: cosmos.mnemonic,
          endpoint: cosmos.endpoint,
          address: cosmos.address
        )
      end.not_to raise_error('Bad credentials - verify your address and mnemonic')
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

  describe '#query' do
    before do
      get_account_request
    end

    it 'should do basic query' do
      stub_request(:get, 'http://localhost:1317/test')
        .to_return(status: 200, body: JSON.generate(response_data), headers: {})

      res = cosmos.query('test')

      expect(res).not_to be_nil
    end

    it '404 query' do
      stub_request(:get, 'http://localhost:1317/test')
        .to_return(status: 404, body: 'not found', headers: {})

      expect { cosmos.query('test') }.to raise_error Bluzelle::Error::ApiError
    end

    it 'should handle key not found query' do
      stub_request(:get, 'http://localhost:1317/test')
        .to_return(status: 404, body: JSON.generate({ 'error': { 'codespace': 'sdk', 'code': '6', 'message': 'could not read key' } }), headers: {})

      expect { cosmos.query('test') }.to raise_error Bluzelle::Error::ApiError
    end

    it 'should handle unexpected exception' do
      stub_request(:get, 'http://localhost:1317/test')
        .to_return(status: 404, body: JSON.generate({ 'error': { 'codespace': 'sdk', 'code': '6' } }), headers: {})

      expect { cosmos.query('test') }.to raise_error Bluzelle::Error::ApiError
    end
  end

  def get_account_request
    stub_request(:get, 'http://localhost:1317/auth/accounts/bluzelle1xhz23a58mku7ch3hx8f9hrx6he6gyujq57y3kp')
      .to_return(
        status: 200,
        body: JSON.generate(response_data),
        headers: { 'Content-Type': 'application/json' }
      )
  end

  def get_skeleton_request(data = '')
    stub_request(:post, 'http://localhost:1317/crud/create')
      .to_return(status: 200, body: data, headers: {})
  end
end
