# test.mk - Helper commands for testing the V8 features on twin testnet
# Based on instructions in tools/twin_testnet_v8_testing.md

# Default variables
CHAIN_ID := 2
TESTNET_URL := https://twin-testnet-rpc.libra.org
CHAIN_NAME := testnet
# Makefile for Libra Framework
FULLNODE := https://twin-rpc.openlibra.space

# List of addresses to vouch for
VOUCH_ADDRESSES := \
    0xECAF65ADD1B785B0495E3099F4045EC0 \
    0x46A7A744B5D33C47F6B20766F8088B10 \
    0xEA10EA06C0FDAB689DA9DCF78FC90F4E \
    0xD67F3FF22BD719EB5BE2DF6577C9B42D \
    0x7E56B29CB23A49368BE593E5CFC9712E \
    0x304A03C0B4ACDFDCE54BFAF39D4E0448 \
    0x2B0E8325DEA5BE93D856CFDE2D0CBA12 \
    0xFBE8DA53C92CEEEB40D8967EC033A0FB \
    0xBC25F79FEF8A981BE4636AC1A2D6F587 \
    0x37799DA327DB4C58D5E28E7DD6338F6B \
    0x111a82b5422e244632f0935899488a863d61c1f13cb0458f89d97bf1bb800c11 \
    0xD3F6B48DE139E02DF101658D5FCF5EFBA5DC4C47ADC7CED6748D97B42FAF5F41 \
    0xC8F2D9C6B28A10CA250AF6219F81EA3F2677CF1F61124246D4901ED115996485 \
    0x4B08C148F5E80962BE1E5755F0D2ED29

# Helper to get address from config or prompt if not found
define get_address
$(eval MY_ADDRESS := $(shell libra config show --path="profileConfig.default_account" 2>/dev/null))
@if [ -z "${MY_ADDRESS}" ]; then \
    read -p "Enter your address: " MY_ADDRESS; \
    echo $$MY_ADDRESS; \
else \
    echo ${MY_ADDRESS}; \
fi
endef

# Setup and Configuration
config:
	@echo "Configuring CLI for twin testnet..."
	libra config --chain-name=${CHAIN_NAME} init --fullnode-url=${TESTNET_URL}

config-with-address:
	@echo "Configuring CLI for twin testnet with address and authkey..."
	@read -p "Enter your address: " MY_ADDRESS; \
	read -p "Enter your authkey: " AUTHKEY; \
	libra config --chain-name=${CHAIN_NAME} init --fullnode-url=${TESTNET_URL} \
	--force-address $$MY_ADDRESS --force-authkey $$AUTHKEY

# Verification Commands
check-epoch:
	@echo "Checking current epoch..."
	libra query epoch

check-block-height:
	@echo "Checking block height..."
	libra query block-height

check-balance:
	@echo "Checking balance..."
	$(eval MY_ADDRESS := $(shell $(call get_address)))
	libra query balance ${MY_ADDRESS}


# FILO Migration Features
transfer:
	@echo "Attempting to transfer funds..."
	@read -p "Enter recipient address: " RECIPIENT; \
	read -p "Enter amount to transfer: " AMOUNT; \
	libra txs --chain-id=${CHAIN_ID} transfer --to $$RECIPIENT --amount $$AMOUNT

vouch-for:
	@echo "Vouching for an account..."
	@read -p "Enter address to vouch for: " TARGET_ADDRESS; \
	libra txs --chain-id=${CHAIN_ID} user vouch --vouch-for=$$TARGET_ADDRESS

# Target to vouch for all listed accounts
vouch-all:
	@echo "Starting to vouch for all accounts..."
	@for addr in $(VOUCH_ADDRESSES); do \
		echo "Vouching for $$addr"; \
		libra txs -m="$$MNEM" --chain-name=testnet --url=${FULLNODE} user vouch --vouch-for $$addr || echo "Failed to vouch for $$addr, continuing..."; \
	done
	@echo "Completed vouching for all accounts."


check-remaining-vouches:
	@echo "Checking remaining vouches..."
	$(eval MY_ADDRESS := $(shell $(call get_address)))
	libra query view -f 0x1::vouch_limits::get_remaining_vouches --args ${MY_ADDRESS}

check-vouch-score:
	@echo "Checking vouch score..."
	$(eval MY_ADDRESS := $(shell $(call get_address)))
	libra query view -f 0x1::page_rank_lazy::get_cached_score --args ${MY_ADDRESS}

check-founder-status:
	@echo "Checking founder status..."
	$(eval MY_ADDRESS := $(shell $(call get_address)))
	libra query view -f 0x1::founder::is_founder --args ${MY_ADDRESS}

check-reauthorization:
	@echo "Checking if account is reauthorized..."
	$(eval MY_ADDRESS := $(shell $(call get_address)))
	libra query view -f 0x1::reauthorization::is_v8_authorized --args ${MY_ADDRESS}

# Community Wallet Reauthorization
list-community-wallet-proposals:
	@echo "Listing pending community wallet proposals..."
	libra query view -f 0x1::community_wallet::get_pending_proposals

vote-community-wallet:
	@echo "Voting on community wallet reauthorization..."
	@read -p "Enter community wallet address: " WALLET; \
	libra txs --chain-id=${CHAIN_ID} community reauthorize --community-wallet $$WALLET

check-vote:
	@echo "Checking your vote on a community wallet..."
	$(eval MY_ADDRESS := $(shell $(call get_address)))
	@read -p "Enter community wallet address: " WALLET; \
	libra query view -f 0x1::community_wallet::get_vote --args ${MY_ADDRESS} $$WALLET

check-proposal-votes:
	@echo "Checking total votes on a community wallet proposal..."
	@read -p "Enter community wallet address: " WALLET; \
	libra query view -f 0x1::community_wallet::get_proposal_votes --args $$WALLET

# Root of Trust
check-root-of-trust:
	@echo "Checking current root of trust..."
	libra query view -f 0x1::root_of_trust::get_current_root

check-rotation-status:
	@echo "Checking root of trust rotation status..."
	libra query view -f 0x1::root_of_trust::get_rotation_status

# Help
help:
	@echo "Twin Testnet V8 Testing Make Commands"
	@echo ""
	@echo "Setup:"
	@echo "  make config                       - Configure CLI for twin testnet"
	@echo "  make config-with-address          - Configure CLI with address and authkey"
	@echo ""
	@echo "Verification:"
	@echo "  make check-epoch                  - Check current epoch"
	@echo "  make check-block-height           - Check block height"
	@echo "  make check-balance                - Check account balance"
	@echo ""
	@echo "FILO Migration:"
	@echo "  make transfer                     - Transfer funds to another account"
	@echo "  make vouch-for                    - Vouch for another account"
	@echo "  make check-remaining-vouches      - Check how many vouches you have left"
	@echo "  make check-vouch-score            - Check an account's vouch score"
	@echo "  make check-founder-status         - Check if an account has founder status"
	@echo "  make check-reauthorization        - Check if an account is reauthorized"
	@echo ""
	@echo "Community Wallet:"
	@echo "  make list-community-wallet-proposals - List pending community wallet proposals"
	@echo "  make vote-community-wallet        - Vote on community wallet reauthorization"
	@echo "  make check-vote                   - Check your vote on a community wallet"
	@echo "  make check-proposal-votes         - Check total votes on a proposal"
	@echo ""
	@echo "Root of Trust:"
	@echo "  make check-root-of-trust          - Check current root of trust"
	@echo "  make check-rotation-status        - Check root of trust rotation status"
	@echo ""
	@echo "Help:"
	@echo "  make help                         - Show this help message"
