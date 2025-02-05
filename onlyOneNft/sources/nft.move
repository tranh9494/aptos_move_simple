module publisher::nftSample {
use std::signer;
    use std::string::{Self, String};
    use std::vector;
    use aptos_framework::account;
    use aptos_token::token::{Self};

    // &signer is not Admin
    const E_NO_ADMIN: u64 = 0;
    // has no capabilities
    const E_HAS_CAPABILITIES: u64 = 2;
    // mint status is paused
    const E_MINT_PAUSED : u64 = 3;
    // mint total is reached
    const E_MINT_SUPPLY_REACHED : u64 = 4;

    struct NftWeb3 has key {
        name : String,
        description: String,
        baseUri: String,
        paused: bool,
        total_supply: u64,
        minted: u64,
        whitelist: vector<address>,
        resource_cap : account::SignerCapability,
        owner : address
    }

    entry fun init_module (owner : &signer) {
        let name  =  string::utf8(b"Sample");
        let description = string::utf8(b"Metaverse Sample");
        let baseUri = string::utf8(b"https://gateway.pinata.cloud/ipfs/QmcVxumHiLwCr9hD6VyhpRuMM17BndsE5ab6nTipMD84qG");
        let total_supply  = 1000;
        let whitelist = vector::empty<address>();
        let owner_address = signer::address_of(owner);

        assert!(owner_address == @publisher, E_NO_ADMIN);
        assert!(!exists<NftWeb3>(@publisher), E_HAS_CAPABILITIES);

        let (_resource, resource_cap) = account::create_resource_account(owner, vector::empty<u8>());
        // one prameter : &signer, two prameter : seed -> vector<u8>
        // create resource account for manage resources 
        // only Can create once
        // return type signer, SignerCapability
        let resource_signer_from_cap  = account::create_signer_with_capability(&resource_cap);
    
        move_to<NftWeb3>(
            owner,
            NftWeb3{
                name,
                description,
                baseUri,
                paused : false,
                total_supply,
                minted:  1,
                whitelist,
                resource_cap,
                owner : owner_address,
        });

        token::create_collection(
            &resource_signer_from_cap ,  // creator
            name,   // tokenName
            description, // description
            baseUri,  // tokenMetaData Uri
            u64:MAX, // maximum
            vector<bool>[false, false, false] // mutate_setting??
        );
    }

    public entry fun create_whiteList (
        account : &signer,
        add_whiteList : vector<address>
    ) acquires NftWeb3 {
        let owner = signer::address_of(account);

        assert!(owner == @publisher, 0);
        assert!(exists<NftWeb3>(@publisher), E_HAS_CAPABILITIES);

        let nft_data = borrow_global_mut<NftWeb3>(owner);

        vector::append(&mut nft_data.whitelist, add_whiteList);
    }

    public entry fun check_publishser( sender  : &signer) : u64 {
        let owner_address = signer::address_of(sender);
        assert!(owner_address == @publisher, E_NO_ADMIN);
        return 3
    }

    public entry fun mint_nft_by_user(
        sender  : &signer
    ) acquires NftWeb3 {

        let receiver_address =  signer::address_of(sender);

        assert!(exists<NftWeb3>(@publisher), E_HAS_CAPABILITIES);
        // @publisher == collection
        let nft_data = borrow_global_mut<NftWeb3>(receiver_address);

        assert!(nft_data.paused == false,  E_MINT_PAUSED);
        assert!(nft_data.minted != nft_data.total_supply,  E_MINT_SUPPLY_REACHED);
        // let now = aptos_framework::timestamp::now_secnods();
        // not using just sample

        let minted_amount = nft_data.minted;
        let token_name = nft_data.name;

        string::append(&mut token_name, string::utf8(b" #"));
        string::append(&mut token_name, num_str(minted_amount));

        let baseUri = nft_data.baseUri;
        string::append(&mut baseUri, num_str(minted_amount));
        string::append(&mut baseUri, string::utf8(b".json"));

        let resource_signer_from_cap = account::create_signer_with_capability(&nft_data.resource_cap);

        // if(vector::contains(&nft_data.whitelist, &receiver_addr)) {
        //     // if whiteListed
            
        // }

        token::create_token_script(
            &resource_signer_from_cap,
            nft_data.name,
            token_name,
            nft_data.description,
            1,          // mint Amount
            0,
            baseUri,
            nft_data.owner, // original royalty_payee_addr
            100,        // royalty points_denominator
            5,          // royalty_points_numerator
            vector<bool>[false, false, false, false, true],
            vector::empty<String>(),
            vector<vector<u8>>[],
            vector::empty<String>()
        );
        // create NFT Token
        let token_data_id = token::create_token_data_id(signer::address_of(&resource_signer_from_cap), nft_data.name, token_name );
        // first : address = tokenOwner 

        // second : string = collection -> NFT's Collection Name 
        // -> Example = ZEP NFT Collection

        // third : string = tokenName
        // -> Example = ZEP #1
        // -> Example = ZEP #2

        token::opt_in_direct_transfer(sender, true);

        // create tokens and directly deposite to receiver's address. The receiver should opt-in direct transfer
        token::mint_token_to(&resource_signer_from_cap, receiver_address, token_data_id, 1);

        nft_data.minted = nft_data.minted+1;
    }


    public entry fun mint_nft_to_Owner(
        account  : &signer
    ) acquires NftWeb3 {
        assert!(exists<NftWeb3>(@publisher), E_HAS_CAPABILITIES);
        let nft_data = borrow_global_mut<NftWeb3>(@publisher);

        assert!(nft_data.paused == false,  E_MINT_PAUSED);
        assert!(nft_data.minted != nft_data.total_supply,  E_MINT_SUPPLY_REACHED);

        let resource_signer_from_cap = account::create_signer_with_capability(&nft_data.resource_cap);

        let minted_amount = nft_data.minted;

        let token_name = nft_data.name;
        string::append(&mut token_name, string::utf8(b" #"));
        string::append(&mut token_name, num_str(minted_amount));

        let baseUri = nft_data.baseUri;
        string::append(&mut baseUri, num_str(minted_amount));
        string::append(&mut baseUri, string::utf8(b".json"));

        token::create_token_script(
            &resource_signer_from_cap,
            nft_data.name,
            token_name,
            nft_data.description,
            1,
            0,
            baseUri,
            signer::address_of(account), // original royalty_payee_addr
            100,
            5,
            vector<bool>[false, false, false, false, true],
            vector::empty<String>(),
            vector<vector<u8>>[],
            vector::empty<String>()
        );

        let token_data_id = token::create_token_data_id(signer::address_of(&resource_signer_from_cap), nft_data.name, token_name );
        // collectionName, name, token_name

        token::opt_in_direct_transfer(account, true);

        token::mint_token_to(&resource_signer_from_cap, signer::address_of(account), token_data_id, 1);

        nft_data.minted = nft_data.minted+1;
    }

    // coin::transfer<0x1::aptos_coin::AptosCoin>(receiver, resource_data.source, mint_price);
    //     token::mint_token_to(&resource_signer_from_cap,receiver_addr,token_data_id,1);

    fun num_str(num: u64): String{
        let v1 = vector::empty();
        while (num/10 > 0){
            let rem = num%10;
            vector::push_back(&mut v1, (rem+48 as u8));
            num = num/10;
        };
        vector::push_back(&mut v1, (num+48 as u8));
        vector::reverse(&mut v1);
        string::utf8(v1)
    }
}