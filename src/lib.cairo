#[starknet::interface]
trait ICrossChain<TState> {
    fn get_eth_owner(self: @TState) -> starknet::EthAddress;
    fn get_strk_owner(self: @TState) -> starknet::ContractAddress;
    fn get_value(self: @TState) -> u128;
    fn set_value(ref self: TState, new_value: u128);
}

#[starknet::contract]
mod CrossChain {
    use starknet::syscalls::send_message_to_l1_syscall;
    use starknet::ContractAddress;
    use starknet::EthAddress;
    use starknet::get_caller_address;

    #[storage]
    struct Storage {
        value: u128,
        eth_owner: EthAddress,
        strk_owner: ContractAddress,
    }

    #[abi(embed_v0)]
    impl CrossChainPub of super::ICrossChain<ContractState> {

        fn get_eth_owner(self: @ContractState) -> EthAddress {
            self.eth_owner.read()
        }

        fn get_strk_owner(self: @ContractState) -> ContractAddress {
            self.strk_owner.read()
        }

        fn get_value(self: @ContractState) -> u128 {
            self.value.read()
        }

        fn set_value(ref self: ContractState, new_value: u128) {
            let caller = get_caller_address();
            assert(caller == self.strk_owner.read(), 'Unauthorized strk sender');

            self.value.write(new_value);
        }
    }

    #[abi(per_item)]
    #[generate_trait]
    impl CrossChain of AutoTrait {

        #[constructor]
        fn constructor(
                ref self: ContractState,
                eth_owner_addr: EthAddress,
                strk_owner_addr: ContractAddress) {

            // This is wrong! The contract is deployed by a special
            // contract that only exposes the deployContract function.
            // Hence, get_caller_address() won't return the wallet contract
            // address but the address of this intermediate contract.
            // let caller = get_caller_address();
            // self.strk_owner.write(caller);

            self.eth_owner.write(eth_owner_addr);
            self.strk_owner.write(strk_owner_addr);
        }

        // L1 -> L2 message handler, to be called by sequencer.
        #[l1_handler]
        fn value_from_l1(ref self: ContractState, from_address: felt252, new_value: felt252) {
            assert(from_address == self.eth_owner.read().into(), 'Unauthorized eth sender');
            self.value.write(new_value.try_into().unwrap());
        }

        // L2 -> L1 message sender
        #[external(v0)]
        fn value_to_l1(ref self: ContractState) {
            let caller = get_caller_address();
            assert(caller == self.strk_owner.read(), 'Unauthorized strk sender');

            // We "serialize" value, as the payload must be `Span<felt252>`.
            let params :Array<felt252> =  array![self.value.read().into()];
            send_message_to_l1_syscall(self.eth_owner.read().into(), params.span())
                .unwrap();
        }
    }
}
