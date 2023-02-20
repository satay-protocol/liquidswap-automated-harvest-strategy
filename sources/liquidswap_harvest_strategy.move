module satay_liquidswap_automated::liquidswap_harvest_strategy {

    use std::signer;

    use std::option;

    use aptos_framework::coin::{Self, Coin};

    use satay_coins::strategy_coin::StrategyCoin;

    use satay::math;
    use satay::satay;
    use satay::strategy_config;
    use harvest::stake;

    struct LiquidswapHarvest<phantom StakeCoin, phantom RewardCoin> has drop {}

    struct TendLock<phantom StakeCoin, phantom RewardCoin> {
        pool_addr: address
    }

    // governance functions

    /// initialize StrategyCapability<BaseCoin, LiquidswapHarvest<StakeCoin, RewardCoin>> and StrategyCoin<BaseCoin, LiquidswapHarvest<StakeCoin, RewardCoin>>
    /// * governance: &signer - must have the governance role on satay::global_config
    public entry fun initialize<StakeCoin, RewardCoin>(governance: &signer) {
        satay::new_strategy<StakeCoin, LiquidswapHarvest<StakeCoin, RewardCoin>>(
            governance,
            LiquidswapHarvest<StakeCoin, RewardCoin> {}
        );
    }

    // strategy manager functions

    /// claim rewards, convert to BaseCoin, and deposit back into the strategy
    /// * strategy_manager: &signer - must have the strategy manager role account on satay::strategy_config
    public fun open_for_tend<StakeCoin, RewardCoin>(
        strategy_manager: &signer,
        pool_addr: address
    ): (Coin<RewardCoin>, TendLock<StakeCoin, RewardCoin>) {
        strategy_config::assert_strategy_manager<StakeCoin, LiquidswapHarvest<StakeCoin, RewardCoin>>(
            strategy_manager,
            get_strategy_account_address<StakeCoin, RewardCoin>()
        );
        (stake::harvest<StakeCoin, RewardCoin>(
            &satay::strategy_signer<StakeCoin, LiquidswapHarvest<StakeCoin, RewardCoin>>(LiquidswapHarvest<StakeCoin, RewardCoin> {}),
            pool_addr
        ), TendLock<StakeCoin, RewardCoin> { pool_addr })
    }

    public fun close_for_tend<StakeCoin, RewardCoin>(
        stake_coins: Coin<StakeCoin>,
        tend_lock: TendLock<StakeCoin, RewardCoin>,
    ) {
        let TendLock<StakeCoin, RewardCoin> { pool_addr } = tend_lock;
        stake::stake<StakeCoin, RewardCoin>(
            &satay::strategy_signer<StakeCoin, LiquidswapHarvest<StakeCoin, RewardCoin>>(LiquidswapHarvest<StakeCoin, RewardCoin> {}),
            pool_addr,
            stake_coins
        );
    }

    // user functions

    /// deposit BaseCoin into the strategy for user, mint StrategyCoin<BaseCoin, LiquidswapHarvest<StakeCoin, RewardCoin>> in return
    /// * user: &signer - must hold amount of BaseCoin
    /// * amount: u64 - the amount of BaseCoin to deposit
    public entry fun deposit<StakeCoin, RewardCoin>(user: &signer, amount: u64, pool_addr: address) {
        let base_coins = coin::withdraw<StakeCoin>(user, amount);
        let strategy_coins = apply<StakeCoin, RewardCoin>(base_coins, pool_addr);
        if(!coin::is_account_registered<StrategyCoin<StakeCoin, LiquidswapHarvest<StakeCoin, RewardCoin>>>(signer::address_of(user))) {
            coin::register<StrategyCoin<StakeCoin, LiquidswapHarvest<StakeCoin, RewardCoin>>>(user);
        };
        coin::deposit(signer::address_of(user), strategy_coins);
    }

    /// burn StrategyCoin<BaseCoin, LiquidswapHarvest<StakeCoin, RewardCoin>> for user, withdraw BaseCoin from the strategy in return
    /// * user: &signer - must hold amount of StrategyCoin<BaseCoin, LiquidswapHarvest<StakeCoin, RewardCoin>>
    /// * amount: u64 - the amount of StrategyCoin<BaseCoin, LiquidswapHarvest<StakeCoin, RewardCoin>> to burn
    public entry fun withdraw<StakeCoin, RewardCoin>(user: &signer, amount: u64, pool_addr: address) {
        let strategy_coins = coin::withdraw<StrategyCoin<StakeCoin, LiquidswapHarvest<StakeCoin, RewardCoin>>>(user, amount);
        let aptos_coins = liquidate<StakeCoin, RewardCoin>(strategy_coins, pool_addr);
        coin::deposit(signer::address_of(user), aptos_coins);
    }

    /// convert BaseCoin into StrategyCoin<BaseCoin, LiquidswapHarvest<StakeCoin, RewardCoin>>
    /// * base_coins: Coin<BaseCoin> - the BaseCoin to convert
    public fun apply<StakeCoin, RewardCoin>(
        base_coins: Coin<StakeCoin>,
        pool_addr: address
    ): Coin<StrategyCoin<StakeCoin, LiquidswapHarvest<StakeCoin, RewardCoin>>> {
        let base_coin_value = coin::value(&base_coins);
        stake::stake<StakeCoin, RewardCoin>(
            &satay::strategy_signer<StakeCoin, LiquidswapHarvest<StakeCoin, RewardCoin>>(LiquidswapHarvest<StakeCoin, RewardCoin> {}),
                pool_addr,
                base_coins
        );
        satay::strategy_mint<StakeCoin, LiquidswapHarvest<StakeCoin, RewardCoin>>(
            calc_product_coin_amount<StakeCoin, RewardCoin>(base_coin_value, pool_addr),
            LiquidswapHarvest<StakeCoin, RewardCoin> {}
        )
    }

    /// convert StrategyCoin<BaseCoin, LiquidswapHarvest<StakeCoin, RewardCoin>> into BaseCoin
    /// * strategy_coins: Coin<StrategyCoin<BaseCoin, LiquidswapHarvest<StakeCoin, RewardCoin>>> - the StrategyCoin to convert
    public fun liquidate<StakeCoin, RewardCoin>(
        strategy_coins: Coin<StrategyCoin<StakeCoin, LiquidswapHarvest<StakeCoin, RewardCoin>>>,
        pool_addr: address
    ): Coin<StakeCoin> {
        let strategy_coin_value = coin::value(&strategy_coins);
        satay::strategy_burn(strategy_coins, LiquidswapHarvest<StakeCoin, RewardCoin> {});
        stake::unstake<StakeCoin, RewardCoin>(
            &satay::strategy_signer<StakeCoin, LiquidswapHarvest<StakeCoin, RewardCoin>>(LiquidswapHarvest<StakeCoin, RewardCoin> {}),
            pool_addr,
            calc_base_coin_amount<StakeCoin, RewardCoin>(strategy_coin_value, pool_addr)
        )
    }

    // calculations

    /// calculate the amount of product coins that can be minted for a given amount of base coins
    /// * product_coin_amount: u64 - the amount of ProductCoin<BaseCoin> to be converted
    public fun calc_base_coin_amount<StakeCoin, RewardCoin>(strategy_coin_amount: u64, pool_addr: address): u64 {
        let base_coin_balance = stake::get_user_stake<StakeCoin, RewardCoin>(
            get_strategy_account_address<StakeCoin, RewardCoin>(),
            pool_addr
        );
        let strategy_coin_supply_option = coin::supply<StrategyCoin<StakeCoin, LiquidswapHarvest<StakeCoin, RewardCoin>>>();
        let strategy_coin_supply = option::get_with_default(&strategy_coin_supply_option, 0);
        if(strategy_coin_supply == 0) {
            return base_coin_balance
        };
        math::calculate_proportion_of_u64_with_u128_denominator(
            base_coin_balance,
            strategy_coin_amount,
            strategy_coin_supply,
        )
    }

    /// calculate the amount of base coins that can be liquidated for a given amount of product coins
    /// * base_coin_amount: u64 - the amount of BaseCoin to be converted
    public fun calc_product_coin_amount<StakeCoin, RewardCoin>(base_coin_amount: u64, pool_addr: address): u64 {
        let base_coin_balance = stake::get_user_stake<StakeCoin, RewardCoin>(
            get_strategy_account_address<StakeCoin, RewardCoin>(),
            pool_addr
        );
        let strategy_coin_supply_option = coin::supply<StrategyCoin<StakeCoin, LiquidswapHarvest<StakeCoin, RewardCoin>>>();
        if(base_coin_balance == 0) {
            return base_coin_amount
        };
        math::mul_u128_u64_div_u64_result_u64(
            option::get_with_default(&strategy_coin_supply_option, 0),
            base_coin_amount,
            base_coin_balance,
        )
    }

    // getters

    /// gets the address of the product account for BaseCoin
    public fun get_strategy_account_address<StakeCoin, RewardCoin>(): address
    {
        satay::get_strategy_address<StakeCoin, LiquidswapHarvest<StakeCoin, RewardCoin>>()
    }

    /// gets the witness for the LiquidswapHarvest<StakeCoin, RewardCoin>
    public(friend) fun get_strategy_witness<StakeCoin, RewardCoin>(): LiquidswapHarvest<StakeCoin, RewardCoin> {
        LiquidswapHarvest<StakeCoin, RewardCoin> {}
    }
}
