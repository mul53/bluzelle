# API documentation
Read below for detailed documentation on how to use the Bluzelle database service.

### Bluzelle::Swarm::Client.new\({...}\)

Configures the Bluzelle connection. Multiple clients can be created by creating new instances of this class.

```ruby
require 'bluzelle'

api = Bluzelle::Swarm::Client.new({
    mnemonic: 'volcano arrest ceiling physical concert sunset absent hungry tobacco canal census era pretty car code crunch inside behind afraid express giraffe reflect stadium luxury',
    endpoint: "http://localhost:1317",
    uuid:     "20fc19d4-7c9d-4b5c-9578-8cedd756e0ea",
    chain_id: "bluzelle"
});
```

| Argument | Description |
| :--- | :--- |
| **mnemonic** | The mnemonic of the private key for your Bluzelle account |
| endpoint | \(Optional\) The hostname and port of your rest server. Default: http://localhost:1317 |
| uuid | \(Optional\) Bluzelle uses `UUID`'s to identify distinct databases on a single swarm. We recommend using [Version 4 of the universally unique identifier](https://en.wikipedia.org/wiki/Universally_unique_identifier#Version_4_%28random%29). Defaults to the account address. |
| chain_id | \(Optional\) The chain id of your Bluzelle account. Default: bluzelle |


The calls below are methods of the instance created by instantiating the `Bluzelle::Swarm::Client` class.

## General Functions

### version\()

Retrieve the version of the Bluzelle service.

```ruby
api.version
```

Returns a string containing the version information, e.g.

```
0.0.0-39-g8895e3e
```

Throws an exception if a response is not received from the connection.


### account\()

Retrieve information about the currently active Bluzelle account.

```ruby
api.account
```

Returns JSON object representing the account information, e.g.

Throws an exception if a response is not received from the connection.


## Database Functions

### create\(key, value , gas_info[,  lease_info]\)

Create a field in the database.

```ruby
api.create 'mykey', '{ a: 13 }', {gax_fee: '400001'}, {days: 100};
```

| Argument | Description |
| :--- | :--- |
| key | The name of the key to create |
| value | The string value to set the key |
| gas_info | Object containing gas parameters (see above) |
| lease_info (optional) | Minimum time for key to remain in database (see above) |

Returns nothing.

Throws an exception when a response is not received from the connection, the key already exists, or invalid value.

### read\(key, prove\)

Retrieve the value of a key without consensus verification. Can optionally require the result to have a cryptographic proof (slower).

```ruby
value = api.read 'mykey', {gax_fee: '400001'}
```

| Argument | Description |
| :--- | :--- |
| key | The key to retrieve |
| prove | A proof of the value is required from the network (requires 'config trust-node false' to be set) |

Returns the string value of the key.

Throws an exception when the key does not exist in the database.
Throws an exception when the prove is true and the result fails verification.

### tx_read\(key, gas_info\)

Retrieve the value of a key via a transaction (i.e. uses consensus).

```ruby
value = api.tx_read 'mykey', {max_fee: '400001'}
```

| Argument | Description |
| :--- | :--- |
| key | The key to retrieve |
| gas_info | Object containing gas parameters (see above) |

Returns the string value of the key.

Throws an exception when the key does not exist in the database.

### update\(key, value, gas_info[, lease_info]\)

Update a field in the database.

```ruby
api.update 'mykey', { a: 13 }, {max_fee: '400001'}, {days: 100}
```

| Argument | Description |
| :--- | :--- |
| key | The name of the key to create |
| value | The string value to set the key |
| gas_info | Object containing gas parameters (see above) |
| lease_info (optional) | Positive or negative amount of time to alter the lease by. If not specified, the existing lease will not be changed. |

Returns nothing.

Throws an exception when the key doesn't exist, or invalid value.

### delete\(key, gas_info\)

Delete a field from the database.

```ruby
api.delete 'mykey', {max_fee: '400001'}
```

| Argument | Description |
| :--- | :--- |
| key | The name of the key to delete |
| gas_info | Object containing gas parameters (see above) |

Returns nothing.

Throws an exception when the key is not in the database.

### has\(key\)

Query to see if a key is in the database. This function bypasses the consensus and cryptography mechanisms in favor of speed.


```ruby
hasMyKey = api.has 'mykey'
```

| Argument | Description |
| :--- | :--- |
| key | The name of the key to query |

Returns a boolean value - `true` or `false`, representing whether the key is in the database.

### tx_has\(key, gas_info\)

Query to see if a key is in the database via a transaction (i.e. uses consensus).

```ruby
hasMyKey = api.tx_has 'mykey', {gas_price: 10}
```

| Argument | Description |
| :--- | :--- |
| key | The name of the key to query |
| gas_info | Object containing gas parameters (see above) |

Returns a boolean value - `true` or `false`, representing whether the key is in the database.

### keys\(\)

Retrieve a list of all keys. This function bypasses the consensus and cryptography mechanisms in favor of speed.

```ruby
keys = api.keys
```

Returns an array of strings. ex. `["key1", "key2", ...]`.

### tx_keys\(gas_info\)

Retrieve a list of all keys via a transaction (i.e. uses consensus).

```ruby
keys = api.tx_keys { gas_price: 10 }
```

| Argument | Description |
| :--- | :--- |
| gas_info | Object containing gas parameters (see above) |

Returns an array of strings. ex. `["key1", "key2", ...]`.

### rename\(key, new_key, gas_info\)

Change the name of an existing key.

