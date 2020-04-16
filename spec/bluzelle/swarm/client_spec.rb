# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bluzelle::Swarm::Client do
  let(:client) do
    Bluzelle::Swarm::Client.new(
      address: 'bluzelle1xhz23a58mku7ch3hx8f9hrx6he6gyujq57y3kp',
      mnemonic: 'volcano arrest ceiling physical concert sunset absent hungry tobacco canal census era pretty car code crunch inside behind afraid express giraffe reflect stadium luxury',
      endpoint: 'http://localhost:1317',
      chain_id: 'bluzelle',
      uuid: '20fc19d4-7c9d-4b5c-9578-8cedd756e0ea'
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
      get_account_request
    end

    it 'with default chain_id, endpoint and uuid' do
      @client = Bluzelle::Swarm::Client.new(
        address: client.address,
        mnemonic: client.mnemonic
      )

      expect(@client.chain_id).to eq(client.chain_id)
      expect(@client.endpoint).to eq(client.endpoint)
      expect(@client.uuid).to eq(client.address)
    end

    it 'without address throws error' do
      expect do
        Bluzelle::Swarm::Client.new(
          mnemonic: client.mnemonic,
          endpoint: client.endpoint,
          chain_id: client.chain_id,
          uuid: client.uuid
        )
      end .to raise_error(ArgumentError)
    end

    it 'without mnemonic throws error' do
      expect do
        Bluzelle::Swarm::Client.new(
          address: client.address,
          endpoint: client.endpoint,
          chain_id: client.chain_id,
          uuid: client.uuid
        )
      end .to raise_error(ArgumentError)
    end

    it 'fails when address is not a string' do
      non_string_types = [{}, 1]

      non_string_types.each do |type|
        expect do
          Bluzelle::Swarm::Client.new(
            address: type,
            mnemonic: client.mnemonic,
            endpoint: client.endpoint,
            chain_id: client.chain_id,
            uuid: client.uuid
          )
        end .to raise_error(ArgumentError)
      end
    end

    it 'fails when mnemonic throws error' do
      non_string_types = [{}, 1]

      non_string_types.each do |type|
        expect do
          Bluzelle::Swarm::Client.new(
            address: client.address,
            mnemonic: type,
            endpoint: client.endpoint,
            chain_id: client.chain_id,
            uuid: client.uuid
          )
        end .to raise_error(ArgumentError)
      end
    end
  end

  describe '#create' do
    before do
      get_account_request
    end

    it 'should throw error when key is not string' do
      non_string_types = [{}, 1, []]

      non_string_types.each do |key|
        expect do
          client.create(key, '{a: 13}')
        end.to raise_error(ArgumentError)
      end
    end

    it 'should throw error when value is not string' do
      non_string_types = [{}, 1, []]

      non_string_types.each do |value|
        expect do
          client.create('myKey', value)
        end.to raise_error(ArgumentError)
      end
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
end
