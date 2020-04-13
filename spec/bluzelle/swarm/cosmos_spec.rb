require 'spec_helper'

RSpec.describe Bluzelle::Swarm::Cosmos do
    let(:cosmos) {
        Bluzelle::Swarm::Cosmos.new(
            mnemonic: 'volcano arrest ceiling physical concert sunset absent hungry tobacco canal census era pretty car code crunch inside behind afraid express giraffe reflect stadium luxury',
            endpoint: 'http://localhost:1317',
            address: 'bluzelle1xhz23a58mku7ch3hx8f9hrx6he6gyujq57y3kp'
        )
    }

    describe '#initialize' do
        it 'should throw error if address validation fails' do
            expect{
                Bluzelle::Swarm::Cosmos.new(
                    mnemonic: cosmos.mnemonic,
                    endpoint: cosmos.endpoint,
                    address: "#{cosmos.address}x"
                )
            }.to raise_error('Bad credentials - verify your address and mnemonic')
        end

        it 'retrieves account information'
    end
end