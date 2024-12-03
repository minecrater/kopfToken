module 0x200e2ea1904de5eed8e653399905fb9b657c8218e3198257d29138883eb9caca::KopfToken {
    use std::signer;
    use std::vector;
    use std::event;
    use std::account;

    struct KopfToken has key, store, drop {
        id: u64,
        value: u64,
        max_supply: u64,
        total_supply: u64,
        token_name: vector<u8>,
        token_symbol: vector<u8>,
    }

    // Define token events
    #[event]
    struct MintEvent has store, drop {
        recipient: address,
        amount: u64,
    }

    #[event]
    struct BurnEvent has store, drop {
        account: address,
        amount: u64,
    }

    #[event]
    struct TransferEvent has store, drop {
        sender: address,
        recipient: address,
        amount: u64,
    }

    // Initialize token supply
    public fun initialize(account: &signer, max_supply: u64, token_name: vector<u8>, token_symbol: vector<u8>) {
        assert!(max_supply > 0, 1); // Max supply cannot be zero
        assert!(vector::length(&token_symbol) > 0, 1); // Token symbol cannot be empty
        move_to(account, KopfToken { 
            id: 0, 
            value: 0,
            max_supply,
            total_supply: 0,
            token_name, 
            token_symbol 
        });
    }

  // Mint tokens
    public fun mint(_account: &signer, recipient: &signer, amount: u64) acquires KopfToken {
        let recipient_address = signer::address_of(recipient);

    // Initialize recipient's KopfToken resource if not exists
        if (exists<KopfToken>(recipient_address) == false) {
            move_to(recipient, KopfToken {
                id: 0,
                value: 0,
                max_supply: 0, // Set max_supply to 0 by default
                total_supply: 0,
                token_name: vector::empty(),
                token_symbol: vector::empty(),
            });
        };
    
        let recipient_token = borrow_global_mut<KopfToken>(recipient_address);
        if (recipient_token.id == 0) {
            // Initialize recipient's KopfToken resource
            *recipient_token = KopfToken {
                id: 0,
                value: amount,
                max_supply: 1000000, // Set max_supply to a non-zero value
                total_supply: 0,
                token_name: vector::empty(),
                token_symbol: vector::empty(),
            };
        } else {
            recipient_token.value = recipient_token.value + amount;
        };

        // Check if recipient has sufficient balance
        assert!(recipient_token.value >= amount, 1);

        // Emit mint event
        let event = MintEvent {
            recipient: recipient_address,
            amount,
        };
        event::emit(event);

        // Check if mint amount exceeds max supply
        let token = borrow_global_mut<KopfToken>(signer::address_of(_account));
        assert!(token.total_supply + amount <= token.max_supply, 1);
        token.total_supply = token.total_supply + amount;
    }

   // Burn tokens
    public fun burn(account: &signer, amount: u64) acquires KopfToken {
        let addr = signer::address_of(account);
        let token = borrow_global_mut<KopfToken>(addr);
        assert!(token.value >= amount, 1); // Check if account has sufficient balance
        token.value = token.value - amount;
        token.total_supply = token.total_supply - amount; // Update total supply

        // Emit burn event
        let event = BurnEvent {
            account: addr,
            amount,
        };
        event::emit(event);
    }
    // Transfer tokens
    public fun transfer(sender: &signer, recipient: &signer, amount: u64) acquires KopfToken {
        // Initialize sender's KopfToken resource if not exists
        if (exists<KopfToken>(signer::address_of(sender)) == false) {
            move_to(sender, KopfToken {
                id: 0,
                value: 0,
                max_supply: 0,
                total_supply: 0,
                token_name: vector::empty(),
                token_symbol: vector::empty(),
            });
        };

        // Initialize recipient's KopfToken resource if not exists
        if (exists<KopfToken>(signer::address_of(recipient)) == false) {
            move_to(recipient, KopfToken {
                id: 0,
                value: 0,
                max_supply: 0,
                total_supply: 0,
                token_name: vector::empty(),
                token_symbol: vector::empty(),
            });
        };

        // Transfer tokens from sender to recipient
        let sender_token = borrow_global_mut<KopfToken>(signer::address_of(sender));
        assert!(sender_token.value >= amount, 1); // Check if sender has sufficient balance
        sender_token.value = sender_token.value - amount;

        let recipient_token = borrow_global_mut<KopfToken>(signer::address_of(recipient));
        recipient_token.value = recipient_token.value + amount;

        // Emit transfer event
        let event = TransferEvent {
            sender: signer::address_of(sender),
            recipient: signer::address_of(recipient),
            amount,
        };
        event::emit(event);
    }

    // Get user balance
    public fun get_balance(user: address): u64 acquires KopfToken {
        let token = borrow_global<KopfToken>(user);
        token.value
    }

    public fun get_name_by_address(account: address): vector<u8> acquires KopfToken {
        let token = borrow_global<KopfToken>(account);
        // Assuming token_name is stored in KopfToken struct
        token.token_name
    }

    public fun get_symbol_by_address(account: address): vector<u8> acquires KopfToken {
        let token = borrow_global<KopfToken>(account);
        // Assuming token_symbol is stored in KopfToken struct
        token.token_symbol
    }

    public fun get_max_supply(account: &signer): u64 acquires KopfToken {
        let token = borrow_global<KopfToken>(signer::address_of(account));
        token.max_supply
    }

    public fun get_total_supply(account: &signer): u64 acquires KopfToken {
        let token = borrow_global<KopfToken>(signer::address_of(account));
        token.total_supply
    }

}