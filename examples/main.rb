require 'bluzelle'

client = Bluzelle::Swarm::Client.new(
  address: 'bluzelle1upsfjftremwgxz3gfy0wf3xgvwpymqx754ssu9',
  mnemonic: 'around buzz diagram captain obtain detail salon mango muffin brother morning jeans display attend knife carry green dwarf vendor hungry fan route pumpkin car',
  endpoint: 'testnet.public.bluzelle.com:1317',
  chain_id: 'bluzelle',
  uuid: '20fc19d4-7c9d-4b5c-9578-8cedd756e0ea'
)

puts client.version 
# 0.0.0-60-g1b32db7

puts client.account
 