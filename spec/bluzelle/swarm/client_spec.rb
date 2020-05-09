# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bluzelle::Swarm::Client do
  let(:client) do
    Bluzelle::Swarm::Client.new(
      address: 'bluzelle1xhz23a58mku7ch3hx8f9hrx6he6gyujq57y3kp',
      mnemonic: 'volcano arrest ceiling physical concert sunset absent hungry tobacco canal census era pretty car code crunch inside behind afraid express giraffe reflect stadium luxury',
      endpoint: 'http://localhost:1317',
      chain_id: 'bluzelle',
      uuid: '20fc19d4-7c9d-4b5c-9578-8cedd756e0ea',
      gas_info: {
        max_fee: 400_000
      }
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
      account_request_stub
    end

    it 'with default chain_id, endpoint and uuid' do
      @client = Bluzelle::Swarm::Client.new(
        address: client.address,
        mnemonic: client.mnemonic,
        gas_info: {
          max_fee: 400_000
        }
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
      account_request_stub
    end

    it 'should throw error when no values are provided' do
      expect do
        client.create
      end.to raise_error(ArgumentError)
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

    it 'should create successfully' do
      initial_request_stub('crud/create', { 'Key': 'key', 'Value': 'value', 'Lease': '0' })
      stub = tx_request_stub({})

      client.create('key', 'value')

      expect(stub).to have_been_made.once
    end

    it 'should throw error on when not successful' do
      initial_request_stub('crud/create', { 'Key': 'key', 'Value': 'value', 'Lease': '0' })
      tx_request_stub({ 'error': { 'message': 'key already exists' } }, 400)

      expect do
        client.create('key', 'value')
      end.to raise_error 'key already exists'
    end
  end

  describe '#update' do
    before do
      account_request_stub
    end

    it 'should update key' do
      initial_request_stub('crud/update', { 'Key': 'key', 'Value': 'value', 'Lease': '0' })
      stub = tx_request_stub({})

      client.update('key', 'value')

      expect(stub).to have_been_made.once
    end
  end

  describe '#read' do
    before do
      account_request_stub
    end

    it 'should read key verified' do
      query_request_stub('pread/20fc19d4-7c9d-4b5c-9578-8cedd756e0ea/key', { 'value': 'value' })
      expect(client.read('key', true)).to eq('value')
    end

    it 'should read key unverified' do
      query_request_stub('read/20fc19d4-7c9d-4b5c-9578-8cedd756e0ea/key', { 'value': 'value' })
      expect(client.read('key')).to eq('value')
    end
  end

  describe '#tx_read' do
    before do
      account_request_stub
    end

    it 'should read key' do
      initial_request_stub('crud/read', { 'Key': 'key' })

      tx_request_stub({ 'data': to_hex(to_json_str({ 'value': 'value' })) })

      expect(client.tx_read('key')).to eq('value')
    end
  end

  describe '#delete' do
    before do
      account_request_stub
    end

    it 'should delete key' do
      stub_request(:delete, 'http://localhost:1317/crud/delete')
        .to_return(status: 200, body: JSON.generate(tx_create_skeleton))

      stub = tx_request_stub({ has: true })

      client.delete('key')

      expect(stub).to have_been_made.once
    end
  end

  describe '#has' do
    before do
      account_request_stub
    end

    it 'should return boolean' do
      query_request_stub('has/20fc19d4-7c9d-4b5c-9578-8cedd756e0ea/key', { 'has': true })

      expect(client.has('key')).to be_truthy
    end
  end

  describe '#tx_has' do
    before do
      account_request_stub
    end

    it 'should return boolean' do
      initial_request_stub('crud/has', { 'Key': 'key' })

      tx_request_stub({ 'data': to_hex(to_json_str({ 'has': true })) })

      expect(client.tx_has('key')).to be_truthy
    end
  end

  describe '#keys' do
    before do
      account_request_stub
    end

    it 'should return keys' do
      keys = %w[key1 key2 key3]

      query_request_stub('keys/20fc19d4-7c9d-4b5c-9578-8cedd756e0ea', { 'keys': keys })

      expect(client.keys).to include('key1')
    end
  end

  describe '#tx_keys' do
    before do
      account_request_stub
    end

    it 'should return keys' do
      keys = %w[key1 key2 key3]
      initial_request_stub('crud/keys')

      tx_request_stub({ 'data': to_hex(to_json_str({ 'keys': keys })) })

      expect(client.tx_keys).to include('key1')
    end
  end

  describe '#rename' do
    before do
      account_request_stub
    end

    it 'should rename key' do
      initial_request_stub('crud/rename', { 'Key': 'key', 'NewKey': 'new_key' })
      stub = tx_request_stub({})

      client.rename('key', 'new_key')

      expect(stub).to have_been_made.once
    end
  end

  describe '#count' do
    before do
      account_request_stub
    end

    it 'should return count' do
      query_request_stub('count/20fc19d4-7c9d-4b5c-9578-8cedd756e0ea', { 'count': 10 })

      expect(client.count).to eq(10)
    end
  end

  describe '#tx_count' do
    before do
      account_request_stub
    end

    it 'should return tx count' do
      initial_request_stub('crud/count')

      tx_request_stub({ 'data': to_hex(to_json_str({ 'count': 10 })) })

      expect(client.tx_count).to eq(10)
    end
  end

  describe '#delete_all' do
    before do
      account_request_stub
    end

    it 'should delete all successfully' do
      initial_request_stub('crud/deleteall')
      stub = tx_request_stub({})

      client.delete_all

      expect(stub).to have_been_made.once
    end
  end

  describe '#key_values' do
    before do
      account_request_stub
    end

    it 'should return key values' do
      kvs = { "keyvalues": [{ "key": 'key1', "value": 'value1' }, { "key": 'key2', "value": 'value2' }] }

      query_request_stub('keyvalues/20fc19d4-7c9d-4b5c-9578-8cedd756e0ea', kvs)

      expect(client.key_values).not_to be_nil
    end
  end

  describe '#tx_key_values' do
    before do
      account_request_stub
    end

    it 'should return key values' do
      kvs = { "keyvalues": [{ "key": 'key1', "value": 'value1' }, { "key": 'key2', "value": 'value2' }] }
      initial_request_stub('crud/keyvalues')

      tx_request_stub({ 'data': to_hex(to_json_str(kvs)) })

      expect(client.tx_key_values).not_to be_nil
    end
  end

  describe '#multi_update' do
    before do
      account_request_stub
    end

    it 'should update multiple values given key_values' do
      kvs = [{ 'key' => 'key1', 'value' => 'value1' }, { 'key' => 'key2', 'value' => 'value2' }]
      initial_request_stub('crud/multiupdate', { 'KeyValues' => [{ 'key' => 'key1', 'value' => 'value1' }, { 'key' => 'key2', 'value' => 'value2' }] })
      stub = tx_request_stub({})

      client.multi_update(kvs)

      expect(stub).to have_been_made.once
    end

    it 'should return error when not given array' do
      nt_supported = ['tx', 1, {}]

      nt_supported.each do |type|
        expect do
          client.multi_update(type)
        end.to raise_error ArgumentError
      end
    end
  end

  describe '#get_lease' do
    before do
      account_request_stub
    end

    it 'should return lease given key' do
      query_request_stub('getlease/20fc19d4-7c9d-4b5c-9578-8cedd756e0ea/key', { 'lease': '20' })

      res = client.get_lease('key')

      expect(res).to eq(100)
    end

    it 'should return error when key is not provided' do
      expect do
        client.get_lease
      end.to raise_error ArgumentError
    end
  end

  describe '#tx_get_lease' do
    before do
      account_request_stub
    end

    it 'should get lease given key' do
      initial_request_stub('crud/getlease', { 'Key': 'key' })
      tx_request_stub({ 'data': to_hex(to_json_str({ 'lease': '20' })) })

      res = client.tx_get_lease('key')

      expect(res).to eq(100)
    end

    it 'should return error when key is not provided' do
      expect do
        client.tx_get_lease
      end.to raise_error ArgumentError
    end
  end

  describe '#renew_lease' do
    before do
      account_request_stub
    end

    it 'should renew given key and lease' do
      initial_request_stub('crud/renewlease', { 'Key': 'key', 'Lease': '36966' })
      stub = tx_request_stub({})

      client.renew_lease('key', { 'days': '2', 'hours': '3', 'minutes': '20', 'seconds': '30' })

      expect(stub).to have_been_made.once
    end

    it 'should return error if key is not provided' do
      expect do
        client.renew_lease
      end.to raise_error ArgumentError
    end

    it 'should renew lease given key and no lease' do
      initial_request_stub('crud/renewlease', { 'Key': 'key', 'Lease': '0' })
      stub = tx_request_stub({})

      client.renew_lease('key')

      expect(stub).to have_been_made.once
    end
  end

  describe '#renew_lease_all' do
    before do
      account_request_stub
    end

    it 'should renew lease when given no lease' do
      initial_request_stub('crud/renewleaseall', { 'Lease': '0' })
      stub = tx_request_stub({})

      client.renew_lease_all

      expect(stub).to have_been_made.once
    end

    it 'should renew lease when given lease object' do
      initial_request_stub('crud/renewleaseall', { 'Lease': '36966' })

      stub = tx_request_stub({})

      client.renew_lease_all({ 'days': '2', 'hours': '3', 'minutes': '20', 'seconds': '30' })
      expect(stub).to have_been_made.once
    end
  end

  describe '#get_n_shortest_lease' do
    before do
      account_request_stub
    end

    it 'should get n shortest lease' do
      leases_data = [{ key: 'key1', lease: 100 }, { key: 'key2', lease: 200 }]
      query_request_stub(
        'getnshortestlease/20fc19d4-7c9d-4b5c-9578-8cedd756e0ea/10',
        { 'keyleases': leases_data }
      )

      leases = client.get_n_shortest_lease(10)

      expect(leases).not_to be_nil
    end
  end

  describe '#tx_get_n_shortest_lease' do
    before do
      account_request_stub
    end

    it 'should return shortest lease' do
      leases_data = [{ key: 'key1', lease: 100 }, { key: 'key2', lease: 200 }]

      initial_request_stub('crud/getnshortestlease', { N: '10' })

      tx_request_stub({ 'data': to_hex(to_json_str({ 'keyleases': leases_data })) })

      leases = client.tx_get_n_shortest_lease(10)

      expect(leases).not_to be_nil
    end
  end

  describe '#account' do
    before do
      account_request_stub
    end

    it 'should return account' do
      account = client.account

      expect(account).to include('account_number')
    end
  end

  describe '#version' do
    before do
      account_request_stub
    end

    it 'should return client version' do
      version_info = {
        "application": {
          "name": 'BluzelleService',
          "server_name": 'blzd',
          "client_name": 'blzcli',
          "version": '0.0.0-39-g8895e3e',
          "commit": '8895e3edf0a3ede0f6ed30f2224930e8faa1236e',
          "build_tags": 'ledger,faucet,cosmos-sdk v0.38.1',
          "go": 'go version go1.13.4 linux/amd64'
        }
      }

      stub_request(:get, 'http://localhost:1317/node_info')
        .to_return(status: 200, body: JSON.generate(version_info), headers: {})

      version = client.version

      # FIXME: Fix test
      expect(version).to eq(version_info[:version])
    end
  end

  def query_request_stub(path, data)
    stub_request(:get, "http://localhost:1317/crud/#{path}")
      .to_return(status: 200, body: JSON.generate({ result: data }), headers: {})
  end

  def initial_request_stub(endpoint, options = {})
    stub_request(options[:method] || :post, "http://localhost:1317/#{endpoint}")
      .to_return(status: 200, body: JSON.generate(tx_create_skeleton), headers: {})
  end

  def tx_request_stub(data, status = 200)
    stub_request(:post, 'http://localhost:1317/txs')
      .to_return(status: status, body: JSON.generate(data))
  end

  def account_request_stub
    stub_request(:get, 'http://localhost:1317/auth/accounts/bluzelle1xhz23a58mku7ch3hx8f9hrx6he6gyujq57y3kp')
      .to_return(
        status: 200,
        body: JSON.generate(response_data),
        headers: { 'Content-Type': 'application/json' }
      )
  end

  def to_hex(str)
    str.unpack('H*')[0]
  end

  def to_json_str(obj)
    JSON.generate(obj)
  end
end
