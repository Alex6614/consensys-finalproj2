# Supply Chain Error Propagation

## Overview

This is an error reporting system used by suppliers and manufacturers. It allows error notifications to propagate down a supply chain. This allows you to send messages through the supply chain directly without middlemen.

The product of each organization may be composed of many parts from other organizations. Each of those parts may consist of even more parts. For example, you might be Dell producing a laptop. The laptop may be made of a screen, buttons, and chips (obviously simplified). Those chips are made of transistors and resisistors. And so on. If a laptop is found to be defective due to a chip, we'd like to notify the chip manufacturers that an error may exist in their products. This app goes a step further and notifies the producers of parts that go into a chip, as well.

## What I Built

A simple web app where you can send notifications to your suppliers, as well as a file through IPFS. You can:

1.  Upload the name of your parts
2.  Whitelist other users and allow them to send your notifications
3.  Attach an IPFS file to your notification
4.  Receive notifications
5.  Stop the blockchain using the circuit breaker, if you are admin.

## How to use

### Aim

Here, we emulate a supply chain! We set up a supply chain with three entities, such that when the top organization sends a notification, the second entity gets an error notification, as well as a link to the file describing the defect, and the third gets a warning.

Suppose we have a laptop store account, a laptop manufacturer, and a chip manufacturer:

*   Account 1 = Laptop Store Account
*   Account 2 = Laptop Manufacturer
*   Account 3 = Chip Manufacturer

### Setup Development server and smart contract

1.  Go into the directory and install packages with command "npm install" (This may take up to 5 minutes)
2.  Compile contracts with command "truffle compile"
3.  Create your blockchain in the console with command "ganache-cli". Be sure to copy the seed phrase. 
4.  Run development server with command "npm start"
5.  Access the accounts on Metamask by inputting the seed phrase.
6.  Migrate the contract using "truffle migrate"

### Using the App

1.  Setting up the chain
    1.  Make sure you are in account 1\. Copy its address.
    2.  Go to account 2\. Enter "laptop" as the new part name, and "chip" as the new subpart name. Then press submit. Wait for an alert confirmation before moving forward :)
    3.  In account 2, whitelist account 1 by entering "laptop" in the whitelist section and copying the address into the form. Then press submit. Copy the address of account 1\. As before, wait for a confirmation.
    4.  Go to account 3\. Enter "chip" as the new part name, and leave the subpart section empty. Then press submit. Wait for a confirmation.
    5.  In account 3, whitelist account 2 by entering "chip" in the whitelist section and copying account 2's address into the form. Then press submit. Wait for a confirmation.
2.  Sending the notification
    1.  Go to account 1.
    2.  Add an IPFS file by browsing through your files and sending a small one. Try adding "sampleNotification.txt" from the root of the project. Press "Send it," then wait for a hash to appear underneath. 
    3.  Type in "laptop" for the part name, and add your IPFS address copied from above. Press submit, and wait for a confirmation.
3.  Receiving the notification
    1.  Go to account 2\. Go down and press receive notification. You will receive ether from account 1, and you will also see details of the error underneath.
    2.  See your file by opening a new tab and typing: "https://gateway.ipfs.io/ipfs/xxx", replacing "xxx" with the ipfs hash. You should see your file!
    3.  Go to account 3\. Press receive notification. Here, you won't receive any ether, but you will still get a warning that a product (ie. the laptop) that uses your product (ie. your chip) might be defective.
4.  Trying out circuit breaker.
    1.  Go to account 1 (or whichever account instantiated the contract).
    2.  Press "Toggle Emergency Stop"
    3.  Wait for a confirmation, then press "Check Emergency Stop". It should cause an alert to pop up, indicating that the circuit breaker has been set to true.
    4.  Now, most of the other buttons will not allow for successful transaction to occur.

## Tests

1.  Testing if one can add a resource: Covers the "addResource" function. This adds a resource for a member. Checks if the corresponding event has been emitted, and if the blockchain has recorded a new part for the user.
2.  Testing if the subparts of a resource is also added: Covers the "getSubparts" function. This adds a resource with subparts for a member. Then checks if they exist on the blockchain.
3.  Testing if subparts can be split using the imported string library. Covers the "getSubparts" function, and part of the "notify" function. This checks if the space separated subparts can be split using the string library, which is used to propagate errors down the supply chain.
4.  Testing if users can be whitelisted for particular resources: Covers the "whitelistUser" function. This checks if the blockchain can whitelist users for specific parts.
5.  Testing if the admin can toggle the circuit breaker: Covers the "toggleContractActive" function. This checks if the admin can toggle the circuit breaker, leaving functions unusable until the circuit breaker is turned off.