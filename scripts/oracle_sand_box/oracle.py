from ape import accounts, project
from .. import constants
from ..utils import edit_value


class OracleContracts:
    def __init__(self):
        # Contract addresses
        self.finder = ""
        self.store = ""
        self.identifier_whitelist_address = ""
        self.mock = ""
        self.whitelist = ""
        self.default_currency = ""

    def deploy_contracts(self):
        deployer = accounts.load("account1")  # Load deployer account

        # Deploy StoreContract
        store_contract = deployer.deploy(
            project.StoreContract,
            constants.fixed_oracle_fee,
            constants.weekly_delay_fee,
            constants.empty_address,
        )
        edit_value("store_contract_address", store_contract.address)
        self.store = store_contract.address

        # Deploy AncillaryDataInterface
        ancillary_data_contract = deployer.deploy(project.AncillaryDataInterface)
        edit_value("ancillary_data_address", ancillary_data_contract.address)

        # Deploy FinderContract
        finder_contract = deployer.deploy(project.FinderContract)
        edit_value("finder_address", finder_contract.address)
        self.finder = finder_contract.address

        # Deploy MockAncillaryContract
        mock_oracle_ancillary_contract = deployer.deploy(
            project.MockAncillaryContract,
            finder_contract.address,
            constants.empty_address,
        )
        edit_value("mock_oracle_address", mock_oracle_ancillary_contract.address)
        self.mock = mock_oracle_ancillary_contract.address

        # Deploy DefaultCurrency token contract
        default_currency_contract = deployer.deploy(
            project.TestERC20,
            constants.default_currency_name,
            constants.default_currency_symbol,
            constants.default_currency_decimal
        )
        edit_value("currency_address", default_currency_contract.address)
        self.default_currency = default_currency_contract.address

        # Deploy AddressWhitelistContract
        address_whitelist_contract = deployer.deploy(project.AddressWhitelistContract)
        edit_value("address_whitelist", address_whitelist_contract.address)
        self.whitelist = address_whitelist_contract.address

        # Deploy IdentifierWhitelistContract
        identifier_contract = deployer.deploy(project.IdentifierWhitelistContract)
        edit_value("identifier_address", identifier_contract.address)
        self.identifier_whitelist_address = identifier_contract.address

    def register_contracts(self):
        deployer = accounts.load("account1")

        # Link contracts through FinderContract
        project.FinderContract.at(self.finder, fetch_from_explorer=False).changeImplementationAddress(
            constants.Store,
            self.store,
            sender=deployer,
        )
        print("Store contract address: ", self.store)
        print("Finder contract address: ", self.finder)

        project.FinderContract.at(self.finder, fetch_from_explorer=False).changeImplementationAddress(
            constants.CollateralWhitelist,
            self.whitelist,
            sender=deployer,
        )
        project.FinderContract.at(self.finder, fetch_from_explorer=False).changeImplementationAddress(
            constants.IdentifierWhitelist,
            self.identifier_whitelist_address,
            sender=deployer,
        )
        project.FinderContract.at(self.finder, fetch_from_explorer=False).changeImplementationAddress(
            constants.Oracle,
            self.mock,
            sender=deployer,
        )

        # Update AddressWhitelistContract
        project.AddressWhitelistContract.at(self.whitelist, fetch_from_explorer=False).addToWhitelist(
            self.default_currency,
            sender=deployer,
        )

        # Update IdentifierWhitelistContract
        project.IdentifierWhitelistContract.at(self.identifier_whitelist_address, fetch_from_explorer=False).addSupportedIdentifier(
            constants.default_identifier,
            sender=deployer,
        )

        # Update StoreContract
        final_fee = {"rawValue": int(constants.minimum_bond / 2)}
        project.Store.at(self.store, fetch_from_explorer=False).setFinalFee(
            self.default_currency,
            final_fee,
            sender=deployer,
        )

    def deploy_and_register_oov3(self):
        deployer = accounts.load("account1")

        optimistic_oracle_contract = deployer.deploy(
            project.OOV3,
            self.finder,
            self.default_currency,
            constants.default_liveness
        )
        edit_value("OOV3_address", optimistic_oracle_contract.address)

        project.FinderContract.at(self.finder, fetch_from_explorer=False).changeImplementationAddress(
            constants.OptimisticOracleV3,
            optimistic_oracle_contract.address,
            sender=deployer
        )