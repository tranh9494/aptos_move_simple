module myAddress::myCustomNFT {
    use std::string::{Self, String};
    use std::signer;    
    use std::vector;
    use std::hash;
    use std::bcs;
    use aptos_std::from_bcs;

    use aptos_token::token::{Self};
    use aptos_token::token::TokenDataId;

    use aptos_framework::account;
    use aptos_framework::resource_account;
    use aptos_framework::timestamp;
    use aptos_framework::transaction_context;
    use aptos_framework::event::{Self, EventHandle};

    struct HeroNft has key {
        name : String,
        description : String,
        baseUri : String,
        total_supply : u64,
        minted : u64,
        power : u64,
        owner : address,
        resource_cap : account::SignerCapability,
    }

    struct Monster has key ,drop {
        hp : u64,
        strength : u64,
    }

    struct EventStore has key {
        kill_event: EventHandle<HuntSuccessEvent>,
    }


    struct HuntSuccessEvent has drop, store {
        killer : address
    }

    const E_NO_ADMIN: u64 = 0;
    const E_NOT_OWNER : u64 = 0;
    const E_HAS_CAPABILITIES: u64 = 2;
    const E_MINT_SUPPLY_REACHED : u64 = 4;

    fun init_module(owner_account : &signer) {
        let token_name = string::utf8(b"Hero NFT");
        let token_description = string::utf8(b"Battle Monster Using Your NFT");
        let base_uri = string::utf8(b"https://gateway.pinata.cloud/ipfs/QmcVxumHiLwCr9hD6VyhpRuMM17BndsE5ab6nTipMD84qG");
        let total_supply  = 1000;   

        let owner_address = signer::address_of(owner_account);

        assert!(owner_address == @myAddress, E_NO_ADMIN);
        assert!(!exists<HeroNft>(@myAddress), E_HAS_CAPABILITIES);

        let mutate_setting = vector<bool>[ false, false, false ];
        let collection_name = string::utf8(b"Hero NFT Collection");
        let collection_description  = string::utf8(b"Hero NFT Collection Description");
        let collection_uri = string::utf8(b"https://gateway.pinata.cloud/ipfs/QmcVxumHiLwCr9hD6VyhpRuMM17BndsE5ab6nTipMD84qG");

        token::create_collection(owner_account, collection_name, collection_description, collection_uri, total_supply, mutate_setting);

        // let resource_signer_cap = resource_account::retrieve_resource_account_cap(owner_account, owner_address);
        let (_resource, resource_signer_cap) = account::create_resource_account(owner_account, vector::empty<u8>());

        // let token_data_id = token::create_tokendata(
        //     owner_account, 
        //     collection_name,
        //     token_name, 
        //     token_description,  
        //     0, 
        //     base_uri,
        //     owner_address, 
        //     1, 
        //     0,
        //     token::create_token_mutability_config( 
        //         &vector<bool>[ false, false, false, false, true ]
        //     ),
        //     vector<String>[string::utf8(b"given_to")], 
        //     vector<vector<u8>>[b""], 
        //     vector<String>[ string::utf8(b"address") ], 
        // );

        move_to<HeroNft>(
            owner_account,
            HeroNft{
                name : token_name,
                description : token_description,
                baseUri : base_uri,
                total_supply,
                minted:  1,
                owner : owner_address,
                power: 0,
                resource_cap : resource_signer_cap
        });

        move_to<EventStore>(
            owner_account, EventStore{
                kill_event : account::new_event_handle<HuntSuccessEvent>(owner_account),
            }
        )
    }

    public entry fun mint_nft(
        sender : &signer
    ) acquires HeroNft {
        let receiver_address =  signer::address_of(sender); 
        let nft_data = borrow_global_mut<HeroNft>(@myAddress);
 
        assert!(nft_data.minted != nft_data.total_supply,  E_MINT_SUPPLY_REACHED);

        let minted_amount = nft_data.minted;
        let token_name = nft_data.name;

        string::append(&mut token_name, string::utf8(b" #"));
        string::append(&mut token_name, num_str(minted_amount));

        let baseUri = nft_data.baseUri;
        string::append(&mut baseUri, num_str(minted_amount));
        string::append(&mut baseUri, string::utf8(b".json"));

        let resource_signer_from_cap = account::create_signer_with_capability(&nft_data.resource_cap);
        // signer

        let (_resource, resource_signer_cap) = account::create_resource_account(sender, vector::empty<u8>());
        assert(signer::address_of(&resource_signer_from_cap) == @myAddress, E_NO_ADMIN);

        token::create_token_script(
            &resource_signer_from_cap,
            nft_data.name,
            token_name,
            nft_data.description,
            1,          
            0,
            baseUri,
            nft_data.owner, 
            100,        
            5,         
            vector<bool>[false, false, false, false, true],
            vector::empty<String>(),
            vector<vector<u8>>[],
            vector::empty<String>()
        );


        let token_data_id = token::create_token_data_id(signer::address_of(&resource_signer_from_cap), nft_data.name, token_name );
        token::mint_token_to(&resource_signer_from_cap, receiver_address, token_data_id, 1);
        token::opt_in_direct_transfer(sender, true);

        nft_data.minted = nft_data.minted+1;

        move_to<HeroNft>(
            sender,
            HeroNft{
                name : token_name,
                description : nft_data.description,
                baseUri : baseUri,
                total_supply : nft_data.total_supply,
                minted:  nft_data.minted,
                owner : receiver_address,
                power: random_number(receiver_address, 1, 5),
                resource_cap : resource_signer_cap
        });
    }

    public entry fun hunt_monster(
        sender :  &signer,
    ) : bool acquires HeroNft, Monster, EventStore {
        let sender_address = signer::address_of(sender);

        let nft_data = borrow_global_mut<HeroNft>(sender_address);
        let monster_data = borrow_global_mut<Monster>(@myAddress);
        let resource_signer_from_cap = account::create_signer_with_capability(&nft_data.resource_cap);

        assert(signer::address_of(&resource_signer_from_cap) == sender_address, E_NOT_OWNER);

        let hero_power = nft_data.power;
        let monster_hp = monster_data.hp;
        let monster_strength = monster_data.strength;

        let random_attack_number = random_number(sender_address, 0, 3);
        let random_heal_number = random_number(@myAddress, 0, 2);

        let attack_power = hero_power * random_attack_number;
        let heal_amount = monster_strength * random_heal_number;

        if(attack_power > monster_hp) {
            let event_store = borrow_global_mut<EventStore>(sender_address);
            let kill_event = HuntSuccessEvent {
                killer : sender_address,
            };
            event::emit_event<HuntSuccessEvent>(
                &mut event_store.kill_event,
                kill_event
            );
            let my_resource: Monster = move_from<Monster>(@myAddress);
            return true;
        };

        monster_data.hp = monster_hp - attack_power;
        monster_data.hp = monster_hp + heal_amount;
        false
    }

    public entry fun create_monster_by_owner ( 
        sender : &signer
    ) {
        // exists로 검증 필요
        assert(signer::address_of(sender) == @myAddress, E_NO_ADMIN);

        move_to<Monster>(
            sender,
            Monster{
                hp : random_number(signer::address_of(sender), 1, 100),
                strength : 5
        });
    }

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

    fun random_number(add:address,number1:u64,max:u64):u64
    {
        let x = bcs::to_bytes<address>(&add);
        let y = bcs::to_bytes<u64>(&number1);
        let z = bcs::to_bytes<u64>(&timestamp::now_seconds());
        vector::append(&mut x,y);
        vector::append(&mut x,z);
        let script_hash: vector<u8> = transaction_context::get_script_hash();
        vector::append(&mut x,script_hash);
        let tmp = hash::sha2_256(x);

        let data = vector<u8>[];
        let i =24;
        while (i < 32)
        {
            let x =vector::borrow(&tmp,i);
            vector::append(&mut data,vector<u8>[*x]);
            i= i+1;
        };
        assert!(max>0,999);

        let random = from_bcs::to_u64(data) % max;
        random

    }
}