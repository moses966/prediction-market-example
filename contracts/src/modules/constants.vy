# pragma version ^0.4.0

# <<OracleInterfaces>>
# Stores common interface names used throughout the DVM by registration in the Finder.
Oracle: constant(Bytes[6]) = b"Oracle"
IdentifierWhitelist: constant(Bytes[19]) = b"IdentifierWhitelist"
Store: constant(Bytes[5]) = b"Store"
FinancialContractsAdmin: constant(Bytes[23]) = b"FinancialContractsAdmin"
Registry: constant(Bytes[8]) = b"Registry"
CollateralWhitelist: constant(Bytes[19]) = b"CollateralWhitelist"
OptimisticOracle: constant(Bytes[16]) = b"OptimisticOracle"
OptimisticOracleV2: constant(Bytes[18]) = b"OptimisticOracleV2"
OptimisticOracleV3: constant(Bytes[18]) = b"OptimisticOracleV3"
Bridge: constant(Bytes[6]) = b"Bridge"
GenericHandler: constant(Bytes[14]) = b"GenericHandler"
SkinnyOptimisticOracle: constant(Bytes[22]) = b"SkinnyOptimisticOracle"
ChildMessenger: constant(Bytes[14]) = b"ChildMessenger"
OracleHub: constant(Bytes[9]) = b"OracleHub"
OracleSpoke: constant(Bytes[11]) = b"OracleSpoke"


# <<OptimisticOracleConstraints(commonly re-used values for contracts associated with the OptimisticOracle)>>
# Any price request submitted to the OptimisticOracle must contain ancillary data no larger than this value.
# This value must be <= the Voting contract's `ancillaryBytesLimit` constant value otherwise it is possible
# that a price can be requested to the OptimisticOracle successfully, but cannot be resolved by the DVM which
# refuses to accept a price request made with ancillary data length over a certain size.
ancillaryBytesLimit: constant(uint256) = 8192

# Roles
MINT_ROLE: public(constant(bytes32)) = keccak256("MINT_ROLE")
BURN_ROLE: public(constant(bytes32)) = keccak256("BURN_ROLE")
MANAGER_ROLE: public(constant(bytes32)) = keccak256("MANAGER_ROLE")