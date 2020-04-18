require 'bluzelle'

client = Bluzelle::Swarm::Client.new(
  address: 'bluzelle1xhz23a58mku7ch3hx8f9hrx6he6gyujq57y3kp',
  mnemonic: 'volcano arrest ceiling physical concert sunset absent hungry tobacco canal census era pretty car code crunch inside behind afraid express giraffe reflect stadium luxury',
  endpoint: 'testnet.public.bluzelle.com:1317',
  chain_id: 'bluzelle',
  uuid: '20fc19d4-7c9d-4b5c-9578-8cedd756e0ea'
)

puts client.version # 0.0.0-60-g1b32db7
 