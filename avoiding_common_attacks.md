# Safety Checklist for Common Attacks

*   Logic bugs
    *   I tried to avoid these by writing multiple tests for the contract.
*   Recursive Calls
    *   I only use one external contract that I trust (the Strings library), although if I called other contracts I should use the 'reentry' flag.
*   Integer Arithmetic Overflow
    *   There are no user-supplied data that involves arithmetic operations
*   Poison Data
    *   I disallow resources with too long a name by checking in the frontend if a user-supplied name is over 15 characters.
*   Exposed Functions
    *   All functions that should only be used by the owner is checked with the isOwner modifier.
*   Exposed Secrets
    *   Admittedly the information is exposed, but this can be mitigated in the future by encrypting the data and decrypting it on the frontend, so information on the blockchain cannot be read.
*   DoS
    *   A user can whitelist who can notify him/her, reducing the ability of malicious actors to spam.
*   Miner vulnerabilities
    *   I don't use block hashes
*   Malicious Creator
    *   There are no functions that allows the creator to take the funds owned by users of the contract.
*   Off-chain safety
    *   I have ensured that the only external library call has been audited.
*   Cross-chain Replay Attack
    *   As this will be deployed after the Ethereum hard-fork, this attack should not occur.
*   Tx.Origin Problem
    *   My contract does not use tx.origin
*   Solidity Fallback Data Collisions
    *   I don't have fallback functions read msg.data
*   Incorrect use of Cryptography
    *   I don't make use of cryptography
*   Gas limits
    *   I sanitize the data before it is entered into the blockchain