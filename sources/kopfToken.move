module 0x200e2ea1904de5eed8e653399905fb9b657c8218e3198257d29138883eb9caca::KopfToken {
    use std::signer;
    use std::vector;
    use std::event;
    use std::account;
    use std::option;
    //use 0x1::Signer;
    

    //constants for errors
    const EINVALID_MAX_SUPPLY: u64 = 1001;
    const EINVALID_SYMBOL: u64 = 1002;
    const EINVALID_AMOUNT: u64 = 1003;
    const EINVALID_RECIPIENT: u64 = 1004;
    const EMAX_SUPPLY_REACHED: u64 = 1005;
    const EINSUFFICIENT_BALANCE: u64 = 1006;
    const EINSUFFICIENT_SUPPLY: u64 = 1007;
    const EINVALID_OWNER: u64 = 1008;
    const ERESOURCE_NOT_FOUND: u64 = 1009;
    const ERESOURCE_ALREADY_EXISTS: u64 = 1010;

    struct KopfToken has key, store, drop {
        id: u64,
        value: u64,
        max_supply: u64,
        total_supply: u64,
        token_name: vector<u8>,
        token_symbol: vector<u8>,
        owner: address, // Store owner address
        mint_events: vector<MintEvent>,
        transfer_events: vector<TransferEvent>,
        burn_events: vector<BurnEvent>, 
    }

    // Define token events
    #[event]
    struct MintEvent has store, drop, copy {
        recipient: address,
        amount: u64,
    }

    #[event]
    struct BurnEvent has store, drop, copy {
        account: address,
        amount: u64,
    }

    #[event]
    struct TransferEvent has store, drop, copy {
        sender: address,
        recipient: address,
        amount: u64,
    }

    // Initialize token supply
    public entry fun initialize(account: &signer, max_supply: u64, token_name: vector<u8>, token_symbol: vector<u8>) {
        assert!(max_supply > 0, EINVALID_MAX_SUPPLY); // Validate max supply
        assert!(vector::length(&token_symbol) > 0, EINVALID_SYMBOL); // Validate symbol
        assert!(!exists<KopfToken>(signer::address_of(account)), EINVALID_RECIPIENT); // Check for existing token resource
        let token = KopfToken {
            id: 0,
            value: 0,
            max_supply,
            total_supply: 0,
            token_name,
            token_symbol,
            owner: signer::address_of(account), // Initialize owner
            mint_events: vector::empty(),
            transfer_events: vector::empty(),
            burn_events: vector::empty(), 
        };
        move_to(account, token);
    }

    //initlizing the recipient 
    public entry fun initialize_recipient(account: &signer){
        let recipient_address = signer::address_of(account);

        // Ensure the recipient does not already have a KopfToken resource
        assert!(!exists<KopfToken>(recipient_address), ERESOURCE_ALREADY_EXISTS);

        // Create a new KopfToken resource for the recipient
        move_to(account, KopfToken {
            id: 0,
            value: 0,
            max_supply: 0, // Placeholder; customize if needed
            total_supply: 0,
            token_name: b"KopfToken",
            token_symbol: b"KOPF",
            owner: recipient_address,
            mint_events: vector::empty(),
            transfer_events: vector::empty(),
            burn_events: vector::empty(),
        });
    }


    // Mint tokens
    public entry fun mint(account: &signer, recipient: address, amount: u64) acquires KopfToken {
        let token_owner = signer::address_of(account);

        // Check if sender is token owner
        {
            let token = borrow_global_mut<KopfToken>(token_owner);
            assert!(token.owner == token_owner, EINVALID_OWNER);

            if (recipient == @0x0) {
                abort(EINVALID_RECIPIENT); // Minting to zero address is invalid
            };
            // Check sufficient supply
            assert!(token.total_supply + amount <= token.max_supply, EMAX_SUPPLY_REACHED);

            // Mint tokens
            token.total_supply = token.total_supply + amount;
        };

        // Initialize recipient's token resource if needed
        if (!exists<KopfToken>(recipient)) {
            initialize_recipient(account);
        };

        // Add minted tokens to recipient and log event
        {
            let recipient_token = borrow_global_mut<KopfToken>(recipient);
            let event = MintEvent {
                recipient,
                amount,
            };
            event::emit(event);
            vector::push_back(&mut recipient_token.mint_events, event);
            recipient_token.value = recipient_token.value + amount;
        }
    }





    // Burn tokens
    public entry fun burn(account: &signer, amount: u64) acquires KopfToken {
        assert!(amount > 0, EINVALID_AMOUNT); // Amount must be positive

        let addr = signer::address_of(account);
        let token = borrow_global_mut<KopfToken>(addr);

        // Authorization check
        assert!(token.owner == addr, 1);

        // Check sufficient total supply
        if (token.total_supply < amount) {
            abort(EINSUFFICIENT_SUPPLY) // Insufficient supply to burn
        };

        // Check sufficient balance
        assert!(token.value >= amount, EINSUFFICIENT_BALANCE); // Ensure balance is sufficient

        // Update balance
        token.value = token.value - amount;

        // Update total supply
        token.total_supply = token.total_supply - amount;

        // Emit burn event
        let event = BurnEvent {
            account: addr,
            amount,
        };
        event::emit(event);
        vector::push_back(&mut token.burn_events, event);
    }



    // Transfer tokens
    public entry fun transfer(sender: &signer, recipient: &signer, amount: u64) acquires KopfToken {
        let sender_address = signer::address_of(sender);
        let recipient_address = signer::address_of(recipient);

        assert!(has_kopf_token(sender_address), ERESOURCE_NOT_FOUND);
        assert!(amount > 0, EINVALID_AMOUNT);
        assert!(recipient_address != @0x0, EINVALID_RECIPIENT); 


        if (!has_kopf_token(recipient_address)) {
            initialize_recipient(recipient);
        };

        {
            let sender_token = borrow_global_mut<KopfToken>(sender_address);
            assert!(sender_token.value >= amount, EINSUFFICIENT_BALANCE);
            sender_token.value = sender_token.value - amount;
        }; // sender_token goes out of scope here

        let recipient_token = borrow_global_mut<KopfToken>(recipient_address);
        recipient_token.value = recipient_token.value + amount;

        // Log transfer event
        let event = TransferEvent {
            sender: sender_address,
            recipient: recipient_address,
            amount,
        };
        event::emit(event);
        vector::push_back(&mut recipient_token.transfer_events, event);
    }


    // Get user balance
    public fun get_balance(user: address): option::Option<u64> acquires KopfToken {
        if (!exists<KopfToken>(user)) {
            abort(EINVALID_RECIPIENT) // Token not initialized
        };
        let token = borrow_global<KopfToken>(user);
        option::some(token.value)
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

    public fun get_total_supply(recipient: address): u64 acquires KopfToken {
        let token = borrow_global<KopfToken>(recipient);
        token.total_supply
    }

    public fun get_burn_events(account: address): vector<BurnEvent> acquires KopfToken {
        let token = borrow_global<KopfToken>(account);
        token.burn_events
    }

    public fun get_mint_events(account: address): vector<MintEvent> acquires KopfToken {
        let token = borrow_global<KopfToken>(account);
        token.mint_events
    }

    public fun get_transfer_events(account: address): vector<TransferEvent> acquires KopfToken {
        let token = borrow_global<KopfToken>(account);
        token.transfer_events
    }

    public fun get_burn_event_account(event: BurnEvent): address {
        event.account
    }

    public fun get_burn_event_amount(event: BurnEvent): u64 {
        event.amount
    }

    public fun get_transfer_event_sender(event: TransferEvent): address {
        event.sender
    }

    public fun get_transfer_event_recipient(event: TransferEvent): address {
        event.recipient
    }

    public fun get_transfer_event_amount(event: TransferEvent): u64 {
    event.amount
    }


    fun has_kopf_token(account: address): bool {
        exists<KopfToken>(account)
    }

  
}