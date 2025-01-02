// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.0;

// Inherit Finder contract using `is`
import "contracts/dependencies/contracts/data-verification-mechanism/implementation/Store.sol";

contract StoreContract is Store {
    /**
     * @notice Constructor for StoreContract.
     * @param _fixedOracleFeePerSecondPerPfc Fixed Oracle fee per second per PFC.
     * @param _weeklyDelayFeePerSecondPerPfc Weekly delay fee per second per PFC.
     * @param _timerAddress Address of the Timer contract (or address(0) for live network).
     */
    constructor(
        FixedPoint.Unsigned memory _fixedOracleFeePerSecondPerPfc,
        FixedPoint.Unsigned memory _weeklyDelayFeePerSecondPerPfc,
        address _timerAddress
    )
        Store(_fixedOracleFeePerSecondPerPfc, _weeklyDelayFeePerSecondPerPfc, _timerAddress)
    {}
}
