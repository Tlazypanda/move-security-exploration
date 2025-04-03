# CTF Challenge: Lottery Manipulation

## Background

A simple lottery smart contract built on Move. In this lottery, users can try their luck by calling the `play` function, which uses the Aptos randomness framework to generate a random number between 0 and 99. If the user gets the winning number (42), they win 1000 tokens!

The developer has taken some security precautions by properly implementing randomness, but might have made a critical mistake in function visibility.

## Challenge Objective

Your task is to find a vulnerability in the lottery contract and create an exploit module that guarantees you'll win. You must demonstrate a 100% success rate (you should never lose).

## Contract Code

```move
module 0x42::lottery {
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
```

## Hint

Think about function visibility and test-and-abort patterns. Notice how randomness is used and how it could be manipulated in a transaction.

## Deliverables

1. Create an exploit module that demonstrates the vulnerability.
2. Explain in comments how your exploit works.
3. Suggest a fix to make the lottery secure.

## Rules

- You cannot modify the original lottery module.
- Your solution must work 100% of the time.
- Your explanation should clearly identify the vulnerability.

## Example Solution Format

```move
module 0x43::exploit {
    use 0x42::lottery;

    entry fun exploit(attacker: &signer) {
        // Your exploit code here
        
        // ...
        
        // Explanation:
        // This exploit works because...
    }
}
```

Good luck, and may the odds be ever in your favor (or in this case, 100% in your favor)!