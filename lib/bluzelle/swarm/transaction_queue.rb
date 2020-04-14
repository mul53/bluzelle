module Bluzelle
    module Swarm
        class TransactionQueue
            def initialize
                @queue = []
            end

            def size?
                @queue.size
            end

            def enqueue(el)
                @queue << el
            end

            def isEmpty?
                @queue.empty?
            end

            def dequeue
                @queue.shift
            end

            def front
                @queue[0]
            end
        end
    end
end