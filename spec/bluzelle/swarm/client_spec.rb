require 'spec_helper'

RSpec.describe Bluzelle::Swarm::Client do
    it 'has default chain_id' do
        @client = Bluzelle::Swarm::Client.new(
            address: '',
            mnemonic: '',
            uuid: '',
            endpoint: ''
        )
        expect(@client.chain_id).to eq('bluzelle')
    end

    it 'has default endpoint' do
        @client = Bluzelle::Swarm::Client.new(
            address: '',
            mnemonic: '',
            uuid: '',
            chain_id: ''
        )
        expect(@client.endpoint).to eq('http://localhost:1317')
    end
end