```ruby
api.rename 'key', 'newkey', {gas_price: 10}
```

| Argument | Description |
| :--- | :--- |
| key | The name of the key to rename |
| new_key | The new name for the key |
| gas_info | Object containing gas parameters (see above) |

Returns nothing.

Throws an exception if the key doesn't exist.


| Argument | Description |
| :--- | :--- |
| key | The name of the key to query |

Returns to a boolean value - `true` or `false`, representing whether the key is in the database.

### count\(\)

Retrieve the number of keys in the current database/uuid. This function bypasses the consensus and cryptography mechanisms in favor of speed.

```ruby
number = api.count
```

Returns an integer value.

### tx_count\(gas_info\)

Retrieve the number of keys in the current database/uuid via a transaction.

```ruby
number = api.tx_count {gas_price: 10}
```

| Argument | Description |
| :--- | :--- |
| gas_info | Object containing gas parameters (see above) |

Returns an integer value.

### delete_all\(gas_info\)

Remove all keys in the current database/uuid.

```ruby
api.delete_all {gas_price: 10}
```

| Argument | Description |
| :--- | :--- |
| gas_info | Object containing gas parameters (see above) |

Returns nothing.

### key_values\(\)

Enumerate all keys and values in the current database/uuid. This function bypasses the consensus and cryptography mechanisms in favor of speed.

```ruby
kvs = api.key_values;
```

Returns a JSON array containing key/value pairs, e.g.

```
[{"key": "key1", "value": "value1"}, {"key": "key2", "value": "value2"}]
```

### tx_key_values\(gas_info\)

Enumerate all keys and values in the current database/uuid via a transaction.

```ruby
kvs = api.tx_key_values {gas_price: 10}
```

| Argument | Description |
| :--- | :--- |
| gas_info | Object containing gas parameters (see above) |

Returns a JSON array containing key/value pairs, e.g.

```
[{"key": "key1", "value": "value1"}, {"key": "key2", "value": "value2"}]
```

### multi_update\(key_values, gas_info\)

Update multiple fields in the database.

```ruby
api.multi_update([{key: "key1", value: "value1"}, {key: "key2", value: "value2"}, {gas_price: 10})
```

| Argument | Description |
| :--- | :--- |
| key_values | An array of objects containing keys and values (see example avove) |
| gas_info | Object containing gas parameters (see above) |

Returns nothing.

Throws an exception when any of the keys doesn't exist.


### get_lease\(key\)

Retrieve the minimum time remaining on the lease for a key. This function bypasses the consensus and cryptography mechanisms in favor of speed.

```ruby
value = api.get_lease 'mykey'
```

| Argument | Description |
| :--- | :--- |
| key | The key to retrieve the lease information for |

Returns the minimum length of time remaining for the key's lease, in seconds.

Throws an exception when the key does not exist in the database.

### tx_get_lease\(key, gas_info\)

Retrieve the minimum time remaining on the lease for a key, using a transaction.

```ruby
value = api.tx_get_lease 'mykey', {gas_price: 10}
```

| Argument | Description |
| :--- | :--- |
| key | The key to retrieve the lease information for |
| gas_info | Object containing gas parameters (see above) |

Returns the minimum length of time remaining for the key's lease, in seconds.

Throws an exception when the key does not exist in the database.

### renew_lease\(key, gas_info[, lease_info]\)

Update the minimum time remaining on the lease for a key.

```ruby
value = api.renew_lease 'mykey', {max_fee: '400001'}, { days: 100 }
```

| Argument | Description |
| :--- | :--- |
| key | The key to retrieve the lease information for |
| gas_info | Object containing gas parameters (see above) |
| lease_info (optional) | Minimum time for key to remain in database (see above) |

Returns the minimum length of time remaining for the key's lease.

Throws an exception when the key does not exist in the database.


### renew_lease_all\(gas_info[, lease_info]\)

Update the minimum time remaining on the lease for all keys.

```ruby
value = api.renew_lease_all {max_fee: '400001'}, { days: 100 }
```

| Argument | Description |
| :--- | :--- |
| gas_info | Object containing gas parameters (see above) |
| lease_info (optional) | Minimum time for key to remain in database (see above) |

Returns the minimum length of time remaining for the key's lease.

Throws an exception when the key does not exist in the database.


### get_n_shortest_lease\(n\)

Retrieve a list of the n keys in the database with the shortest leases.  This function bypasses the consensus and cryptography mechanisms in favor of speed.
 
```ruby

keys = api.get_n_shortest_lease 10

```

| Argument | Description |
| :--- | :--- |
| n  | The number of keys to retrieve the lease information for |

Returns a JSON array of objects containing key, lease (in seconds), e.g.
```
[ { key: "mykey", lease: { seconds: "12345" } }, {...}, ...]
```

### tx_get_n_shortest_lease\(n, gas_info\)

Retrieve a list of the N keys/values in the database with the shortest leases, using a transaction.
 
```ruby

keys = api.tx_get_n_shortest_lease 10, {max_fee: '400001'}

```

| Argument | Description |
| :--- | :--- |
| n | The number of keys to retrieve the lease information for |
| gas_info | Object containing gas parameters (see above) |

Returns a JSON array of objects containing key, lifetime (in seconds), e.g.
```
[ { key: "mykey", lifetime: "12345" }, {...}, ...]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mul53/bluzelle. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/mul53/bluzelle/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Bluzelle project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/mul53/bluzelle/blob/master/CODE_OF_CONDUCT.md).
