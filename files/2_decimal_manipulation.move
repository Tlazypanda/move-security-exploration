module 0x42::defi_protocol {
    use std::signer;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::account;
    
    /// Constants
    const PROTOCOL_FEE_BPS: u64 = 15; // 0.15%
    const TREASURY_ADDRESS: address = @0x42;
    
    /// Error codes
    const EINSUFFICIENT_BALANCE: u64 = 1;
    const EZERO_AMOUNT: u64 = 2;
    
    struct SwapHistory<phantom CoinIn, phantom CoinOut> has key {
        total_volume: u64,
        total_fees_collected: u64,
        swap_count: u64
    }
    
    /// Initialize the protocol for a trading pair
    public entry fun initialize_pair<CoinIn, CoinOut>(admin: &signer) {
        let admin_addr = signer::address_of(admin);
        assert!(admin_addr == TREASURY_ADDRESS, 0);
        
        if (!exists<SwapHistory<CoinIn, CoinOut>>(admin_addr)) {
            move_to(admin, SwapHistory<CoinIn, CoinOut> {
                total_volume: 0,
                total_fees_collected: 0,
                swap_count: 0
            });
        };
    }
    
    /// Execute a swap with fee
    public entry fun execute_swap<CoinIn, CoinOut>(
        user: &signer, 
        amount: u64
    ) acquires SwapHistory {
        assert!(amount > 0, EZERO_AMOUNT);
        
        // Calculate fee
        let fee = calculate_protocol_fees(amount);
        
        // Deduct tokens from user
        let user_addr = signer::address_of(user);
        let tokens_in = coin::withdraw<CoinIn>(user, amount);
        
        // Split fee if applicable
        if (fee > 0) {
            let fee_tokens = coin::extract(&mut tokens_in, fee);
            coin::deposit(TREASURY_ADDRESS, fee_tokens);
        };
        
        // Perform swap logic (simplified)
        let tokens_out = get_tokens_out<CoinIn, CoinOut>(amount - fee);
        coin::deposit(user_addr, tokens_out);
        
        // Update history
        let history = borrow_global_mut<SwapHistory<CoinIn, CoinOut>>(TREASURY_ADDRESS);
        history.total_volume = history.total_volume + amount;
        history.total_fees_collected = history.total_fees_collected + fee;
        history.swap_count = history.swap_count + 1;
    }
    
    /// Calculate the protocol fee for a given amount
    public fun calculate_protocol_fees(size: u64): u64 {
        return size * PROTOCOL_FEE_BPS / 10000
    }
    
    /// Get output tokens (simplified implementation for challenge)
    fun get_tokens_out<CoinIn, CoinOut>(amount_in: u64): Coin<CoinOut> {
        // In a real DEX, this would calculate based on reserves
        // For this challenge, we'll just mint new tokens
        coin::mint<CoinOut>(amount_in, &account::create_test_signer_cap(TREASURY_ADDRESS))
    }
    
    /// View function to check total fees collected
    #[view]
    public fun total_fees_collected<CoinIn, CoinOut>(): u64 acquires SwapHistory {
        borrow_global<SwapHistory<CoinIn, CoinOut>>(TREASURY_ADDRESS).total_fees_collected
    }
}