module 0x200e2ea1904de5eed8e653399905fb9b657c8218e3198257d29138883eb9caca::KopfToken {
    use std::signer;
    use std::vector;
    use std::event;
    use std::account;
    use std::option;

    //constants for errors
    const EINVALID_MAX_SUPPLY: u64 = 1001;
    const EINVALID_SYMBOL: u64 = 1002;
    const EINVALID_AMOUNT: u64 = 1003;
    const EINVALID_RECIPIENT: u64 = 1004;
    const EMAX_SUPPLY_REACHED: u64 = 1005;
    const EINSUFFICIENT_BALANCE: u64 = 1006;
    const EINSUFFICIENT_SUPPLY: u64 = 1007;

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
    public fun initialize(account: &signer, max_supply: u64, token_name: vector<u8>, token_symbol: vector<u8>) {
        assert!(max_supply > 0, EINVALID_MAX_SUPPLY); // Validate max supply
        assert!(vector::length(&token_symbol) > 0, EINVALID_SYMBOL); // Validate symbol

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

    // Mint tokens
    public fun mint(_account: &signer, recipient: &signer, amount: u64): option::Option<bool> acquires KopfToken {
        assert!(amount > 0, EINVALID_AMOUNT); // Amount must be positive
        assert!(signer::address_of(recipient) != @0x1, EINVALID_RECIPIENT); // Recipient cannot be zero address
        let token = borrow_global_mut<KopfToken>(signer::address_of(_account));
        assert!(signer::address_of(_account) == token.owner, 1); // Check owner


        // Initialize recipient's KopfToken resource if not exists
        let recipient_address = signer::address_of(recipient); 
        if (recipient_address == @0x1) {
            return option::none(); // Return none for zero address
        };
        assert!(recipient_address != @0x1, 1); // Prevent transfer to zero address

        if (!exists<KopfToken>(recipient_address)) {
            0x200e2ea1904de5eed8e653399905fb9b657c8218e3198257d29138883eb9caca::KopfToken::initialize(
                recipient, 
                100, 
                b"MyToken", 
                b"KOPF"
            );
            assert!(exists<KopfToken>(recipient_address), 1); // Ensure initialization
        };

        let recipient_token = borrow_global_mut<KopfToken>(recipient_address);
        if (recipient_token.id == 0) {
            *recipient_token = KopfToken {
                id: 0,
                value: amount,
                max_supply: 1000000, 
                total_supply: 0,
                token_name: vector::empty(),
                token_symbol: vector::empty(),
                owner: recipient_address,
                mint_events: vector::empty(),
                transfer_events: vector::empty(),
                burn_events: vector::empty(), 
            };
        } else {
            recipient_token.value = recipient_token.value + amount;
        };

        // Check if mint amount exceeds max supply
        {
            let token = borrow_global_mut<KopfToken>(signer::address_of(_account));
            token.total_supply = token.total_supply + amount;
            assert!(token.total_supply <= token.max_supply, EMAX_SUPPLY_REACHED);
        };

        // Emit mint event and store it
        let event = MintEvent {
            recipient: recipient_address,
            amount,
        };
        let event_copy = copy event;
        event::emit(event);
        let sender_token = borrow_global_mut<KopfToken>(signer::address_of(_account));
        vector::push_back(&mut sender_token.mint_events, event_copy);

        option::some(true)
    }

    // Burn tokens
    public fun burn(account: &signer, amount: u64): option::Option<bool> acquires KopfToken {
        assert!(amount > 0, EINVALID_AMOUNT);

        let addr = signer::address_of(account);
        let token = borrow_global_mut<KopfToken>(addr);

        // Authorization check
        assert!(token.owner == addr, 1);

        // Check sufficient total supply
        if (token.total_supply < amount) {
            abort(EINSUFFICIENT_SUPPLY);
        };

        // Check sufficient balance
        assert!(token.value >= amount, EINSUFFICIENT_BALANCE);

        // Update balance
        token.value = token.value - amount;

        //update total supply
        token.total_supply = token.total_supply - amount;

        // Emit burn event
        let event = BurnEvent {
            account: addr,
            amount,
        };
        let event_copy = copy event;
        event::emit(event);
        vector::push_back(&mut token.burn_events, event_copy);

        option::some(true)
    } 


    // Transfer tokens
    public fun transfer(sender: &signer, recipient: &signer, amount: u64): option::Option<bool> acquires KopfToken {
        // Validate transfer amount
        assert!(amount > 0, EINVALID_AMOUNT); // Amount must be positive
        let recipient_address = signer::address_of(recipient);
        assert!(signer::address_of(recipient) != @0x1, EINVALID_RECIPIENT); // Recipient cannot be zero address

        if (!exists<KopfToken>(recipient_address)) {
            0x200e2ea1904de5eed8e653399905fb9b657c8218e3198257d29138883eb9caca::KopfToken::initialize(recipient, 100, b"MyToken", b"MTK");
        };

        //creating a new KopfToken resource for the sender, using move_to
        if (!exists<KopfToken>(signer::address_of(sender))) {
            move_to(sender, KopfToken {
                id: 0,
                value: 0,
                max_supply: 0,
                total_supply: 0,
                token_name: vector::empty(),
                token_symbol: vector::empty(),
                owner: signer::address_of(sender), 
                mint_events: vector::empty(),
                    transfer_events: vector::empty(),
                    burn_events: vector::empty(),
            });
        };

        // Transfer tokens from sender to recipient
        let recipient_token = borrow_global_mut<KopfToken>(signer::address_of(recipient));
        let new_value = recipient_token.value + amount;
        if (new_value < recipient_token.value) {
            abort 1 // Overflow would occur, abort transaction
        };
        recipient_token.value = new_value;

        let sender_token = borrow_global_mut<KopfToken>(signer::address_of(sender));
        assert!(signer::address_of(sender) == sender_token.owner, 2); // Only owner can transfer
        assert!(sender_token.value >= amount, EINSUFFICIENT_BALANCE); // Check balance
        sender_token.value = sender_token.value - amount;

        // Emit transfer event and store it
        let event = TransferEvent {
            sender: signer::address_of(sender),
            recipient: signer::address_of(recipient),
            amount,
        };
        event::emit(event);
        vector::push_back(&mut sender_token.transfer_events, event);
        option::some(true)
    }


    // Get user balance
    public fun get_balance(user: address): option::Option<u64> acquires KopfToken {
        if (user == @0x1) {
            option::none() // Return none for zero address
        } else {
            let token = borrow_global<KopfToken>(user);
            option::some(token.value)
        }
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
}