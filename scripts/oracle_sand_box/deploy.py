import os
import sys

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "../../")))

from scripts.oracle_sand_box.oracle import OracleContracts

def main():
    oracle_contracts = OracleContracts()

    # 1. Deploy UMA ecosystem contracts with mocked oracle and selected currency.
    oracle_contracts.deploy_contracts()

    # 2. Register UMA ecosystem contracts, whitelist currency and identifier.
    oracle_contracts.register_contracts()

    # 3. Deploy Optimistic Oracle V3 and register it in the Finder.
    oracle_contracts.deploy_and_register_oov3()

if __name__ == "__main__":
    main()