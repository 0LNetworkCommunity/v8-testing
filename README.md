# Twin Testnet V8 Features Testing Guide

Thank you for participating in testing the new V8 features on our twin testnet. This document provides step-by-step instructions for using the Libra CLI to execute test transactions.

### See participating [testnet accounts addresses](./test-accounts.md)

# Cheat Sheet

```
export MY_ADDR=<YOUR ADDRESS>
export TO=<SOMEONE'S ADDRESS>

# trigger an epoch
libra txs governance epoch-boundary
# init your account
libra txs user human-founder
# check if your account migrated
libra query view -f 0x1::founder::is_founder -a $MY_ADDR
# vouch for someone
libra txs user vouch --vouch-for $TO
# get your social score
libra query view -f 0x1::page_rank_lazy::get_cached_score -a $MY_ADDR
# get your vouching limit
libra query view -f 0x1::vouch_limits::get_vouch_limit -a $MY_ADDR
# if you have enough vouches with a high social score it should be authorized
libra query view -f 0x1::reauthorization::is_v8_authorized -a $MY_ADDR

# ON NEXT EPOCH you'll get a drip
# get balance
libra query balance $MY_ACCOUNT
# Now you can transfer
libra txs transfer -t $TO -a 100
```

## Important Note: Using The correct Network
The instructions below will help configure a proper `~/.libra/libra-cli-config.yaml` to use for testing. It will setup to include the chain id 2 (in configs as `chain_name: TESTNET`).

### Be extra safe
If you are using a device that has had production keys and settings in the past, you should be explicit with the arguments in the CLI.

For belt-and-suspenders testing, you should also explicitly include the chain ID in your CLI arguments for testing.

**Always include `--chain-name=testnet` and `--url <TESTNET URL>` immediately after the `txs` command when using the twin testnet.**

For the `query` command, you can use `--url <TESTNET URL>` when using the twin testnet.

This parameter specifies that you're interacting with the twin testnet (Chain ID 2) rather than the mainnet (Chain ID 1). The correct format is:

```bash
libra txs --chain-name=testnet --url https://twin-rpc.openlibra.space [subcommand] [options]
```

Without this parameter in the correct position, your transactions will attempt to target the mainnet and might succeed, or worse, could be used for replay attacks.


## Prerequisites

- Libra CLI installed (version 8.0.0-rc.4 or higher, see below for the latest branch under test)
- An account previously existing on mainnet

## Install
```
git clone https://github.com/0LNetworkCommunity/libra-framework
git checkout release-8.0.0-rc.9

cd libra-framework
cargo build --release -p libra
cp ./target/release/libra $HOME/.cargo/bin

# confirm install
which libra
libra version
```

## Setup

1. Configure your CLI to connect to the twin testnet:

  ```bash
  # config for testnet and the mnemonic to set up addresses and authkeys

  libra config --chain-name=testnet init --fullnode-url=https://twin-rpc.openlibra.space

  # if you do not wish to enter a mnemonic on config you can enter the address and authkey directly.

  libra config --chain-name=testnet \
  init \
  --fullnode-url https://twin-rpc.openlibra.space \
  --force-address <ADDRESS> \
  --force-authkey <AUTHKEY>

  ```

2. Verify your connection:

```bash
# check the epoch
libra query epoch
# check block height
libra query block-height
```

## FILO Migration Features

### Feature 1: V7 Accounts as Slow Wallets

NOTE: the epoch must have changed once.

```
## trigger new epoch, can happen ever 5 mins
libra txs governance epoch-boundary

## check the root of trust list is not empty
libra query view -f 0x1::root_of_trust::get_current_roots_at_registry -a 0x1
```


### Description
In V8, all V7 accounts have been converted to slow wallets. This means previously unlocked balances are now considered dormant until human reauthorization with Vouch is completed.

### Testing Steps

1. Check your account balance:

