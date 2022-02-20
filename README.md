Zero-Knowledge proof application. 

This was a project for the Stanford Class, CS251: "Blockchain and Cryptocurrencies". 

This project is based on the functionality of Tornado cash. It constructs a Merkle Tree for storing coins, just like Tornado Cash, and has the logic for spending a coin. 

The files of interest are: 
1. circuits/spend.circom -- implements the circuit logic of spending a coin from the Merkle Tree in Tornado cash.  
2. src/compute_spend_inputs.js -- JS logic for searching down merkle tree. Uses circuit. 

The remaining files are boilerplate provided by course staff.
