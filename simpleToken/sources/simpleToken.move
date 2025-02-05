module admin::simpleToken {
    
    use aptos_framework::coin;
    use std::signer;
    use std::string;

    struct USDT{}

    struct CoinCapabilities<phantom USDT> has key {
        mint_capability: coin::MintCapability<USDT>,
        burn_capability: coin::BurnCapability<USDT>,
        freeze_capability: coin::FreezeCapability<USDT>,
    }

    const E_NO_ADMIN: u64 = 0;
    const E_NO_CAPABILITIES: u64 = 1;
    const E_HAS_CAPABILITIES: u64 = 2;

    public entry fun init_usdt(account: &signer) {
        let (burn_capability, freeze_capability, mint_capability) = coin::initialize<USDT>(
            account,
            string::utf8(b"USDT"),
            string::utf8(b"USDT"),
            8,
            true,
        );

        assert!(signer::address_of(account) == @admin, E_NO_ADMIN);
        assert!(!exists<CoinCapabilities<USDT>>(@admin), E_HAS_CAPABILITIES);

        move_to<CoinCapabilities<USDT>>(account, CoinCapabilities<USDT>{mint_capability, burn_capability, freeze_capability});
    }

    public entry fun mint<USDT>(account: &signer, user: address, amount: u64) acquires CoinCapabilities {
        let account_address = signer::address_of(account);
        assert!(account_address == @admin, E_NO_ADMIN);
        assert!(exists<CoinCapabilities<USDT>>(account_address), E_NO_CAPABILITIES);
        let mint_capability = &borrow_global<CoinCapabilities<USDT>>(account_address).mint_capability;
        let coins = coin::mint<USDT>(amount, mint_capability);
        coin::deposit(user, coins)
    }

    public entry fun burn<USDT>(coins: coin::Coin<USDT>) acquires CoinCapabilities {
        let burn_capability = &borrow_global<CoinCapabilities<USDT>>(@admin).burn_capability;
        coin::burn<USDT>(coins, burn_capability);
    }
}