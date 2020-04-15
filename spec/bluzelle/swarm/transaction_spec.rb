require 'spec_helper'

RSpec.describe Bluzelle::Swarm::Transaction do
    let(:transaction) { described_class.new(:get, '/accounts', {}) }
    
    describe '#set_gas' do
        it 'should not set values when not given gas_info' do
            tx = transaction
            
            tx.set_gas()
            
            expect(tx.gas_price).to eq(0)
            expect(tx.max_gas).to eq(0)
            expect(tx.max_fee).to eq(0)
        end

        it 'should set values correctly when given gas_info' do
            tx = transaction
            
            tx.set_gas({ 
                'gas_price': '10',
                'max_gas': '5',
                'max_fee': '15'
            })
            
            expect(tx.gas_price).to eq(10)
            expect(tx.max_gas).to eq(5)
            expect(tx.max_fee).to eq(15)
        end
    end
end