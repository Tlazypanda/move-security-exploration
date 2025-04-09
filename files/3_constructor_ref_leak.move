module 0x42::nft_marketplace {
    use std::signer;
    use std::string::{Self, String};
    use aptos_framework::object::{Self, ConstructorRef, Object, ExtendRef, TransferRef, DeleteRef};
    use aptos_framework::coin::{Self, Coin};
    
    /// NFT token that can be traded on the marketplace
    struct TokenData has key, store {
        name: String,
        description: String,
        uri: String,
        creator: address
    }
    
    /// Ownership record for a token
    struct TokenOwnership has key, store {
        current_owner: address
    }
    
    /// Error codes
    const ENOT_OWNER: u64 = 1;
    const ETOKEN_NOT_FOUND: u64 = 2;
    
    /// Create a new token and return its Object<TokenData> and ConstructorRef
    public fun mint_token(
        creator: &signer,
        name: String,
        description: String,
        uri: String
    ): (Object<TokenData>, ConstructorRef) {
        let creator_addr = signer::address_of(creator);
        
        // Create a new object
        let constructor_ref = object::create_named_object(
            creator,
            *string::bytes(&name)
        );
        
        // Generate signer from constructor ref
        let token_signer = object::generate_signer(&constructor_ref);
        let token_address = signer::address_of(&token_signer);
        
        // Create token data
        let token_data = TokenData {
            name,
            description,
            uri,
            creator: creator_addr
        };
        
        // Initialize token ownership
        let token_ownership = TokenOwnership {
            current_owner: creator_addr
        };
        
        // Store token data and ownership
        move_to(&token_signer, token_data);
        move_to(&token_signer, token_ownership);
        
        // Return the token object and constructor ref
        (object::address_to_object<TokenData>(token_address), constructor_ref)
    }
    
    /// List a token for sale (simplified)
    public entry fun list_token_for_sale(
        seller: &signer,
        token: Object<TokenData>,
        price: u64
    ) acquires TokenOwnership {
        let seller_addr = signer::address_of(seller);
        let token_addr = object::object_address(&token);
        
        // Verify ownership
        let ownership = borrow_global<TokenOwnership>(token_addr);
        assert!(ownership.current_owner == seller_addr, ENOT_OWNER);
        
        // In a real marketplace, this would create a listing
        // For this challenge, we'll simplify this part
    }
    
    /// Buy a token (simplified)
    public entry fun buy_token<CoinType>(
        buyer: &signer,
        token: Object<TokenData>,
        payment: Coin<CoinType>
    ) acquires TokenOwnership {
        let buyer_addr = signer::address_of(buyer);
        let token_addr = object::object_address(&token);
        
        // In a real marketplace, this would verify the listing exists
        // and handle escrow, etc.
        
        // Get current owner
        let ownership = borrow_global_mut<TokenOwnership>(token_addr);
        let seller_addr = ownership.current_owner;
        
        // Verify payment (simplified)
        coin::deposit(seller_addr, payment);
        
        // Update ownership
        ownership.current_owner = buyer_addr;
    }
    
    /// Helper function to check token ownership
    #[view]
    public fun get_token_owner(token: Object<TokenData>): address acquires TokenOwnership {
        let token_addr = object::object_address(&token);
        borrow_global<TokenOwnership>(token_addr).current_owner
    }
}