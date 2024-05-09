# L2 <-> L1 Messaging

This project demonstrated how to message between Ethereum and the Starknet L2.

<BR />


## Setup

1. Install asdf, Scarb and Starkli.

1. Make sure the two have the same Cairo version downgrading scarb if necessary.

    ```BASH
    starkli declare --help
    # Check the version info included with the compiler-version parameter

    scarb --version
    ```

1. Build the project

    ```BASH
    scarb build
    ```

<BR />


## Command Dump

Class Hash: `0x072458426fced34bcde0a3ccc90c3d41a72728918213b7eb2bcadbe21c57d1df` <BR />
Contract: `0x03d845f90b5c3160fa1e1fede38e4283f5ba4036d3a305220b20f1feee677065`

```BASH
# Publish the contract on the L2 chain
starkli declare target/dev/starkone_CrossChain.contract_class.json \
            --account ~/.starkli-wallets/deployer/account.json  \
            --keystore ~/.starkli-wallets/deployer/keystore.json   \
            --compiler-version=2.6.2 --estimate-only --network sepolia

starkli declare target/dev/starkone_CrossChain.contract_class.json \
            --rpc https://starknet-sepolia.infura.io/v3/67a984ea915d43568e63f81d4142f08b \
            --account ~/.starkli-wallets/deployer/account.json \
            --keystore ~/.starkli-wallets/deployer/keystore.json \
            --compiler-version=2.6.2 --max-fee 0.001

# Deploy the contract on L2
starkli deploy \
            0x072458426fced34bcde0a3ccc90c3d41a72728918213b7eb2bcadbe21c57d1df \
            0xCbB9660eA60B895443ef5001B968b6Ae4c0AaA18 \
            0x036ea88e18632de7053fb93fc98de1b71ec2461d88ee1ba1bcf97846cd551972 \
            --account ~/.starkli-wallets/deployer/account.json \
            --keystore ~/.starkli-wallets/deployer/keystore.json --estimate-only --network sepolia

starkli deploy \
            0x072458426fced34bcde0a3ccc90c3d41a72728918213b7eb2bcadbe21c57d1df \
            0xCbB9660eA60B895443ef5001B968b6Ae4c0AaA18 \
            0x036ea88e18632de7053fb93fc98de1b71ec2461d88ee1ba1bcf97846cd551972 \
            --rpc https://starknet-sepolia.infura.io/v3/67a984ea915d43568e63f81d4142f08b \
            --account ~/.starkli-wallets/deployer/account.json \
            --keystore ~/.starkli-wallets/deployer/keystore.json --max-fee 0.0001

# Test the deployment by reading/writing some values
starkli call \
            0x03d845f90b5c3160fa1e1fede38e4283f5ba4036d3a305220b20f1feee677065 \
            get_eth_owner --network=sepolia

starkli call \
            0x03d845f90b5c3160fa1e1fede38e4283f5ba4036d3a305220b20f1feee677065 \
            get_strk_owner --network=sepolia

starkli invoke \
            0x03d845f90b5c3160fa1e1fede38e4283f5ba4036d3a305220b20f1feee677065 \
            set_value 0x23452345  \
            --account ~/.starkli-wallets/deployer/account.json \
            --keystore ~/.starkli-wallets/deployer/keystore.json --max-fee 0.0001 --network sepolia

starkli call \
            0x03d845f90b5c3160fa1e1fede38e4283f5ba4036d3a305220b20f1feee677065 \
            get_value --network=sepolia

# L1 -> L2
# Get the function selector for value_from_l1() to determine the parameters necessary on calling
# StarknetMessaging::sendMessageToL2()
starkli selector value_from_l1
# Return Value: 0x03967dca2b3810ada0a91e22a47b45210d884fc5bdf0cfcd2b2250e87fb08d3a
# Next we move to L1 and call sendMessageToL2()


# L2 -> L1
starkli invoke \
            0x03d845f90b5c3160fa1e1fede38e4283f5ba4036d3a305220b20f1feee677065 \
            value_to_l1 \
            --account ~/.starkli-wallets/deployer/account.json \
            --keystore ~/.starkli-wallets/deployer/keystore.json --estimate-only --network sepolia

starkli invoke \
            0x03d845f90b5c3160fa1e1fede38e4283f5ba4036d3a305220b20f1feee677065 \
            value_to_l1 \
            --account ~/.starkli-wallets/deployer/account.json \
            --keystore ~/.starkli-wallets/deployer/keystore.json --max-fee 0.001 --network sepolia
# Returned transaction id: 0x066837659680e09bbcb0099a4736ee435163289fc62876b495a12798b6d1fef0
# Monitor this transaction id to see when we can "read" the value on L1.
```

<BR />


## Notes on L1 -> L2

The Starknet L1 seplia contract addresses are listed here: <BR />
https://docs.starknet.io/documentation/tools/important_addresses/#starknet_version_on_sepolia_testnet

The Core contract responsible for L1 <--> L2 messaging is (a proxy): <BR />
`0xE2Bb56ee936fd6433DC0F6e7e3b8365C906AA057`

Calling StarknetMessaging::sendMessageToL2() on the proxy  <BR />
https://sepolia.etherscan.io/address/0xE2Bb56ee936fd6433DC0F6e7e3b8365C906AA057#writeProxyContract

```
StarknetMessaging::sendMessageToL2(
        value     = 0.002 ETH
        toAddress = 0x03d845f90b5c3160fa1e1fede38e4283f5ba4036d3a305220b20f1feee677065
        selector  = 0x03967dca2b3810ada0a91e22a47b45210d884fc5bdf0cfcd2b2250e87fb08d3a
        payload   = 0x10102020
)
```

Note: the value for calling l1_msg could not be estimated using starkli as starkli invoke does not support
calling l1_handler functions so this was a rule of thumb estimate also by estimating set_x().

<BR />

## Notes on L2 -> L1

We just invoke the L2 contract function that calls send_message_to_l1_syscall.
Next we wait for 4 hrs until this is published.

Monitor the status thorugh the explorer: <BR />
https://sepolia.starkscan.co/tx/0x66837659680e09bbcb0099a4736ee435163289fc62876b495a12798b6d1fef0
