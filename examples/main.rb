require 'bluzelle'

client = Bluzelle::Swarm::Client.new(
  address: 'bluzelle1upsfjftremwgxz3gfy0wf3xgvwpymqx754ssu9',
  mnemonic: 'around buzz diagram captain obtain detail salon mango muffin brother morning jeans display attend knife carry green dwarf vendor hungry fan route pumpkin car',
  endpoint: 'testnet.public.bluzelle.com:1317',
  chain_id: 'bluzelle',
  uuid: '20fc19d4-7c9d-4b5c-9578-8cedd756e0ea',
  gas_info: {
    max_fee: '4000001'
  }
)

client.version
# 0.0.0-60-g1b32db7

client.account
# {"address"=>"bluzelle1upsfjftremwgxz3gfy0wf3xgvwpymqx754ssu9",
# "coins"=>[{"denom"=>"ubnt", "amount"=>"1199722793983680"}],
# "public_key"=>"bluzellepub1addwnpepqwnm94uc0yy338w7l3ghd8en0kg6nvds3h6l8n0wz355nhz35prtufpjsq2", "account_number"=>9, "sequence"=>302}

client.create 'key', 'value'

client.read 'key'
# value

client.update 'key', 'new_value'

client.read 'key'
# new_value

client.read 'key', true
# new_value

client.keys
# ['key']

client.delete 'key'
