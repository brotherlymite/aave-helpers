// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPool, IPoolConfigurator, IAaveOracle} from 'aave-address-book/AaveV3.sol';
import {IV3RateStrategyFactory} from './IV3RateStrategyFactory.sol';

/// @dev Examples here assume the usage of the `AaveV3PayloadBase` base contracts
/// contained in this same repository
interface IAaveV3ConfigEngine {
  /**
   * @dev Required for naming of a/v/s tokens
   * Example (mock):
   * PoolContext({
   *   networkName: 'Polygon',
   *   networkAbbreviation: 'Pol'
   * })
   */
  struct PoolContext {
    string networkName;
    string networkAbbreviation;
  }

  /**
   * @dev Example (mock):
   * Listing({
   *   asset: 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9,
   *   assetSymbol: 'AAVE',
   *   priceFeed: 0x547a514d5e3769680Ce22B2361c10Ea13619e8a9,
   *   rateStrategyParams: Rates.RateStrategyParams({
   *     optimalUsageRatio: _bpsToRay(80_00),
   *     baseVariableBorrowRate: _bpsToRay(25), // 0.25%
   *     variableRateSlope1: _bpsToRay(3_00),
   *     variableRateSlope2: _bpsToRay(75_00),
   *     stableRateSlope1: _bpsToRay(3_00),
   *     stableRateSlope2: _bpsToRay(75_00),
   *     baseStableRateOffset: _bpsToRay(2_00),
   *     stableRateExcessOffset: _bpsToRay(3_00),
   *     optimalStableToTotalDebtRatio: _bpsToRay(30_00)
   *   }),
   *   enabledToBorrow: true,
   *   flashloanable: true,
   *   stableRateModeEnabled: false,
   *   borrowableInIsolation: true,
   *   withSiloedBorrowing:, false,
   *   ltv: 70_50, // 70.5%
   *   liqThreshold: 76_00, // 76%
   *   liqBonus: 5_00, // 5%
   *   reserveFactor: 10_00, // 10%
   *   supplyCap: 100_000, // 100k AAVE
   *   borrowCap: 60_000, // 60k AAVE
   *   debtCeiling: 100_000, // 100k USD
   *   liqProtocolFee: 10_00, // 10%
   *   eModeCategory: 0, // No category
   * }
   */
  struct Listing {
    address asset;
    string assetSymbol;
    address priceFeed;
    IV3RateStrategyFactory.RateStrategyParams rateStrategyParams; // Mandatory, no matter if enabled for borrowing or not
    bool enabledToBorrow;
    bool stableRateModeEnabled; // Only considered is enabledToBorrow == true
    bool borrowableInIsolation; // Only considered is enabledToBorrow == true
    bool withSiloedBorrowing; // Only considered if enabledToBorrow == true
    bool flashloanable; // Independent from enabled to borrow: an asset can be flashloanble and not enabled to borrow
    uint256 ltv; // Only considered if liqThreshold > 0
    uint256 liqThreshold; // If `0`, the asset will not be enabled as collateral
    uint256 liqBonus; // Only considered if liqThreshold > 0
    uint256 reserveFactor; // Only considered if enabledToBorrow == true
    uint256 supplyCap; // If passing any value distinct to EngineFlags.KEEP_CURRENT, always configured
    uint256 borrowCap; // If passing any value distinct to EngineFlags.KEEP_CURRENT, always configured
    uint256 debtCeiling; // Only considered if liqThreshold > 0
    uint256 liqProtocolFee; // Only considered if liqThreshold > 0
    uint8 eModeCategory; // If `O`, no eMode category will be set
  }

  /**
   * @dev Example (mock):
   * CapsUpdate({
   *   asset: AaveV3EthereumAssets.AAVE_UNDERLYING,
   *   supplyCap: 1_000_000,
   *   borrowCap: EngineFlags.KEEP_CURRENT
   * }
   */
  struct CapsUpdate {
    address asset;
    uint256 supplyCap; // Pass any value, of EngineFlags.KEEP_CURRENT to keep it as it is
    uint256 borrowCap; // Pass any value, of EngineFlags.KEEP_CURRENT to keep it as it is
  }

