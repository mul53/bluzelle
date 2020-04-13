require 'bip_mnemonic'
require 'bitcoin'
require 'money-tree'
require 'digest'
require 'openssl'

module Bluzelle
    module Utils
        module_function

        def get_ec_private_key(mnemonic)
            seed_hex = BipMnemonic.to_seed(mnemonic: mnemonic)
            master = MoneyTree::Master.new(seed_hex: seed_hex)
            child = master.node_for_path("m/44'/118'/0'/0/0")
            ec_pair = Bitcoin::Key.new(child.private_key.to_hex, nil, { compressed: false })
            ec_pair.priv
        end

        def get_ec_public_key_from_priv(priv)
            group = OpenSSL::PKey::EC::Group.new('secp256k1')
            key = OpenSSL::PKey::EC.new(group)

            key.private_key = OpenSSL::BN.new(priv, 16)
            key.public_key = group.generator.mul(key.private_key)

            public_key = key.public_key
            public_key.group.point_conversion_form = :compressed
            public_key.to_hex.rjust(66, '0')
        end

        def validate_address(address, mnemonic)
            priv_key = get_ec_private_key(mnemonic)
            pub_key = get_ec_public_key_from_priv(priv_key)

            raise ArgumentError.new('Bad credentials - verify your address and mnemonic') if get_address(pub_key) != address
        end

        def get_address(pub_key)
            hash = Digest::RMD160.digest(
                Digest::SHA256.digest([pub_key].pack('H*'))
            )
            word = Bitcoin::Bech32.convert_bits(hash.bytes, from_bits: 8, to_bits: 5, pad: false)
            Bitcoin::Bech32.encode('bluzelle', word)
        end
    end
end