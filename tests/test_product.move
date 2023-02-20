#[test_only]
module satay_liquidswap_automated::test_product {

    // use std::signer;
    //
    // use aptos_framework::coin;
    // use aptos_framework::aptos_coin::{Self, AptosCoin};
    // use aptos_framework::stake;
    // use aptos_framework::account;
    //
    // use satay::satay_account;
    // use satay::satay;
    //
    // use satay_liquidswap_automated::liquidswap_harvest_strategy;
    // use satay::strategy_config;
    // use satay_liquidswap_automated::liquidswap_harvest_strategy::LiquidswapHarvest;
    // use satay_coins::strategy_coin::StrategyCoin;
    // use satay::setup_tests;
    //
    // // constants
    //
    // const DEPOSIT_AMOUNT: u64 = 100000;
    // const SATAY_APTOS_AMOUNT: u64 = 5000;
    //
    // // errors
    //
    // const ERR_INITIALIZE: u64 = 1;
    // const ERR_DEPOSIT: u64 = 2;
    //
    // fun setup_tests(
    //     aptos_framework: &signer,
    //     satay: &signer,
    //     user: &signer,
    // ) {
    //     setup_tests::setup_tests_with_user(aptos_framework, satay, user, DEPOSIT_AMOUNT);
    //     liquidswap_harvest_strategy::initialize<AptosCoin>(satay);
    // }
    //
    // #[test(
    //     aptos_framework = @aptos_framework,
    //     satay = @satay,
    //     user = @0x100,
    // )]
    // fun test_initialize(
    //     aptos_framework: &signer,
    //     satay: &signer,
    //     user: &signer,
    // ) {
    //     setup_tests(aptos_framework, satay, user);
    //     let strategy_address = liquidswap_harvest_strategy::get_strategy_account_address<AptosCoin>();
    //     let strategy_manager = strategy_config::get_strategy_manager_address<AptosCoin, MockStrategy>(strategy_address);
    //     assert!(strategy_manager == @satay, ERR_INITIALIZE);
    // }
    //
    // #[test(
    //     aptos_framework = @aptos_framework,
    //     satay = @satay,
    //     user = @0x100
    // )]
    // fun test_deposit(
    //     aptos_framework: &signer,
    //     satay: &signer,
    //     user: &signer
    // ) {
    //     setup_tests(aptos_framework, satay, user);
    //     liquidswap_harvest_strategy::deposit<AptosCoin>(user, DEPOSIT_AMOUNT);
    //
    //     assert!(coin::balance<StrategyCoin<AptosCoin, MockStrategy>>(signer::address_of(user)) == DEPOSIT_AMOUNT, ERR_DEPOSIT);
    //
    //     let next_deposit_amount = 1000;
    //     assert!(
    //         liquidswap_harvest_strategy::calc_product_coin_amount<AptosCoin>(next_deposit_amount) == next_deposit_amount, ERR_DEPOSIT);
    // }
    //
    // #[test(
    //     aptos_framework = @aptos_framework,
    //     satay = @satay,
    //     user = @0x100
    // )]
    // fun test_withdraw(
    //     aptos_framework: &signer,
    //     satay: &signer,
    //     user: &signer
    // ) {
    //     setup_tests(aptos_framework, satay, user);
    //     liquidswap_harvest_strategy::deposit<AptosCoin>(user, DEPOSIT_AMOUNT);
    //     liquidswap_harvest_strategy::withdraw<AptosCoin>(user, DEPOSIT_AMOUNT);
    // }
    //
    // #[test(
    //     aptos_framework = @aptos_framework,
    //     satay = @satay,
    //     user = @0x100
    // )]
    // fun test_tend(
    //     aptos_framework: &signer,
    //     satay: &signer,
    //     user: &signer
    // ) {
    //     setup_tests(aptos_framework, satay, user);
    //     liquidswap_harvest_strategy::deposit<AptosCoin>(user, DEPOSIT_AMOUNT);
    //     liquidswap_harvest_strategy::tend<AptosCoin>(satay);
    // }
}
