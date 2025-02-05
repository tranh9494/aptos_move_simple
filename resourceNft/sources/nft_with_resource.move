module admin::create_nft_with_resource_account {

    // ## nftBasic.move와 유사하지만 해당 Contract는 resourceCap을 추가적으로 활용
    // 함수에 대한 설명은 nftBasic.move를 참고
    
    use std::string;
    use std::vector;

    use aptos_token::token;
    use std::signer;
    use std::string::String;
    use aptos_token::token::TokenDataId;
    use aptos_framework::account::SignerCapability;
    use aptos_framework::resource_account;
    use aptos_framework::account;
    use aptos_framework::timestamp; 

    struct ModuleData has key {
        signer_cap: SignerCapability,
        token_data_id: TokenDataId,
        expiration_timestamp: u64,
        minting_enabled: bool,
    }

    const ENOT_AUTHORIZED: u64 = 1;
    const ECOLLECTION_EXPIRED: u64 = 2;
    const EMINTING_DISABLED: u64 = 3;
    
    fun init_module(resource_signer: &signer) {
        let collection_name = string::utf8(b"Collection name");
        let description = string::utf8(b"Description");
        let collection_uri = string::utf8(b"Collection uri");
        let token_name = string::utf8(b"Token name");
        let token_uri = string::utf8(b"Token uri");
        let maximum_supply = 0;

        let mutate_setting = vector<bool>[ false, false, false ];

        token::create_collection(resource_signer, collection_name, description, collection_uri, maximum_supply, mutate_setting);

        let token_data_id = token::create_tokendata(
            resource_signer,
            collection_name,
            token_name,
            description,
            0,
            token_uri,
            signer::address_of(resource_signer),
            1,
            0,
            token::create_token_mutability_config(
                &vector<bool>[ false, false, false, false, true ]
            ),
            vector<String>[string::utf8(b"given_to")],
            vector<vector<u8>>[b""],
            vector<String>[ string::utf8(b"address") ],
        );

        // create_resource_account과는 완전히 반대되는 행위를 하는 함수
        // retrieve_resource_account_cap은 저장된 주소에 대한 서명 기능을 반환
        // 첫번쨰 ^signer가 가지고 있는 권한을 이용하여, 두번쨰 인자에 있는 컨테이너 중 signer를 검색하고
        // 계정을 반환

        // Solidity를 예로 들어보자면 특정 Contract는 어떤 함수는 A라는 Token이 있는 사용자만 실행 가능하다.
        // 이러한 상황을 검증하는 함수가 retrieve_resource_account_cap
        let resource_signer_cap = resource_account::retrieve_resource_account_cap(resource_signer, @source_addr);

        move_to(resource_signer, ModuleData {
            signer_cap: resource_signer_cap,
            token_data_id,
            minting_enabled: false,
            expiration_timestamp: 10000000000,
        });
    }

    public entry fun mint_event_ticket(receiver: &signer) acquires ModuleData {
        let module_data = borrow_global_mut<ModuleData>(@admin);

        assert!(timestamp::now_seconds() < module_data.expiration_timestamp, error::permission_denied(ECOLLECTION_EXPIRED));
        assert!(module_data.minting_enabled, error::permission_denied(EMINTING_DISABLED));

        let resource_signer = account::create_signer_with_capability(&module_data.signer_cap);
        let token_id = token::mint_token(&resource_signer, module_data.token_data_id, 1);
        token::direct_transfer(&resource_signer, receiver, token_id, 1);

        let (creator_address, collection, name) = token::get_token_data_id_fields(&module_data.token_data_id);

        token::mutate_token_properties(
            &resource_signer,
            signer::address_of(receiver),
            creator_address,
            collection,
            name,
            0,
            1,
            vector<String>[string::utf8(b"given_to")],
            vector<vector<u8>>[bcs::to_bytes(&receiver)],
            vector<String>[ string::utf8(b"address") ],
        );
    }
  
    public entry fun set_minting_enabled(caller: &signer, minting_enabled: bool) acquires ModuleData {
        let caller_address = signer::address_of(caller);
        assert!(caller_address == @admin, error::permission_denied(ENOT_AUTHORIZED));
        let module_data = borrow_global_mut<ModuleData>(@admin);
        module_data.minting_enabled = minting_enabled;
    }

    public entry fun set_timestamp(caller: &signer, expiration_timestamp: u64) acquires ModuleData {
        let caller_address = signer::address_of(caller);
        assert!(caller_address == @admin, error::permission_denied(ENOT_AUTHORIZED));
        let module_data = borrow_global_mut<ModuleData>(@admin);
        module_data.expiration_timestamp = expiration_timestamp;
    }
}