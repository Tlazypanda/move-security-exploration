script {
    use ctf::defi_protocol;

    fun zero_fee_swap<CoinA,CoinB>(caller:&signer){
        let swap_time = 100000;
        for(x in 0..swap_time){
            //swap 100000 time of 660 amount of CoinA to CoinB  -> zero fee
            // defi_protoco::execute_swap<CoinA,CoinB>(caller,660);
        }
    }

    ///Since I changed several settings of the original code to conform to the required test, there is an error here. /// Your original code CoinIN is missing the drop capability, therefore it won't pass the test unit without depositing somewhere.
    /// CoinOut is deployed, but you acquire token_out using account::create_test_signer_cap(TREASURY_ADDRESS).
    /// This is a generate signer capability, not a mint capability, thus I made some minor changes to ensure it works on the test unit.
    /// However, the vulnerability section does not affect anything.

    /// Vulnerability Part
    /// fee are cal by size * PROTOCOL_FEE_BPS / 10000
    /// PROTOCOL_FEE_BPS == 15
    /// So just need to make sure the size * 15 is smaller than 10000 ,could get zero fee

    /// Fixed method
    /// let fee = if(size * PROTOCOL_FEE_BPS < 10000){
    ///    100000000000000000000000000000000000000000000
    /// }else{
    ///    size * PROTOCOL_FEE_BPS / 10000
    /// }
    /// NO one can skip the fee XD

}