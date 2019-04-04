#!/usr/bin/env ruby
require 'stellar-sdk'

TOKEN_NAME = "FOOBAR"
TOTAL_CIRCULATION = 20_000_000_000

client = Stellar::Client.default_testnet

# an account to fund all other operations
FUNDER_SEED = 'SDYF7NHESQ3OZG25EJQM2CYVVJ5BWM5ZUF7DF22ABZ7HVTGCRBYTY7P5'
funder = Stellar::Account.from_seed(FUNDER_SEED)

# create issuer account
puts "Creating issuer account:"
issuer = Stellar::Account.random
puts issuer.address
puts issuer.keypair.seed

# creating an account with 10 XLM
client.create_account(account: issuer, funder: funder, starting_balance: 10)

puts ""
puts "Creating distributor account:"
distributor = Stellar::Account.random
puts distributor.address
puts distributor.keypair.seed

client.create_account(account: distributor, funder: funder, starting_balance: 10)

puts ""
puts "Adding trustline.."

client.change_trust(asset: [:alphanum12, TOKEN_NAME, issuer.keypair], source: distributor, limit: TOTAL_CIRCULATION)

puts ""
puts "Issuing tokens.."

asset = Stellar::Asset.alphanum12(TOKEN_NAME, issuer.keypair)
client.send_payment(from: issuer, to: distributor, amount:Stellar::Amount.new(TOTAL_CIRCULATION, asset))

puts ""
puts "Locking issuer.."

### going low level because there is no client#set_options ###
set_options_args = {
  account: issuer.keypair,
  sequence: (client.account_info(issuer).sequence.to_i + 1),
  master_weight: 0,
  low_threshold: 0,
  med_threshold: 0,
  high_threshold: 0
}
tx = Stellar::Transaction.set_options(set_options_args)
envelope_base64 = tx.to_envelope(issuer.keypair).to_xdr(:base64)
client.horizon.transactions._post(tx: envelope_base64)

puts ""
puts "Distributing coins to a random address:"

random = Stellar::Account.random
client.create_account(account: random, funder: funder, starting_balance: 5)
puts random.address
puts random.keypair.seed

client.change_trust(asset: [:alphanum12, TOKEN_NAME, issuer.keypair], source: random, limit: TOTAL_CIRCULATION)
client.send_payment(from: distributor, to: random, amount:Stellar::Amount.new(100, asset))
