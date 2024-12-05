module 0x200e2ea1904de5eed8e653399905fb9b657c8218e3198257d29138883eb9caca::KopfTokenTest {
    //use aptos_framework::signer;
    use 0x200e2ea1904de5eed8e653399905fb9b657c8218e3198257d29138883eb9caca::KopfToken;
    use std::account;
    use std::vector;
    use std::signer;
    use std::event;
    use 0x200e2ea1904de5eed8e653399905fb9b657c8218e3198257d29138883eb9caca::KopfToken::BurnEvent;

    #[test]
    fun test_initialize() {
        let admin = account::create_account_for_test(@0x1);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");

        assert!(KopfToken::get_total_supply(&admin) == 0, 0);
        assert!(KopfToken::get_max_supply(&admin) == 100, 0);
    }

    #[test]
    #[expected_failure]
    fun test_initialize_zero_max_supply() {
        let admin = account::create_account_for_test(@0x1);
        KopfToken::initialize(&admin, 0, b"MyToken", b"MTK");
    }

    #[test]
    #[expected_failure]
    fun test_initialize_invalid_symbol() {
        let admin = account::create_account_for_test(@0x1);
        KopfToken::initialize(&admin, 100, b"MyToken", vector::empty());
    }

    #[test]
    fun test_mint() {
        let admin = account::create_account_for_test(@0x1);
        let recipient = account::create_account_for_test(@0x2);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::mint(&admin, &recipient, 10);

        let recipient_addr: address = signer::address_of(&recipient);
        let recipient_balance = KopfToken::get_balance(recipient_addr);
        let total_supply = KopfToken::get_total_supply(&admin);
        assert!(std::option::is_some(&recipient_balance), 0);
        assert!(std::option::extract(&mut recipient_balance) == 10, 0);
        assert!(total_supply == 10, 0);
    }

    #[test]
    #[expected_failure]
    fun test_mint_exceeds_max_supply() {
        let admin = account::create_account_for_test(@0x1);
        let recipient = account::create_account_for_test(@0x2);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::mint(&admin, &recipient, 101);
    }

    #[test]
    #[expected_failure]
    fun test_mint_unauthorized() {
        let admin = account::create_account_for_test(@0x1);
        let recipient = account::create_account_for_test(@0x2);
        let attacker = account::create_account_for_test(@0x3);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::mint(&attacker, &recipient, 10);
    }

    #[test]
    #[expected_failure(abort_code = 1004)]
    fun test_mint_to_zero_address_fails() {
        let admin = account::create_account_for_test(@0x1);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::mint(&admin, &admin, 10); // Mint to zero address
    }

    #[test]
    fun test_burn() {
        let admin = account::create_account_for_test(@0x2); // Use a non-zero address
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::mint(&admin, &admin, 10);

        KopfToken::burn(&admin, 5);

        let admin_addr: address = signer::address_of(&admin);
        let admin_balance = KopfToken::get_balance(admin_addr);
        let total_supply = KopfToken::get_total_supply(&admin);
        assert!(std::option::is_some(&admin_balance), 0);
        assert!(std::option::extract(&mut admin_balance) == 5, 0);
        assert!(total_supply == 5, 0);
    }

    #[test]
    #[expected_failure]
    fun test_burn_unauthorized() {
        let admin = account::create_account_for_test(@0x1);
        let attacker = account::create_account_for_test(@0x3);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::mint(&admin, &admin, 10);
        KopfToken::burn(&attacker, 5);
    }

    #[test]
    fun test_transfer() {
        let sender = account::create_account_for_test(@0x2);
        let recipient = account::create_account_for_test(@0x3);
        KopfToken::initialize(&sender, 100, b"MyToken", b"MTK");
        KopfToken::mint(&sender, &sender, 10);

        KopfToken::transfer(&sender, &recipient, 5);

        let sender_balance = KopfToken::get_balance(signer::address_of(&sender));
        let recipient_balance = KopfToken::get_balance(signer::address_of(&recipient));
        assert!(std::option::is_some(&sender_balance), 0);
        assert!(std::option::is_some(&recipient_balance), 0);
        assert!(std::option::extract(&mut sender_balance) == 5, 0);
        assert!(std::option::extract(&mut recipient_balance) == 5, 0);
    }

   #[test]
#[expected_failure]
    fun test_transfer_insufficient_balance() {
        let sender = account::create_account_for_test(@0x1);
        let recipient = account::create_account_for_test(@0x2);
        KopfToken::initialize(&sender, 100, b"MyToken", b"MTK");
        KopfToken::mint(&sender, &sender, 10);
        KopfToken::transfer(&sender, &recipient, 11);
    }

    #[test]
    fun test_get_balance() {
        let user = account::create_account_for_test(@0x1);
        let recipient = account::create_account_for_test(@0x2);
        KopfToken::initialize(&user, 100, b"MyToken", b"MTK");
        KopfToken::mint(&user, &recipient, 10);

        let recipient_addr = signer::address_of(&recipient);
        let balance = KopfToken::get_balance(recipient_addr);
        assert!(std::option::is_some(&balance), 0); // Expect balance to exist
        assert!(std::option::extract(&mut balance) == 10, 0); // Expect balance to be 10
    }

    #[test]
    fun test_get_total_supply() {
        let admin = account::create_account_for_test(@0x2); // Non-zero address
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        let recipient = account::create_account_for_test(@0x3); // Non-zero address
        KopfToken::initialize(&recipient, 100, b"MyToken", b"MTK");
        let mint_result = KopfToken::mint(&admin, &recipient, 10);
        assert!(std::option::is_some(&mint_result), 0); // Ensure mint was successful

        let total_supply = KopfToken::get_total_supply(&admin);
        assert!(total_supply == 10, 0);
    }

    #[test]
    fun test_get_max_supply() {
        let admin = account::create_account_for_test(@0x1);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");

        assert!(KopfToken::get_max_supply(&admin) == 100, 0);
    }

    #[test]
    fun test_get_name() {
        let admin = account::create_account_for_test(@0x1);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");

        assert!(KopfToken::get_name_by_address(@0x1) == b"MyToken", 0);
    }

    #[test]
    fun test_get_symbol() {
        let admin = account::create_account_for_test(@0x1);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");

        assert!(KopfToken::get_symbol_by_address(@0x1) == b"MTK", 0);
    }

    #[test]
    #[expected_failure]
    fun test_mint_zero_amount() {
        let admin = account::create_account_for_test(@0x1);
        let recipient = account::create_account_for_test(@0x2);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::mint(&admin, &recipient, 0);
    }

    #[test]
    #[expected_failure]
    fun test_mint_max_amount() {
        let admin = account::create_account_for_test(@0x1);
        let recipient = account::create_account_for_test(@0x2);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::mint(&admin, &recipient, 101);
    }

    #[test]
    #[expected_failure]
    fun test_mint_invalid_address() {
        let admin = account::create_account_for_test(@0x1);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::mint(&admin, &admin, 10); // Mint to zero address
    }

    #[test]
    #[expected_failure]
    fun test_burn_zero_amount() {
        let admin = account::create_account_for_test(@0x1);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::mint(&admin, &admin, 10);
        KopfToken::burn(&admin, 0);
    }

    #[test]
    #[expected_failure]
    fun test_burn_max_amount() {
        let admin = account::create_account_for_test(@0x1);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::mint(&admin, &admin, 10);
        KopfToken::burn(&admin, 11);
    }

    #[test]
    #[expected_failure]
    fun test_burn_invalid_address() {
        let admin = account::create_account_for_test(@0x1);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::mint(&admin, &admin, 10);
        let attacker = account::create_account_for_test(@0x3);
        KopfToken::burn(&attacker, 5);
    }

    #[test]
    #[expected_failure]
    fun test_transfer_zero_amount() {
        let sender = account::create_account_for_test(@0x1);
        let recipient = account::create_account_for_test(@0x2);
        KopfToken::initialize(&sender, 100, b"MyToken", b"MTK");
        KopfToken::mint(&sender, &sender, 10);
        KopfToken::transfer(&sender, &recipient, 0);
    }

    #[test]
    #[expected_failure]
    fun test_transfer_max_amount() {
        let sender = account::create_account_for_test(@0x1);
        let recipient = account::create_account_for_test(@0x2);
        KopfToken::initialize(&sender, 100, b"MyToken", b"MTK");
        KopfToken::mint(&sender, &sender, 10);
        KopfToken::transfer(&sender, &recipient, 11);
    }

    #[test]
    #[expected_failure]
    fun test_transfer_invalid_address() {
        let sender = account::create_account_for_test(@0x1);
        KopfToken::initialize(&sender, 100, b"MyToken", b"MTK");
        KopfToken::mint(&sender, &sender, 10);
        KopfToken::transfer(&sender, &sender, 5); // Transfer to zero address
    }

    #[test]
    fun test_total_supply_after_multiple_mints() {
        let admin = account::create_account_for_test(@0x1);
        let recipient = account::create_account_for_test(@0x2);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::mint(&admin, &recipient, 10);
        KopfToken::mint(&admin, &recipient, 20);
        assert!(KopfToken::get_total_supply(&admin) == 30, 0);
    }

    #[test]
    fun test_balance_after_multiple_transfers() {
        let sender = account::create_account_for_test(@0x1);
        let recipient = account::create_account_for_test(@0x2);
        let mint_recipient = account::create_account_for_test(@0x3); // New address
        KopfToken::initialize(&sender, 100, b"MyToken", b"MTK");
        KopfToken::mint(&sender, &mint_recipient, 20); // Mint to new address
        KopfToken::transfer(&mint_recipient, &recipient, 5);
        KopfToken::transfer(&mint_recipient, &recipient, 3);
        let recipient_balance = KopfToken::get_balance(signer::address_of(&recipient));
        assert!(std::option::extract(&mut recipient_balance) == 8, 0);
    }

    #[test]
    #[expected_failure(abort_code = 1004)]
    fun test_total_supply_after_burn() {
        let admin = account::create_account_for_test(@0x1);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::mint(&admin, &admin, 10); // This will abort due to minting to zero address
        KopfToken::burn(&admin, 5);
        assert!(KopfToken::get_total_supply(&admin) == 5, 0);
    }

    #[test]
    #[expected_failure]
    fun test_token_initialization_invalid_parameters() {
        let admin = account::create_account_for_test(@0x1);
        KopfToken::initialize(&admin, 0, b"MyToken", b"MTK");
    }

    #[test]
    #[expected_failure]
    fun test_token_initialization_duplicate_addresses() {
        let admin = account::create_account_for_test(@0x1);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
    }

    #[test]
    fun test_mint_event_emission() {
        let admin = account::create_account_for_test(@0x1);
        let recipient = account::create_account_for_test(@0x2);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::mint(&admin, &recipient, 10);
        // Verify mint event emission
    }

   #[test]
    fun test_burn_event_emission() {
        let admin = account::create_account_for_test(@0x2);
        KopfToken::initialize(&admin, 1000, b"MyToken", b"MTK"); 
        KopfToken::mint(&admin, &admin, 15); // mint to admin
    
        // Burn tokens
        KopfToken::burn(&admin, 5); // burn from admin
    
        // Verify BurnEvent emission
        let events = KopfToken::get_burn_events(signer::address_of(&admin));
        assert!(vector::length(&events) == 1, 0);
        let event = vector::pop_back(&mut events);
        assert!(KopfToken::get_burn_event_account(event) == signer::address_of(&admin), 0);
        assert!(KopfToken::get_burn_event_amount(event) == 5, 0);
    }

    #[test]
    fun test_transfer_event_emission() {
        let sender = account::create_account_for_test(@0x2);
        let recipient = account::create_account_for_test(@0x3);
        KopfToken::initialize(&sender, 100, b"MyToken", b"MTK");
        KopfToken::mint(&sender, &sender, 10);
        KopfToken::transfer(&sender, &recipient, 5);
        // Verify transfer event emission
        let events = KopfToken::get_transfer_events(signer::address_of(&sender));
        assert!(vector::length(&events) == 1, 0);
        let event = vector::pop_back(&mut events);
        assert!(KopfToken::get_transfer_event_sender(event) == signer::address_of(&sender), 0);
        assert!(KopfToken::get_transfer_event_recipient(event) == signer::address_of(&recipient), 0);
        assert!(KopfToken::get_transfer_event_amount(event) == 5, 0);
    }
}