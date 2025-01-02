// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "contracts/dependencies/contracts/data-verification-mechanism/test/MockOracleAncillary.sol";

contract MockAncillaryContract is MockOracleAncillary {

    constructor(
        address _finderAddress,
        address _timerAddress
    )
        MockOracleAncillary(_finderAddress, _timerAddress)
    {}
}
