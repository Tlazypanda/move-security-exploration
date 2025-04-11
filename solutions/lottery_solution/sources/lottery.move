module ctf::lottery {
    use std::signer;
    use aptos_framework::randomness;

    /// Resource representing a win in the lottery
    struct WIN has key {
        prize: u64
    }

    /// Error codes
    const EWIN_ALREADY_EXISTS: u64 = 1;

    /// Awards the prize to the user by creating a WIN resource in their account
    fun mint_win_to_user(user: &signer, prize: u64) {
        let user_addr = signer::address_of(user);
        assert!(!exists<WIN>(user_addr), EWIN_ALREADY_EXISTS);
        move_to(user, WIN { prize });
    }

    /// Main lottery function - generates a random number and awards prize if it's 42
    #[lint::allow_unsafe_randomness]
    public fun play(user: &signer) {
        let random_value = randomness::u64_range(0, 100);
        if (random_value == 42) {
            mint_win_to_user(user, 1000);
        }
    }

    /// Check if a user has won
    #[view]
    public fun has_won(addr: address): bool {
        exists<WIN>(addr)
    }

    /// Get prize amount if user has won
    #[view]
    public fun get_prize(addr: address): u64 acquires WIN {
        assert!(exists<WIN>(addr), 0);
        borrow_global<WIN>(addr).prize
    }
}