```bash
libra query balance <ACCOUNT>
# will display [<unlocked>, <total>]
```

2. Verify that:
   - Previously unlocked balances show as 0 unlocked
   - Your total balance shows the full amount (same as your previous balance)

3. Try to make a transfer (this should fail):

  ```bash
  libra txs --chain-name=testnet \
  --url https://twin-rpc.openlibra.space \
  transfer \
  --to-account=<RECIPIENT_ADDRESS> \
  --amount=10
  ```
3.1 Assert your account is a human founder (without this none of the accounts will be able to vouch for your account):
```
libra txs --chain-name=testnet --url https://twin-rpc.openlibra.space/ user human-founder
```

4. Complete reauthorization through vouching:
  - Ask other testnet participants to vouch for you using:
  ```bash
  libra txs --chain-name=testnet \
  --url https://twin-rpc.openlibra.space \
  user vouch \
  --vouch-for=<SOME ADDRESS>
  ```

   - A user can check how many remaining vouches they have to give with:

  ```bash
   libra query --url https://twin-rpc.openlibra.space view --function-id 0x1::vouch_limits::get_vouch_limit --args <YOUR_ADDRESS>
   ```

   - After each vouch, check your vouch score increasing:

   ```bash
   libra query --url https://twin-rpc.openlibra.space view --function-id 0x1::page_rank_lazy::get_cached_score --args <YOUR_ADDRESS>
   ```

   - Continue until you have enough vouches to unlock your balance

5. After sufficient number of vouches you should see a the `Founder` status and that the account is reauthorized:

  ```bash
  libra query --url https://twin-rpc.openlibra.space view --function-id 0x1::founder::is_founder --args <YOUR_ADDRESS>
  ```

  ```bash
  libra query --url https://twin-rpc.openlibra.space view --function-id 0x1::reauthorization::is_v8_authorized --args <YOUR_ADDRESS>
  ```

6. After every epoch boundary (15 minutes in testnet), you should see the unlocked balance increase

  ```bash
  libra query balance <YOUR_ADDRESS>
  ```

6. Assuming you have some unlocked balance, try the transfer again (should succeed now):

  ```bash
  libra txs --chain-name=testnet --url https://twin-rpc.openlibra.space transfer --to-account <RECIPIENT_ADDRESS> --amount 10
  ```

### Expected Outcome
- Initial balance check shows 0 unlocked tokens with full total balance
- First transfer attempt fails with an error about insufficient unlocked tokens
- Vouch score increases with each received vouch
- After receiving sufficient vouches, balance shows unlocked tokens
- Second transfer attempt completes successfully


## Community Wallet Reauthorization Votes

### Feature 4: Submit Vote for Community Wallet Reauthorization

### Description
This feature allows community members to vote on reauthorizing community wallet spending. It's part of the governance improvements in V8.

### Testing Steps
```
export CW_ADDR=<CW ADDRESS>
export CW_ADDR=0x2B0E8325DEA5BE93D856CFDE2D0CBA12
```

1. Check the list of pending community wallet reauthorization proposals:

```bash
libra query view -f  0x1::donor_voice_governance::get_reauth_ballots -a $CW_ADDR
libra query view -f 0x1::donor_voice_governance::is_reauth_proposed -a $CW_ADDR
```

2. Submit your vote for a community wallet reauthorization:

```bash
libra txs community reauthorize --community-wallet $CW_ADDR
```


3. Check the total votes on the reauthorization:

```bash
libra query view -f 0x1::donor_voice_governance::get_reauth_tally -a "$CW_ADDR, <ID OF PROPOSAL>"
```
## CW can send transactions

```
libra txs community propose -c $CW_ADDR -r 0x37799DA327DB4C58D5E28E7DD6338F6B -a 1000 -d test0 --advance
```


### Expected Outcome
- Your vote is recorded successfully
- The proposal's vote count increases accordingly
- Once enough votes are collected, the proposal state should change to either approved or rejected

