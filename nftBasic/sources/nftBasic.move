module mint_nft::nftBasic {
    use std::bcs;
    use std::error;
    use std::signer;
    use std::string::{Self, String};
    use std::vector;

    use aptos_token::token;
    use aptos_token::token::TokenDataId;

    struct ModuleData has key {
        token_data_id: TokenDataId,
    }

    const ENOT_AUTHORIZED: u64 = 1;

    fun init_module(source_account: &signer) {
        let collection_name = string::utf8(b"Collection name");
        let description = string::utf8(b"Description");
        let collection_uri = string::utf8(b"Collection uri");
        let token_name = string::utf8(b"Token name");
        let token_uri = string::utf8(b"Token uri");
        let maximum_supply = 0;

        let mutate_setting = vector<bool>[ false, false, false ];


        token::create_collection(source_account, collection_name, description, collection_uri, maximum_supply, mutate_setting);

        // 민팅될 nft에 대한 tokenData를 만듬
        let token_data_id = token::create_tokendata(
            source_account, // creator
            collection_name, // collection name
            token_name,  // token name
            description,  // description
            u64:MAX,  //  maximum
            token_uri, //uri
            signer::address_of(source_account), // 로열티 수익을 받는 수신자 지갑
            1, // 로열티 수익을 나눌 분모 값
            0, // 로열티 수익을 나눌 분자 값
            token::create_token_mutability_config( // 토큰 발행 및 소유권 이전드의 토큰의 변화를 제어 설정값
                &vector<bool>[ false, false, false, false, true ]
            //                 맥시멈, uri, 로열티, desctioption, properties
            //                  이 5가지 항목을 수정가능하게 설정할 지에 대한 옵션
            ),
            vector<String>[string::utf8(b"given_to")], // 컬렉션 부가 정보(메타데이터)의 키 값
            vector<vector<u8>>[b""], // 부가 정보(메타데이터)의 값
            vector<String>[ string::utf8(b"address") ], // 부가정보의 데이터 타입
        );

        move_to(source_account, ModuleData {
            token_data_id,
        });
    }

  
    public entry fun delayed_mint_event_ticket(module_owner: &signer, receiver: address) acquires ModuleData {
        assert!(signer::address_of(module_owner) == @mint_nft, error::permission_denied(ENOT_AUTHORIZED));
        // 실행자가 creator인지 확인


        let module_data = borrow_global_mut<ModuleData>(@mint_nft);
        token::mint_token_to(module_owner,receiver, module_data.token_data_id, 1); // token을 새로 발행하여 receiver에게 바로 전송
       
        let (creator_address, collection, name) = token::get_token_data_id_fields(&module_data.token_data_id);

        token::mutate_token_properties(
            module_owner, // 호출자
            receiver, // 토큰의 소유자
            creator_address, // 토큰 주소
            collection, // 컬렉션 이름
            name, // nft 이름
            0, // 토큰의 속성 -> 메타데이터가 수정될 떄마다 증가 됨
            1, // 변경할 토큰의 수
            vector<String>[string::utf8(b"given_to")], // 변경할 속성의 키 값
            vector<vector<u8>>[bcs::to_bytes(&receiver)], // 속성 값
            vector<String>[ string::utf8(b"address") ], // 유형
        );

        // 앞서 init 함수에서 create_tokendata에서 부가 정보의 값만 receiver로 바꿔주는 코드
    }
}