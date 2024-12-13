script {
    use 0x68729baa1d029ccd3fa1c53a445e83ad05add47d76b5b04d4ff15f9de56952fa::KopfKoin;

        fun main(account: &signer) {
            let contract_address = @0x68729baa1d029ccd3fa1c53a445e83ad05add47d76b5b04d4ff15f9de56952fa; // Directly use the address
            //let total_supply = KopfKoin::get_total_supply(contract_address);
            //assert!(total_supply > 0, 1); // prevent division-by-zero

            //let amount_to_mint = total_supply * 90 / 100;
            0x68729baa1d029ccd3fa1c53a445e83ad05add47d76b5b04d4ff15f9de56952fa::KopfKoin::mint(account, contract_address, 500);
        }
        
}
