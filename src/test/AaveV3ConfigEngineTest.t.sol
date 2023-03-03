// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {IAaveV3ConfigEngine} from '../v3-config-engine/IAaveV3ConfigEngine.sol';
import {AaveV3PolygonMockListing} from './mocks/AaveV3PolygonMockListing.sol';
import {AaveV3PolygonRatesUpdates070322} from './mocks/gauntlet-updates/AaveV3PolygonRatesUpdates070322.sol';
import '../ProtocolV3TestBase.sol';

contract AaveV3ConfigEngineTest is ProtocolV3TestBase {
  using stdStorage for StdStorage;

  function testListing() public {
    vm.createSelectFork(vm.rpcUrl('polygon'), 39797440);
    (address ratesFactory, ) = DeployRatesFactoryPolLib.deploy();

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEnginePolLib.deploy(ratesFactory));
    AaveV3PolygonMockListing payload = new AaveV3PolygonMockListing(engine);

    vm.startPrank(AaveV3Polygon.ACL_ADMIN);
    AaveV3Polygon.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    // createConfigurationSnapshot('preTestEngine', AaveV3Polygon.POOL);

    ReserveConfig[] memory allConfigsBefore = _getReservesConfigs(AaveV3Polygon.POOL);

    payload.execute();

    // createConfigurationSnapshot('postTestEngine', AaveV3Polygon.POOL);

    // diffReports('preTestEngine', 'postTestEngine');

    ReserveConfig[] memory allConfigsAfter = _getReservesConfigs(AaveV3Polygon.POOL);

    ReserveConfig memory expectedAssetConfig = ReserveConfig({
      symbol: '1INCH',
      underlying: 0x9c2C5fd7b07E95EE044DDeba0E97a665F142394f,
      aToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
      variableDebtToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
      stableDebtToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
      decimals: 18,
      ltv: 82_50,
      liquidationThreshold: 86_00,
      liquidationBonus: 105_00,
      liquidationProtocolFee: 10_00,
      reserveFactor: 10_00,
      usageAsCollateralEnabled: true,
      borrowingEnabled: true,
      interestRateStrategy: _findReserveConfigBySymbol(allConfigsAfter, 'AAVE')
        .interestRateStrategy,
      stableBorrowRateEnabled: false,
      isActive: true,
      isFrozen: false,
      isSiloed: false,
      isBorrowableInIsolation: false,
      isFlashloanable: false,
      supplyCap: 85_000,
      borrowCap: 60_000,
      debtCeiling: 0,
      eModeCategory: 0
    });

    _validateReserveConfig(expectedAssetConfig, allConfigsAfter);

    _noReservesConfigsChangesApartNewListings(allConfigsBefore, allConfigsAfter);

    _validateReserveTokensImpls(
      AaveV3Polygon.POOL_ADDRESSES_PROVIDER,
      _findReserveConfigBySymbol(allConfigsAfter, '1INCH'),
      ReserveTokens({
        aToken: engine.ATOKEN_IMPL(),
        stableDebtToken: engine.STOKEN_IMPL(),
        variableDebtToken: engine.VTOKEN_IMPL()
      })
    );

    _validateAssetSourceOnOracle(
      AaveV3Polygon.POOL_ADDRESSES_PROVIDER,
      0x9c2C5fd7b07E95EE044DDeba0E97a665F142394f,
      0x443C5116CdF663Eb387e72C688D276e702135C87
    );

    // impl should be same as e.g. AAVE
    _validateReserveTokensImpls(
      AaveV3Polygon.POOL_ADDRESSES_PROVIDER,
      _findReserveConfigBySymbol(allConfigsAfter, 'AAVE'),
      ReserveTokens({
        aToken: engine.ATOKEN_IMPL(),
        stableDebtToken: engine.STOKEN_IMPL(),
        variableDebtToken: engine.VTOKEN_IMPL()
      })
    );
  }

  function testCapsUpdates() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 16727659);
    (address ratesFactory, ) = DeployRatesFactoryEthLib.deploy();

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEngineEthLib.deploy(ratesFactory));
    AaveV3EthereumMockCapUpdate payload = new AaveV3EthereumMockCapUpdate(engine);

    vm.startPrank(AaveV3Ethereum.ACL_ADMIN);
    AaveV3Ethereum.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    ReserveConfig[] memory allConfigsBefore = _getReservesConfigs(AaveV3Ethereum.POOL);
    payload.execute();
    ReserveConfig[] memory allConfigsAfter = _getReservesConfigs(AaveV3Ethereum.POOL);

    ReserveConfig memory expectedAssetConfig = ReserveConfig({
      symbol: allConfigsBefore[6].symbol,
      underlying: allConfigsBefore[6].underlying,
      aToken: allConfigsBefore[6].aToken,
      variableDebtToken: allConfigsBefore[6].variableDebtToken,
      stableDebtToken: allConfigsBefore[6].stableDebtToken,
      decimals: allConfigsBefore[6].decimals,
      ltv: allConfigsBefore[6].ltv,
      liquidationThreshold: allConfigsBefore[6].liquidationThreshold,
      liquidationBonus: allConfigsBefore[6].liquidationBonus,
      liquidationProtocolFee: allConfigsBefore[6].liquidationProtocolFee,
      reserveFactor: allConfigsBefore[6].reserveFactor,
      usageAsCollateralEnabled: allConfigsBefore[6].usageAsCollateralEnabled,
      borrowingEnabled: allConfigsBefore[6].borrowingEnabled,
      interestRateStrategy: allConfigsBefore[6].interestRateStrategy,
      stableBorrowRateEnabled: allConfigsBefore[6].stableBorrowRateEnabled,
      isActive: allConfigsBefore[6].isActive,
      isFrozen: allConfigsBefore[6].isFrozen,
      isSiloed: allConfigsBefore[6].isSiloed,
      isBorrowableInIsolation: allConfigsBefore[6].isBorrowableInIsolation,
      isFlashloanable: allConfigsBefore[6].isFlashloanable,
      supplyCap: 1_000_000,
      borrowCap: allConfigsBefore[6].borrowCap,
      debtCeiling: allConfigsBefore[6].debtCeiling,
      eModeCategory: allConfigsBefore[6].eModeCategory
    });

    _validateReserveConfig(expectedAssetConfig, allConfigsAfter);
  }

  function testCollateralsUpdates() public {
    vm.createSelectFork(vm.rpcUrl('avalanche'), 26871634);
    (address ratesFactory, ) = DeployRatesFactoryAvaLib.deploy();

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEngineAvaLib.deploy(ratesFactory));
    AaveV3AvalancheCollateralUpdate payload = new AaveV3AvalancheCollateralUpdate(engine);

    vm.startPrank(AaveV3Avalanche.ACL_ADMIN);
    AaveV3Avalanche.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    ReserveConfig[] memory allConfigsBefore = _getReservesConfigs(AaveV3Avalanche.POOL);
    payload.execute();
    ReserveConfig[] memory allConfigsAfter = _getReservesConfigs(AaveV3Avalanche.POOL);

    ReserveConfig memory expectedAssetConfig = ReserveConfig({
      symbol: allConfigsBefore[6].symbol,
      underlying: allConfigsBefore[6].underlying,
      aToken: allConfigsBefore[6].aToken,
      variableDebtToken: allConfigsBefore[6].variableDebtToken,
      stableDebtToken: allConfigsBefore[6].stableDebtToken,
      decimals: allConfigsBefore[6].decimals,
      ltv: 62_00,
      liquidationThreshold: 72_00,
      liquidationBonus: 106_00, // 100_00 + 6_00
      liquidationProtocolFee: allConfigsBefore[6].liquidationProtocolFee,
      reserveFactor: allConfigsBefore[6].reserveFactor,
      usageAsCollateralEnabled: allConfigsBefore[6].usageAsCollateralEnabled,
      borrowingEnabled: allConfigsBefore[6].borrowingEnabled,
      interestRateStrategy: allConfigsBefore[6].interestRateStrategy,
      stableBorrowRateEnabled: allConfigsBefore[6].stableBorrowRateEnabled,
      isActive: allConfigsBefore[6].isActive,
      isFrozen: allConfigsBefore[6].isFrozen,
      isSiloed: allConfigsBefore[6].isSiloed,
      isBorrowableInIsolation: allConfigsBefore[6].isBorrowableInIsolation,
      isFlashloanable: allConfigsBefore[6].isFlashloanable,
      supplyCap: allConfigsBefore[6].supplyCap,
      borrowCap: allConfigsBefore[6].borrowCap,
      debtCeiling: allConfigsBefore[6].debtCeiling,
      eModeCategory: allConfigsBefore[6].eModeCategory
    });

    _validateReserveConfig(expectedAssetConfig, allConfigsAfter);
  }

  function testRateStrategiesUpdates() public {
    vm.createSelectFork(vm.rpcUrl('optimism'), 74562421);
    (address ratesFactory, ) = DeployRatesFactoryOptLib.deploy();

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEngineOptLib.deploy(ratesFactory));
    AaveV3OptimismMockRatesUpdate payload = new AaveV3OptimismMockRatesUpdate(engine);

    vm.startPrank(AaveV3Optimism.ACL_ADMIN);
    AaveV3Optimism.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    IDefaultInterestRateStrategy initialStrategy = IDefaultInterestRateStrategy(
      AaveV3OptimismAssets.USDT_INTEREST_RATE_STRATEGY
    );
    payload.execute();
    address updatedStrategyAddress = AaveV3Optimism.AAVE_PROTOCOL_DATA_PROVIDER.getInterestRateStrategyAddress(AaveV3OptimismAssets.USDT_UNDERLYING);

    InterestStrategyValues memory expectedInterestStrategyValues = InterestStrategyValues({
      addressesProvider: address(AaveV3Optimism.POOL_ADDRESSES_PROVIDER),
      optimalUsageRatio: _bpsToRay(80_00),
      baseVariableBorrowRate: initialStrategy.getBaseVariableBorrowRate(),
      variableRateSlope1: initialStrategy.getVariableRateSlope1(),
      variableRateSlope2: _bpsToRay(75_00),
      stableRateSlope1: initialStrategy.getStableRateSlope1(),
      stableRateSlope2: _bpsToRay(75_00),
      baseStableBorrowRate: initialStrategy.getBaseStableBorrowRate(),
      optimalStableToTotalDebtRatio: initialStrategy.OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO()
    });

    _validateInterestRateStrategy(
      updatedStrategyAddress,
      updatedStrategyAddress,
      expectedInterestStrategyValues
    );
  }

  function testPolygonRatesUpdate() public {
    vm.createSelectFork(vm.rpcUrl('polygon'), 39797440);

    (address ratesFactory, ) = DeployRatesFactoryPolLib.deploy();

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEnginePolLib.deploy(ratesFactory));
    AaveV3PolygonRatesUpdates070322 payload = new AaveV3PolygonRatesUpdates070322(engine);

    vm.startPrank(AaveV3Polygon.ACL_ADMIN);
    AaveV3Polygon.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    createConfigurationSnapshot('preTestEnginePolygonRates', AaveV3Polygon.POOL);

    payload.execute();

    createConfigurationSnapshot('postTestEnginePolygonRates', AaveV3Polygon.POOL);

    diffReports('preTestEnginePolygonRates', 'postTestEnginePolygonRates');
  }

  function _bpsToRay(uint256 amount) internal pure returns (uint256) {
    return (amount * 1e27) / 10_000;
  }
}

