use openzeppelin::tests::mocks::vestingwallet_mocks::vestingwalletmock;
use openzeppelin::finance::vestingwallet::VestingWalletComponent;
use openzeppelin::finance::vestingwallet::VestingWalletComponent::{VestingWallet,InternalImpl};
use openzeppelin::tests::utils::constants::{
    ZERO, OWNER, 
};
use starknet::{ContractAddress, get_contract_address, get_block_timestamp};


type ComponentState = VestingWalletComponent::ComponentState<vestingwalletmock::ContractState>;



fn COMPONENT_STATE() -> ComponentState {
    VestingWalletComponent::component_state_for_testing()
}

fn setup() -> ComponentState {
    let mut state = COMPONENT_STATE();
    state.initializer(OWNER(), get_block_timestamp() + 60, 60 * 60);
    state
}

//
// initializer & constructor
//

#[test]
fn test_initializer() {
    let mut state = COMPONENT_STATE();
    state.initializer(OWNER(), get_block_timestamp() + 60, 60 * 60);
    // assert_eq!(state.owner(), OWNER());
    assert_eq!(state.get_start(), (get_block_timestamp() + 60).into());
    assert_eq!(state.get_duration(), 60 * 60); 
}

