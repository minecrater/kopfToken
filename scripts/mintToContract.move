script {
    use 0x267a963667e052710cd401a169148191542789cb7b807d343f54b1873b9eac0b::KopfKoin;
    use 0x267a963667e052710cd401a169148191542789cb7b807d343f54b1873b9eac0b::KopfKoin::{mint, get_total_supply};


    fun main(account: &signer) {
        let contract_address = @0x267a963667e052710cd401a169148191542789cb7b807d343f54b1873b9eac0b; // Directly use the address
        let total_supply = KopfKoin::get_total_supply(contract_address);
        assert!(total_supply > 0, 1); // prevent division-by-zero

        let amount_to_mint = total_supply * 90 / 100;
        KopfKoin::mint(account, contract_address, amount_to_mint);
    }
}
