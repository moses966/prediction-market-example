

# <<OracleInterfaces>>
# Stores common interface names used throughout the DVM by registration in the Finder.
Oracle = b"Oracle"
IdentifierWhitelist = b"IdentifierWhitelist"
Store = b"Store"
FinancialContractsAdmin = b"FinancialContractsAdmin"
Registry = b"Registry"
CollateralWhitelist = b"CollateralWhitelist"
OptimisticOracle = b"OptimisticOracle"
OptimisticOracleV2 = b"OptimisticOracleV2"
OptimisticOracleV3 = b"OptimisticOracleV3"
Bridge = b"Bridge"
GenericHandler = b"GenericHandler"
SkinnyOptimisticOracle = b"SkinnyOptimisticOracle"
ChildMessenger = b"ChildMessenger"
OracleHub = b"OracleHub"
OracleSpoke = b"OracleSpoke"
ancillaryBytesLimit = 8192

# sandbox parameters
default_identifier = b"ASSERT_TRUTH"
minimum_bond = int(100e18)
default_liveness = int(7200) # 2 hrs
default_currency_name = f"Phage Token"
default_currency_symbol = f"PUSDT"
currency_initial_supply = int(0)
currency_name_eip712 = f"Currency"
currency_version_eip712 = f"1"
default_currency_decimal = int(18)
token_name = f"Outcome Token"
token_symbol = f"OT"
decimals = int(18)
empty_address = f"0x0000000000000000000000000000000000000000"

# Initialize FixedPoint.Unsigned structures with raw values
fixed_oracle_fee = {"rawValue": 0}  # Represents FixedPoint.Unsigned(0)
weekly_delay_fee = {"rawValue": 0}  # Represents FixedPoint.Unsigned(0)


# Market constants
description = f"Manchester United Won the 2025 Champions League Title."
outcome_one = f"YES"
outcome_two = f"NO"
reward = int(100e18)
required_bond = int(5000e18)
amount = int(10000e18)
redeem_amount = int(5000e18)
transfer_amount = int(5000e18)
duration = int(7200)
