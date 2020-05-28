require 'bluzelle'

client = Bluzelle::Swarm::Client.new(
  address: 'bluzelle1upsfjftremwgxz3gfy0wf3xgvwpymqx754ssu9',
  mnemonic: 'around buzz diagram captain obtain detail salon mango muffin brother morning jeans display attend knife carry green dwarf vendor hungry fan route pumpkin car',
  endpoint: 'testnet.public.bluzelle.com:1317',
  chain_id: 'bluzelle',
  uuid: '20fc19d4-7c9d-4b5c-9578-8cedd756e0ea',
)

gas_info = {
  max_fee: '4000001'
}

puts '#version'
puts client.version

puts '#account'
puts client.account

puts '#create'
puts 'creating key=db, value=redis'
client.create 'db', 'redis', gas_info
puts 'creating key=fs, value=ipfs'
client.create 'fs', 'ipfs', gas_info

puts '#read'
puts 'reading key=db'
puts "value=#{client.read 'db'}"
puts 'reading key=fs'
puts "value=#{client.read 'fs'}"

puts '#tx_read'
puts 'reading key=db'
puts "value = #{client.tx_read 'db', gas_info}"

puts '#update'
puts 'updating key=db, value=bluzelle'
client.update 'db', 'bluzelle', gas_info

puts '#read'
puts 'reading key=db'
puts "value=#{client.read 'db'}"

puts '#has'
puts 'has key=db'
puts client.has 'db'

puts '#tx_has'
puts 'has key=db'
puts client.tx_has 'db', gas_info

puts '#keys'
puts 'getting all keys'
puts client.keys

puts '#tx_keys'
puts 'getting all keys'
puts client.keys gas_info

puts '#rename'
puts 'rename key=db to key=database'
client.rename 'db', 'database', gas_info

puts '#count'
puts 'number of keys'
puts client.count

puts '#tx_count'
puts 'number of keys'
puts client.tx_count gas_info

puts '#key_values'
puts 'getting all keys and values'
puts client.key_values

puts '#tx_key_values'
puts 'getting all keys and values'
puts client.tx_key_values gas_info

puts '#multi_update'
puts 'update key=database, value=mongodb | key=fs, value=unix'
puts client.multi_update([
  { 'Key' => 'db', 'Value' => 'mongodb' },
  { 'Key' => 'fs', 'Value' => 'unix' }
  ], gas_info
)

puts '#key_values'
puts 'getting all keys and values'
puts client.key_values

puts '#get_lease'
puts 'lease key=database'
puts client.get_lease 'database'

puts '#tx_get_lease'
puts 'lease key=database'
puts client.tx_get_lease 'database', gas_info

puts '#renew_lease'
puts 'renew key=database, lease=1day'
client.renew_lease 'database', { 'days': 1 }, gas_info

puts '#get_lease'
puts 'lease key=database'
puts client.get_lease 'database'

puts '#renew_lease'
puts 'renew key=database, lease=1week'
client.renew_lease 'database', { 'days': 7 }, gas_info

puts '#get_lease'
puts 'lease key=database'
puts client.get_lease 'database'

puts '#renew_lease'
puts 'renew key=database, lease=1month'
client.renew_lease 'database', { 'days': 30 }, gas_info

puts '#get_lease'
puts 'lease key=database'
puts client.get_lease 'database'

puts '#renew_lease'
puts 'renew key=database, lease=1year'
client.renew_lease 'database', { 'days': 365 }, gas_info

puts '#get_lease'
puts 'lease key=database'
puts client.get_lease 'database'

puts '#renew_all_lease'
puts 'renew all lease=7days'
client.renew_lease_all({ 'days': 7 }, gas_info)

puts '#get_lease'
puts 'lease key=database'
puts client.get_lease 'database'

puts '#get_lease'
puts 'lease key=fs'
puts client.get_lease 'fs'

puts '#get_n_shortest_leases'
puts 'get n leases'
puts client.get_n_shortest_leases 10

puts '#tx_get_n_shortest_leases'
puts 'get n leases'
puts client.tx_get_n_shortest_leases 10, gas_info

