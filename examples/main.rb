require 'bluzelle'

client = Bluzelle::Swarm::Client.new(
  address: 'bluzelle1upsfjftremwgxz3gfy0wf3xgvwpymqx754ssu9',
  mnemonic: 'around buzz diagram captain obtain detail salon mango muffin brother morning jeans display attend knife carry green dwarf vendor hungry fan route pumpkin car',
  endpoint: 'testnet.public.bluzelle.com:1317',
  chain_id: 'bluzelle',
  uuid: '20fc19d4-7c9d-4b5c-9578-8cedd756e0ea'
)

gas_info = {
  max_fee: '4000001'
}

puts "\n#version"
puts client.version

puts "\n#account"
puts client.account

puts "\n#delete_all"
client.delete_all gas_info

puts "\n#create"
puts 'creating key=db, value=redis'
client.create 'db', 'redis', gas_info
puts 'creating key=fs, value=ipfs'
client.create 'fs', 'ipfs', gas_info

puts "\n#read"
puts 'reading key=db'
puts "value=#{client.read 'db'}"
puts 'reading key=fs'
puts "value=#{client.read 'fs'}"

puts "\n#tx_read"
puts 'reading key=db'
puts "value = #{client.tx_read 'db', gas_info}"

puts "\n#update"
puts 'updating key=db, value=bluzelle'
client.update 'db', 'bluzelle', gas_info

puts "\n#read"
puts 'reading key=db'
puts "value=#{client.read 'db'}"

puts "\n#has"
puts 'has key=db'
puts client.has 'db'

puts "\n#tx_has"
puts 'has key=db'
puts client.tx_has 'db', gas_info

puts "\n#keys"
puts 'getting all keys'
puts client.keys

puts "\n#tx_keys"
puts 'getting all keys'
puts client.tx_keys gas_info

puts "\n#rename"
puts 'rename key=db to key=database'
client.rename 'db', 'database', gas_info

puts "\n#count"
puts 'number of keys'
puts client.count

puts "\n#tx_count"
puts 'number of keys'
puts client.tx_count gas_info

puts "\n#key_values"
puts 'getting all keys and values'
puts client.key_values

puts "\n#tx_key_values"
puts 'getting all keys and values'
puts client.tx_key_values gas_info

puts "\n#multi_update"
puts 'update key=database, value=mongodb | key=fs, value=unix'
puts client.multi_update([
                           { 'key' => 'database', 'value' => 'mongodb' },
                           { 'key' => 'fs', 'value' => 'unix' }
                         ], gas_info)

puts "\n#key_values"
puts 'getting all keys and values'
puts client.key_values

puts "\n#get_lease"
puts 'lease key=database'
puts client.get_lease 'database'

puts "\n#tx_get_lease"
puts 'lease key=database'
puts client.tx_get_lease 'database', gas_info

puts "\n#renew_lease"
puts 'renew key=database, lease=1day'
client.renew_lease 'database', { 'days': 1 }, gas_info

puts "\n#get_lease"
puts 'lease key=database'
puts client.get_lease 'database'

puts "\n#renew_lease"
puts 'renew key=database, lease=1week'
client.renew_lease 'database', { 'days': 7 }, gas_info

puts "\n#get_lease"
puts 'lease key=database'
puts client.get_lease 'database'

puts "\n#renew_lease"
puts 'renew key=database, lease=1month'
client.renew_lease 'database', { 'days': 30 }, gas_info

puts "\n#get_lease"
puts 'lease key=database'
puts client.get_lease 'database'

puts "\n#renew_lease"
puts 'renew key=database, lease=1year'
client.renew_lease 'database', { 'days': 365 }, gas_info

puts "\n#get_lease"
puts 'lease key=database'
puts client.get_lease 'database'

puts "\n#renew_all_lease"
puts 'renew all lease=7days'
client.renew_lease_all({ 'days': 7 }, gas_info)

puts "\n#get_lease"
puts 'lease key=database'
puts client.get_lease 'database'

puts "\n#get_lease"
puts 'lease key=fs'
puts client.get_lease 'fs'

puts "\n#get_n_shortest_leases"
puts 'get n leases'
puts client.get_n_shortest_leases 10

puts "\n#tx_get_n_shortest_leases"
puts 'get n leases'
puts client.tx_get_n_shortest_leases 10, gas_info
