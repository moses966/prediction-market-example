// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "contracts/dependencies/contracts/optimistic-oracle-v3/implementation/OptimisticOracleV3.sol";

contract OOV3 is OptimisticOracleV3 {
    /**
     * @notice Constructor for the OOV3 contract.
     * @param _finder keeps track of all contracts within the UMA system based on their interfaceName.
     * @param _defaultCurrency the default currency to bond asserters in assertTruthWithDefaults.
     * @param _defaultLiveness the default liveness for assertions in assertTruthWithDefaults   
     */
    constructor(
        FinderInterface _finder,
        IERC20 _defaultCurrency,
        uint64 _defaultLiveness
    )
        OptimisticOracleV3(_finder, _defaultCurrency, _defaultLiveness)
    {}
}
