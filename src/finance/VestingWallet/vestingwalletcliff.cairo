// SPDX-License-Identifier: MIT
#[starknet::component]
mod VestingWalletCliffComponent {
    use openzeppelin::access::ownable::{
        OwnableComponent, OwnableComponent::InternalImpl as Ownable
    };
    use openzeppelin::finance::vestingwallet::interface;
    use openzeppelin::finance::vestingwallet::{
        VestingWalletComponent, VestingWalletComponent::InternalImpl as VestingWallet
    };
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::{ContractAddress, get_contract_address, get_block_timestamp};

    #[storage]
    struct Storage {
        #[substorage(v0)]
        cliff: u64,
    }

    mod Errors {
        const InvalidCliffDuration: felt252 = 'InvalidCliffDuration';
    }

    #[embeddable_as(VestingWalletCliffImpl)]
    impl VestingWalletCliff<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl Ownable: OwnableComponent::HasComponent<TContractState>,
        impl VestingWallet: VestingWalletComponent::HasComponent<TContractState>,
    > of interface::IVestingWalletCliff<ComponentState<TContractState>> {
        fn get_cliff(self: @ComponentState<TContractState>) -> u64 {
            return self.cliff.read();
        }

        fn vestedAmount(
            self: @ComponentState<TContractState>, token: ContractAddress, timestamp: u64
        ) -> u256 {
            let tokenAmount = IERC20Dispatcher { contract_address: token }
                .balance_of(get_contract_address());
            let vestingwallet = get_dep_component!(self, VestingWallet);
            return self
                ._vestingSchedule(tokenAmount + vestingwallet.erc20released.read(token), timestamp);
        }
    }

    #[generate_trait]
    impl InternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl Ownable: OwnableComponent::HasComponent<TContractState>,
        impl VestingWallet: VestingWalletComponent::HasComponent<TContractState>,
    > of InternalTrait<TContractState> {
        fn initializer(
            ref self: ComponentState<TContractState>,
            beneficiary: ContractAddress,
            _start: u64,
            _duration: u64,
            _cliff: u64,
        ) {
            let mut vestingwallet = get_dep_component_mut!(ref self, VestingWallet);
            vestingwallet.initializer(beneficiary, _start, _duration);
            assert(_cliff < _duration, Errors::InvalidCliffDuration);
            self.cliff.write(vestingwallet.start.read() + _cliff);
        }

        fn _vestingSchedule(
            self: @ComponentState<TContractState>, totalAllocation: u256, timestamp: u64
        ) -> u256 {
            let vestingwallet = get_dep_component!(self, VestingWallet);

            if (timestamp < self.cliff.read()) {
                return 0;
            } else {
                return vestingwallet._vestingSchedule(totalAllocation, timestamp);
            }
        }
    }
}
