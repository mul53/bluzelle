require 'spec_helper'

RSpec.describe Bluzelle::Utils do
    let(:data) {
        {
            mnemonic: 'volcano arrest ceiling physical concert sunset absent hungry tobacco canal census era pretty car code crunch inside behind afraid express giraffe reflect stadium luxury',
            endpoint: 'http://localhost:1317',
            address: 'bluzelle1xhz23a58mku7ch3hx8f9hrx6he6gyujq57y3kp'
        }
    }

    describe '#get_ec_private' do
        it 'should return correct private key' do
            expect(
                Bluzelle::Utils.get_ec_private_key(data[:mnemonic])
            ).to eq('f02e2c689c06fa26587592b2232275da63b72a369330d89ae1ff6918afc1a2ab')
        end
    end

    describe '#get_address' do
        it 'should return right address' do
            expect(
                Bluzelle::Utils.get_address('0354c8c2d5871606c9b99978f8c49f34fa41e0639cdbc480fed1cbf30aad5d25fb')
            ).to eq('bluzelle1xhz23a58mku7ch3hx8f9hrx6he6gyujq57y3kp')
        end
    end
end