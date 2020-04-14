require 'spec_helper'

RSpec.describe Bluzelle::Swarm::TransactionQueue do
    describe '#initialize' do
        it 'should initialize successfully' do
            expect{
                described_class.new
            }.not_to raise_error
        end 
    end

    describe '#size?' do
        it 'should return correct size' do
            queue = described_class.new
            queue.enqueue(1)
            queue.enqueue(2)
            expect(queue.size?).to eq(2)
        end
    end

    describe '#enqueue' do
        it 'should add element to queue' do
            queue = described_class.new
            queue.enqueue(1)
            expect(queue.size?).to eq(1)
        end
    end

    describe '#isEmpty' do
        it 'should return true when queue has no items' do
            expect(described_class.new.isEmpty?).to be_truthy
        end

        it 'should return false when queue has items' do
            queue = described_class.new
            queue.enqueue(1)
            expect(queue.isEmpty?).to be_falsey
        end
    end

    describe '#dequeue' do
        it 'should remove first element from queue' do
            queue = described_class.new
            queue.enqueue(1)
            queue.enqueue(2)
            expect(queue.dequeue).to eq(1)
        end
    end

    describe '#front' do
        it 'should return first element in queue' do
            queue = described_class.new
            queue.enqueue(1)
            expect(queue.front).to eq(1)
        end
    end
end