  /**
   * @dev Example (mock):
   * CapsUpdate({
   *   asset: AaveV3EthereumAssets.AAVE_UNDERLYING,
   *   ltv: 60_00,
   *   liqThreshold: 70_00,
   *   liqBonus: EngineFlags.KEEP_CURRENT,
   *   debtCeiling: EngineFlags.KEEP_CURRENT,
   *   liqProtocolFee: 7_00,
   *   eModeCategory: EngineFlags.KEEP_CURRENT
   * })
   */
  struct CollateralUpdate {
    address asset;
    uint256 ltv;
    uint256 liqThreshold;
    uint256 liqBonus;
    uint256 debtCeiling;
    uint256 liqProtocolFee;
    uint256 eModeCategory;
  }

  /**
   * @dev Example (mock):
   * RateStrategyUpdate({
   *   asset: AaveV3OptimismAssets.USDT_UNDERLYING,
   *   params: Rates.RateStrategyParams({
   *     optimalUsageRatio: _bpsToRay(80_00),
   *     baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
   *     variableRateSlope1: EngineFlags.KEEP_CURRENT,
   *     variableRateSlope2: _bpsToRay(75_00),
   *     stableRateSlope1: EngineFlags.KEEP_CURRENT,
   *     stableRateSlope2: _bpsToRay(75_00),
   *     baseStableRateOffset: EngineFlags.KEEP_CURRENT,
   *     stableRateExcessOffset: EngineFlags.KEEP_CURRENT,
   *     optimalStableToTotalDebtRatio: EngineFlags.KEEP_CURRENT
   *   })
   * })
   */
  struct RateStrategyUpdate {
    address asset;
    IV3RateStrategyFactory.RateStrategyParams params;
  }

  /**
   * @notice Performs a full listing of an asset in the Aave pool configured in this engine instance
   * @param context `PoolContext` struct, effectively meta-data for naming of a/v/s tokens.
   *   More information on the documentation of the struct.
   * @param listings `Listing[]` list of declarative configs for every aspect of the asset listing.
   *   More information on the documentation of the struct.
   */
  function listAssets(PoolContext memory context, Listing[] memory listings) external;

  /**
   * @notice Performs an update of the caps (supply, borrow) of an asset, in the Aave pool configured in this engine instance
   * @param updates `CapsUpdate[]` list of declarative updates containing the new caps
   *   More information on the documentation of the struct.
   */
  function updateCaps(CapsUpdate[] memory updates) external;

  /**
   * @notice Performs an update the rate strategy params of an asset, in the Aave pool configured in this engine instance
   * @dev The engine itself manages if a new rate strategy needs to be deployed or if an existing one can be re-used
   * @param updates `RateStrategyUpdate[]` list of declarative updates containing the new rate strategy params
   *   More information on the documentation of the struct.
   */
  function updateRateStrategies(RateStrategyUpdate[] memory updates) external;

  /**
   * @notice Performs an update of the collateral-related params of an asset, in the Aave pool configured in this engine instance
   * @param updates `CapsUpCollateralUpdatedate[]` list of declarative updates containing the new parameters
   *   More information on the documentation of the struct.
   */
  function updateCollateralSide(CollateralUpdate[] memory updates) external;

  function RATE_STRATEGIES_FACTORY() external view returns (IV3RateStrategyFactory);

  function POOL() external view returns (IPool);

  function POOL_CONFIGURATOR() external view returns (IPoolConfigurator);

  function ORACLE() external view returns (IAaveOracle);

  function ATOKEN_IMPL() external view returns (address);

  function VTOKEN_IMPL() external view returns (address);

  function STOKEN_IMPL() external view returns (address);

  function REWARDS_CONTROLLER() external view returns (address);

  function COLLECTOR() external view returns (address);
}