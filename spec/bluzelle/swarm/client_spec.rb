require 'spec_helper'

RSpec.describe Bluzelle::Swarm::Client do
    let(:client) {
        Bluzelle::Swarm::Client.new(
            address: 'bluzelle1xhz23a58mku7ch3hx8f9hrx6he6gyujq57y3kp',
            mnemonic: 'volcano arrest ceiling physical concert sunset absent hungry tobacco canal census era pretty car code crunch inside behind afraid express giraffe reflect stadium luxury',
            endpoint: "http://localhost:1317",
            chain_id: "bluzelle",
            uuid: '20fc19d4-7c9d-4b5c-9578-8cedd756e0ea'
        )
    }

    describe '#initialize' do
        it 'with default chain_id, endpoint and uuid' do
            @client = Bluzelle::Swarm::Client.new(
                address: client.address,
                mnemonic: client.mnemonic,
            )
            expect(@client.chain_id).to eq(client.chain_id)
            expect(@client.endpoint).to eq(client.endpoint)
            expect(@client.uuid).to eq(client.address)
        end
    
        it 'without address throws error' do
            expect{ Bluzelle::Swarm::Client.new(
                mnemonic: client.mnemonic,
                endpoint: client.endpoint,
                chain_id: client.chain_id,
                uuid: client.uuid
            ) }.to raise_error(ArgumentError)
        end

        it 'without mnemonic throws error' do
            expect{ Bluzelle::Swarm::Client.new(
                address: client.address,
                endpoint: client.endpoint,
                chain_id: client.chain_id,
                uuid: client.uuid
            )}.to raise_error(ArgumentError)
        end
    end
end