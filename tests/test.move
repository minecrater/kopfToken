module 0x200e2ea1904de5eed8e653399905fb9b657c8218e3198257d29138883eb9caca::KopfTokenTest {
    //use aptos_framework::signer;
    use 0x200e2ea1904de5eed8e653399905fb9b657c8218e3198257d29138883eb9caca::KopfToken;
    use std::account;
    use std::vector;
    use std::signer;

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
        assert!(KopfToken::get_balance(recipient_addr) == 10, 0);
        assert!(KopfToken::get_total_supply(&admin) == 10, 0);
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
    fun test_burn() {
        let admin = account::create_account_for_test(@0x1);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::mint(&admin, &admin, 10);
        KopfToken::burn(&admin, 5);

        let admin_addr: address = signer::address_of(&admin);
        assert!(KopfToken::get_balance(admin_addr) == 5, 0);
        assert!(KopfToken::get_total_supply(&admin) == 5, 0);
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
        let sender = account::create_account_for_test(@0x1);
        let recipient = account::create_account_for_test(@0x2);
        KopfToken::initialize(&sender, 100, b"MyToken", b"MTK");
        KopfToken::mint(&sender, &sender, 10);
        KopfToken::transfer(&sender, &recipient, 5);

        let sender_addr = signer::address_of(&sender);
        assert!(KopfToken::get_balance(sender_addr) == 5, 0);
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
        KopfToken::initialize(&user, 100, b"MyToken", b"MTK");
        KopfToken::mint(&user, &user, 10);

        let user_addr = signer::address_of(&user);
        assert!(KopfToken::get_balance(user_addr) == 10, 0);
    }

    #[test]
    fun test_get_total_supply() {
        let admin = account::create_account_for_test(@0x1);
        KopfToken::initialize(&admin, 100, b"MyToken", b"MTK");
        KopfToken::mint(&admin, &admin, 10);

        assert!(KopfToken::get_total_supply(&admin) == 10, 0);
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
}