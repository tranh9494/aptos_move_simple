# Aptos Move Simple

## Overview

Aptos Move Simple is a project that demonstrates basic functionalities in the Move programming language on the Aptos blockchain. This project includes implementations for token creation, NFTs, and custom resources.

## Features

-   **simpleToken**: A basic fungible token implementation.
    
-   **resourceNft**: A resource-based NFT model.
    
-   **onlyOneNft**: Ensures that each user can only own one NFT.
    
-   **nftBasic**: A basic implementation of an NFT system.
    
-   **myCustomNFT**: A customizable NFT model with additional functionalities.
    

## Requirements

-   Aptos CLI
    
-   Move language knowledge
    
-   Rust (for Move compiler)
    
-   Aptos testnet or local network
    

## Installation

1.  Clone the repository:
    
    ```
    git clone https://github.com/tranh9494/aptos-move-simple.git
    cd aptos-move-simple
    ```
    
2.  Install dependencies:
    
    ```
    aptos init
    ```
    
3.  Compile the Move modules:
    
    ```
    aptos move compile
    ```
    
4.  Deploy to the Aptos blockchain:
    
    ```
    aptos move publish --profile default
    ```
    

## Usage

-   **Minting Tokens**:
    
    ```
    aptos move run --function-id default::simpleToken::mint --args <recipient_address> <amount>
    ```
    
-   **Minting an NFT**:
    
    ```
    aptos move run --function-id default::nftBasic::mint --args <recipient_address>
    ```
    
-   **Checking Balance**:
    
    ```
    aptos move run --function-id default::simpleToken::balance_of --args <address>
    ```
    

## License

This project is open-source and available under the MIT License.

## Contributions

Feel free to submit pull requests or open issues for improvements and bug fixes.

## Contact

For any questions or support, please reach out via GitHub Issues.
