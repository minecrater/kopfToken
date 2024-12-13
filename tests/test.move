module 0x200e2ea1904de5eed8e653399905fb9b657c8218e3198257d29138883eb9caca::KopfTokenTest {
    //use aptos_framework::signer;
    use 0x200e2ea1904de5eed8e653399905fb9b657c8218e3198257d29138883eb9caca::KopfToken;
    use std::account;
    use std::vector;
    use std::signer;
    //use std::event;
    //use std::option;
    //use 0x200e2ea1904de5eed8e653399905fb9b657c8218e3198257d29138883eb9caca::KopfToken::BurnEvent;

    #[test]
    fun test_initialize() {
        let admin = account::create_account_for_test(@0x1);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");

        assert!(KopfToken::get_total_supply(signer::address_of(&admin)) == 0, 0);
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
        let admin = account::create_account_for_test(@0x4);
        let recipient = account::create_account_for_test(@0x2);
        KopfToken::initialize(&recipient, 100, b"MyToken", b"KOPF");
        KopfToken::initialize(&admin, 100, b"MyToken", b"KOPF");
        KopfToken::mint(&admin, signer::address_of(&recipient), 10);
        let recipient_addr: address = signer::address_of(&recipient);
        let recipient_balance = KopfToken::get_balance(recipient_addr);
        assert!(std::option::is_some(&recipient_balance), 0);
        let balance = std::option::extract(&mut recipient_balance);
        assert!(balance == 10, 0);
    }


    #[test]
    #[expected_failure]
    fun test_mint_exceeds_max_supply() {
        let admin = account::create_account_for_test(@0x1);
        let recipient = account::create_account_for_test(@0x2);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::mint(&admin, signer::address_of(&recipient), 101);
    }

    #[test]
    #[expected_failure]
    fun test_mint_unauthorized() {
        let admin = account::create_account_for_test(@0x1);
        let recipient = account::create_account_for_test(@0x2);
        let attacker = account::create_account_for_test(@0x3);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::mint(&attacker, signer::address_of(&recipient), 10);

    }

    #[test]
    #[expected_failure(abort_code = 1004)]
    fun test_mint_to_zero_address_fails() {
        let admin = account::create_account_for_test(@0x1);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::mint(&admin, @0x0, 10); // Mint to zero address
    }

    #[test]
    fun test_burn() {
        let admin = account::create_account_for_test(@0x2); 
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");

        let admin_clone = account::create_account_for_test(@0x2); // Clone the admin account
        KopfToken::mint(&admin_clone, signer::address_of(&admin), 5); 

        let admin_addr = signer::address_of(&admin);
        let token_opt = KopfToken::get_balance(admin_addr);
        assert!(std::option::is_some(&token_opt), 0);
        let initial_balance = std::option::extract(&mut token_opt);
        assert!(initial_balance == 5, 5);

        KopfToken::burn(&admin, 5);
    }



    #[test]
    #[expected_failure]
    fun test_burn_unauthorized() {
        let admin = account::create_account_for_test(@0x1);
        let attacker = account::create_account_for_test(@0x3);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::mint(&admin, signer::address_of(&admin), 10);
        KopfToken::burn(&attacker, 5);
    }

    #[test]
    fun test_transfer() {
        // Create accounts for sender and recipient
        let sender = account::create_account_for_test(@0x2);
        let recipient = account::create_account_for_test(@0x3);

        // Initialize the token contract with the sender as the signer
        KopfToken::initialize(&sender, 100, b"MyToken", b"MTK");

        // Create a new signer for mint operation (to avoid moving the original sender)
        let mint_sender = account::create_account_for_test(@0x4); // New signer for minting
        KopfToken::initialize(&mint_sender, 100, b"MyToken", b"MTK"); // Initialize mint_sender's KopfToken resource

        // Mint tokens to the sender (this consumes mint_sender)
        KopfToken::mint(&mint_sender, signer::address_of(&sender), 10);

        // To transfer tokens, we need a different signer, so let's create a new account for transfer
        let transfer_sender = account::create_account_for_test(@0x2); // New signer for the transfer

        // Transfer tokens from sender to recipient
        KopfToken::transfer(&transfer_sender, &recipient, 5);  // Use a new signer for the transfer

        // Get the address of the original sender (after minting)
        let sender_address = signer::address_of(&sender); // Get the address of the sender
        let sender_balance = KopfToken::get_balance(sender_address); // Check balance using address directly
        let recipient_balance = KopfToken::get_balance(signer::address_of(&recipient)); // Recipient balance

        // Assert that balances are updated correctly
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

        let sender_clone = account::create_account_for_test(@0x1);
        let sender_clone2 = account::create_account_for_test(@0x1);
        KopfToken::mint(&sender_clone, signer::address_of(&sender_clone), 10);
        KopfToken::transfer(&sender_clone2, &recipient, 11);  
    }


    #[test]
    fun test_get_balance() {
        let user = account::create_account_for_test(@0x4);
        let recipient = account::create_account_for_test(@0x2);
        KopfToken::initialize(&user, 100, b"MyToken", b"MTK");
        KopfToken::initialize(&recipient, 100, b"MyToken", b"MTK");
        KopfToken::mint(&user, signer::address_of(&recipient), 10);
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
        KopfToken::initialize(&recipient, 100, b"MyToken", b"MTK"); // Initialize recipient's KopfToken resource

        // Clone the admin account to avoid moving it
        let admin_clone = account::create_account_for_test(@0x2);

        // Mint tokens to the recipient
        KopfToken::mint(&admin, signer::address_of(&recipient), 10);

        // Now, check if the total supply has increased accordingly.
        let total_supply = KopfToken::get_total_supply(signer::address_of(&admin_clone));
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
        KopfToken::mint(&admin, signer::address_of(&recipient), 0);
    }

    #[test]
    #[expected_failure]
    fun test_mint_max_amount() {
        let admin = account::create_account_for_test(@0x1);
        let recipient = account::create_account_for_test(@0x2);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        let max_amount = 101; // Trying to mint more than the max supply
        KopfToken::mint(&recipient, signer::address_of(&admin), max_amount); // Mint 10 tokens from admin to recipient
    }

    #[test]
    #[expected_failure]
    fun test_mint_invalid_address() {
        let admin = account::create_account_for_test(@0x1);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        let zero_address = @0x0; // Define an invalid address
        KopfToken::mint(&admin, zero_address, 10); // Attempt to mint to the zero address
    }

    #[test]
    #[expected_failure]
    fun test_burn_zero_amount() {
        let admin = account::create_account_for_test(@0x1);
        let admin_clone = account::create_account_for_test(@0x1);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::mint(&admin, signer::address_of(&admin), 10);
        KopfToken::burn(&admin_clone, 0);
    }

    #[test]
    #[expected_failure]
    fun test_burn_max_amount() {
        let admin = account::create_account_for_test(@0x1);
        let admin_clone = account::create_account_for_test(@0x1);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::mint(&admin, signer::address_of(&admin), 10);
        KopfToken::burn(&admin_clone, 11);
    }

    #[test]
    #[expected_failure]
    fun test_burn_invalid_address() {
        let admin = account::create_account_for_test(@0x1);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::mint(&admin, signer::address_of(&admin), 10);
        let attacker = account::create_account_for_test(@0x3);
        KopfToken::burn(&attacker, 5);
    }

    #[test]
    #[expected_failure]
    fun test_transfer_zero_amount() {
        let sender = account::create_account_for_test(@0x1);
        let sender_clone = account::create_account_for_test(@0x1);
        let recipient = account::create_account_for_test(@0x2);
        KopfToken::initialize(&sender, 100, b"MyToken", b"MTK");
        KopfToken::mint(&sender, signer::address_of(&sender), 10);
        KopfToken::transfer(&sender_clone, &recipient, 0);
    }

    #[test]
    #[expected_failure]
    fun test_transfer_max_amount() {
        let sender = account::create_account_for_test(@0x1);
        let sender_clone = account::create_account_for_test(@0x1);
        let recipient = account::create_account_for_test(@0x2);
        KopfToken::initialize(&sender, 100, b"MyToken", b"MTK");
        KopfToken::mint(&sender, signer::address_of(&sender), 10);
        KopfToken::transfer(&sender_clone, &recipient, 11);
    }

    #[test]
    #[expected_failure]
    fun test_transfer_invalid_address() {
        let sender = account::create_account_for_test(@0x1);
        let invalid_recipient = account::create_account_for_test(@0x0); // Create an account with address @0x0
        KopfToken::initialize(&sender, 100, b"MyToken", b"MTK");
        KopfToken::mint(&sender, signer::address_of(&sender), 10);
        KopfToken::transfer(&sender, &invalid_recipient, 5);
    }

    #[test]
    fun test_total_supply_after_multiple_mints() {
        let admin = account::create_account_for_test(@0x2);
        let admin_clone = account::create_account_for_test(@0x2);
        let admin_clone2 = account::create_account_for_test(@0x2);
        let recipient = account::create_account_for_test(@0x2);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::mint(&admin, signer::address_of(&recipient), 10);
        KopfToken::mint(&admin_clone, signer::address_of(&recipient), 20);
        assert!(KopfToken::get_total_supply(signer::address_of(&admin_clone2)) == 30, 0);
    }

    #[test]
    fun test_balance_after_multiple_transfers() {
        let admin = account::create_account_for_test(@0x4);
        let recipient = account::create_account_for_test(@0x2);
        let mint_recipient = account::create_account_for_test(@0x4); // New address
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::mint(&mint_recipient, signer::address_of(&admin), 20);
        //assert!(KopfToken::get_balance(signer::address_of(&mint_recipient)) == option::Some(20), 0);
    
        KopfToken::transfer(&mint_recipient, &recipient, 5);
        KopfToken::transfer(&mint_recipient, &recipient, 3);
        let recipient_balance = KopfToken::get_balance(signer::address_of(&recipient));
        //assert!(recipient_balance == option::Some(8), 0);
    }

    #[test]
    fun test_total_supply_after_burn() {
        let admin = account::create_account_for_test(@0x1);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        assert!(KopfToken::get_total_supply(signer::address_of(&admin)) == 0, 0);
        KopfToken::mint(&admin, signer::address_of(&admin), 10);
        assert!(KopfToken::get_total_supply(signer::address_of(&admin)) == 10, 0);
        KopfToken::burn(&admin, 5);
        assert!(KopfToken::get_total_supply(signer::address_of(&admin)) == 5, 0);
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
        let admin = account::create_account_for_test(@0x3);
        let recipient = account::create_account_for_test(@0x2);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::initialize(&recipient, 100, b"MyToken", b"MTK"); // Initialize recipient's KopfToken resource
        let initial_balance = KopfToken::get_balance(signer::address_of(&recipient));
        assert!(std::option::is_some(&initial_balance), 0);
        let initial_balance_val = std::option::extract(&mut initial_balance);
        assert!(initial_balance_val == 0, 0); // Initial balance should be 0
        
        KopfToken::mint(&admin, signer::address_of(&recipient), 10);
        
        // Verify mint event emission
        let events = KopfToken::get_mint_events(signer::address_of(&recipient));
        assert!(vector::length(&events) == 1, 0);
        let mint_event: 0x200e2ea1904de5eed8e653399905fb9b657c8218e3198257d29138883eb9caca::KopfToken::MintEvent = vector::pop_back(&mut events);
        
        // Verify recipient's balance increase
        let updated_balance = KopfToken::get_balance(signer::address_of(&recipient));
        assert!(std::option::is_some(&updated_balance), 0);
        let updated_balance_val = std::option::extract(&mut updated_balance);
        assert!(updated_balance_val == 10, 0); // Balance should increase by 10
    }

   #[test]
    fun test_burn_event_emission() {
        let admin = account::create_account_for_test(@0x2);
        let admin_clone = account::create_account_for_test(@0x2);
        let admin_clone2 = account::create_account_for_test(@0x2);
        let admin_clone3 = account::create_account_for_test(@0x2);
        KopfToken::initialize(&admin, 1000, b"MyToken", b"MTK"); 
        KopfToken::mint(&admin_clone, signer::address_of(&admin), 10); //mint to admin
        // Burn tokens
        KopfToken::burn(&admin_clone2, 5); // burn from admin
    
        // Verify BurnEvent emission
        let events = KopfToken::get_burn_events(signer::address_of(&admin_clone3));
        assert!(vector::length(&events) == 1, 0);
        let event = vector::pop_back(&mut events);
        assert!(KopfToken::get_burn_event_account(event) == signer::address_of(&admin_clone3), 0);
        assert!(KopfToken::get_burn_event_amount(event) == 5, 0);
    }


    #[test]
    fun test_transfer_event_emission() {
        let sender = account::create_account_for_test(@0x2);
        let recipient = account::create_account_for_test(@0x3);
        KopfToken::initialize(&sender, 100, b"MyToken", b"MTK");
        KopfToken::mint(&sender, signer::address_of(&sender), 10); // Mint to sender

        KopfToken::transfer(&sender, &recipient, 5);

        // Verify transfer event emission
        let events = KopfToken::get_transfer_events(signer::address_of(&recipient));
        assert!(vector::length(&events) == 1, 0);
        let event = vector::pop_back(&mut events);
        assert!(KopfToken::get_transfer_event_sender(event) == signer::address_of(&sender), 0);
        assert!(KopfToken::get_transfer_event_recipient(event) == signer::address_of(&recipient), 0);
        assert!(KopfToken::get_transfer_event_amount(event) == 5, 0);
    }

    #[test]
    fun test_initialize_recipient() {
        let recipient = account::create_account_for_test(@0x2);
        KopfToken::initialize_recipient(&recipient);
        // Check if recipient's account is initialized
        let recipient_addr = signer::address_of(&recipient);
        let recipient_balance = KopfToken::get_balance(recipient_addr);
        assert!(std::option::is_some(&recipient_balance), 0);
        let balance = std::option::extract(&mut recipient_balance);
        assert!(balance == 0, 0); // Initial balance should be 0
    }
    
}