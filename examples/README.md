# Example
This is an example of how to use blzrb

## Installation(ubuntu 18.04)

### Install dependencies
1. `sudo apt-get update`
2. `sudo apt-get install g++`
3. install ruby, rbenv
    ```
    git clone https://github.com/rbenv/rbenv.git ~/.rbenv
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc
    exec $SHELL

    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
    echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
    exec $SHELL

    rbenv install 2.7.1
    rbenv global 2.7.1
    ruby -v
   ```
4. `sudo apt-get install libsecp256k1-dev`

### Setup project
1. Create a folder for your project
2. Init the proejct with composer `bundle init`
3. Add this line to your Gemfile `gem 'blzrb'`
4. Run `bundle install`
4. Create a file called `main.rb` and include the code below

```ruby
require 'bluzelle'

bz = Bluzelle::Swarm::Client.new(
  mnemonic: 'around buzz diagram captain obtain detail salon mango muffin brother morning jeans display attend knife carry green dwarf vendor hungry fan route pumpkin car',
  endpoint: 'http://testnet.public.bluzelle.com:1317',
  chain_id: 'bluzelle',
  uuid: '20fc19d4-7c9d-4b5c-9578-8cedd756e0ea',
)

bz.create 'somekey', 'somevalue', { 'max_fee': '400000000' }
puts bz.read 'somekey'
```
5. Run the file `ruby main.rb`

To run more tests copy the script in `examples/main.rb` to your file and run your file