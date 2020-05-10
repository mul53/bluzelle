require 'bip_mnemonic'
require 'bitcoin'
require 'money-tree'
require 'digest'
require 'openssl'
require 'base64'
require 'secp256k1'

module Bluzelle
  module Utils
    module_function

    def get_ec_private_key(mnemonic)
      seed = bip39_mnemonic_to_seed(mnemonic)
      node = bip32_from_seed(seed)
      child = node.node_for_path(Constants::PATH)
      ec_pair = create_ec_pair(child.private_key.to_hex)
      ec_pair.priv
    end

    def get_ec_public_key_from_priv(priv)
      key = open_key(priv)
      compressed_pub_key(key)
    end

    def validate_address(address, mnemonic)
      priv_key = get_ec_private_key(mnemonic)
      pub_key = get_ec_public_key_from_priv(priv_key)

      if get_address(pub_key) != address
        raise ArgumentError, 'Bad credentials - verify your address and mnemonic'
      end
    end

    def get_address(pub_key)
      hash = rmd_160_digest(sha_256_digest([pub_key].pack('H*')))
      word = bech32_convert_bits(to_bytes(hash))
      bech32_encode(Constants::PREFIX, word)
    end

    def to_bytes(obj)
      obj.bytes
    end

    def rmd_160_digest(hex)
      Digest::RMD160.digest hex
    end

    def sha_256_digest(hex)
      Digest::SHA256.digest hex
    end

    def bech32_encode(prefix, word)
      Bitcoin::Bech32.encode(prefix, word)
    end

    def bech32_convert_bits(bytes, from_bits: 8, to_bits: 5, pad: false)
      Bitcoin::Bech32.convert_bits(bytes, from_bits: from_bits, to_bits: to_bits, pad: pad)
    end

    def bip39_mnemonic_to_seed(mnemonic)
      BipMnemonic.to_seed(mnemonic: mnemonic)
    end

    def open_key(priv)
      group = OpenSSL::PKey::EC::Group.new('secp256k1')
      key = OpenSSL::PKey::EC.new(group)

      key.private_key = OpenSSL::BN.new(priv, 16)
      key.public_key = group.generator.mul(key.private_key)

      key
    end

    def compressed_pub_key(key)
      public_key = key.public_key
      public_key.group.point_conversion_form = :compressed
      public_key.to_hex.rjust(66, '0')
    end

    def bip32_from_seed(seed)
      MoneyTree::Master.new(seed_hex: seed)
    end

    def create_ec_pair(private_key)
      Bitcoin::Key.new(private_key, nil, { compressed: false })
    end

    def make_random_string(length = 32)
      random_string = ''
      chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'.chars

      1.upto(length) { random_string << chars.sample }

      random_string
    end

    def to_base64(str)
      Base64.strict_encode64(str)
    end

    def convert_lease(lease)
      return '0' if lease.nil?

      seconds = 0

      seconds += lease.dig(:days).nil? ? 0 : (lease.dig(:days).to_i * 24 * 60 * 60)
      seconds += lease.dig(:hours).nil? ? 0 : (lease.dig(:hours).to_i * 60 * 60)
      seconds += lease.dig(:minutes).nil? ? 0 : (lease.dig(:minutes).to_i * 60)
      seconds += lease.dig(:seconds).nil? ? 0 : lease.dig(:seconds).to_i

      (seconds / Constants::BLOCK_TIME_IN_SECONDS).to_s
    end

    def sort_hash(hash)
      hash_clone = hash.clone

      hash_clone.each do |key, value|
        hash_clone[key] = sort_hash(value) if value.is_a?(Hash)

        next unless value.is_a?(Array)

        arr = []

        hash_clone[key].each do |el|
          arr << sort_hash(el)
        end

        hash_clone[key] = arr
      end

      hash_clone.sort.to_h
    end

    def stringify_keys(hash)
      res = {}
  
      hash.each do |key, value|
        if value.is_a?(Hash)
          res[key.to_s] = stringify_keys(value)
          next
        end
        res[key.to_s] = value
      end
  
      res
    end

    def ecdsa_sign(payload, private_key)
      pk = Secp256k1::PrivateKey.new(privkey: hex_to_bin(private_key), raw: true)
      rs = pk.ecdsa_sign(payload)
      r = rs.slice(0, 32).read_string.reverse
      s = rs.slice(32, 32).read_string.reverse
      "#{r}#{s}"
    end

    def encode_json(obj)
      JSON.generate(obj)
    end

    def decode_json(str)
      JSON.parse(str)
    end

    def hex_to_bin(hex_str)
      [hex_str].pack('H*')
    end
  end
end
