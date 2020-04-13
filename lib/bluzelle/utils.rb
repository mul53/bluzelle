require 'bip_mnemonic'
require 'bitcoin'
require 'money-tree'
require 'digest'
require 'openssl'

module Bluzelle
    module Utils
        PREFIX = 'bluzelle'
        PATH = "m/44'/118'/0'/0/0"

        module_function

        def get_ec_private_key(mnemonic)
            seed = bip39_mnemonic_to_seed(mnemonic)
            node = bip32_from_seed(seed)
            child = node.node_for_path(PATH)
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

            raise ArgumentError.new('Bad credentials - verify your address and mnemonic') if get_address(pub_key) != address
        end

        def get_address(pub_key)
            hash = rmd_160_digest(sha_256_digest([pub_key].pack('H*')))
            word = bech32_convert_bits(to_bytes(hash))
            bech32_encode(PREFIX, word)
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
    end
end