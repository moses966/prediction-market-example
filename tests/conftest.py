import pytest
from scripts import constants


@pytest.fixture(scope="session")
def deployer(accounts):
    yield accounts[0]

@pytest.fixture(scope="session")
def user_wallet(accounts):
    yield accounts[1]

@pytest.fixture(scope="session")
def asserter_wallet(accounts):
    yield accounts[2]


@pytest.fixture(scope="session")
def store_contract(project, deployer):
    """Fixture to deploy the StoreContract."""
    yield deployer.deploy(
        project.StoreContract,
        constants.fixed_oracle_fee,
        constants.weekly_delay_fee,
        constants.empty_address,
    )

@pytest.fixture(scope="session")
def ancillary_data_contract(project, deployer):
    """Fixture to deploy the AncillaryDataInterface."""
    yield deployer.deploy(project.AncillaryDataInterface)

@pytest.fixture(scope="session")
def finder_contract(project, deployer):
    """Fixture to deploy the FinderContract."""
    yield deployer.deploy(project.FinderContract)

@pytest.fixture(scope="session")
def mock_oracle_ancillary_contract(project, deployer, finder_contract):
    """Fixture to deploy the MockAncillaryContract."""
    yield deployer.deploy(
        project.MockAncillaryContract,
        finder_contract.address,
        constants.empty_address,
    )

@pytest.fixture(scope="session")
def address_whitelist_contract(project, deployer):
    """Fixture to deploy the AddressWhitelistContract."""
    yield deployer.deploy(project.AddressWhitelistContract)

@pytest.fixture(scope="session")
def identifier_whitelist_contract(project, deployer):
    """Fixture to deploy the IdentifierWhitelistContract."""
    yield deployer.deploy(project.IdentifierWhitelistContract)

@pytest.fixture(scope="session")
def currency(project, deployer):
    yield deployer.deploy(
        project.TestERC20,
        "Test ERC20",
        "TT",
        18
    )

@pytest.fixture(scope="session")
def register_contracts(
    deployer,
    finder_contract,
    address_whitelist_contract,
    identifier_whitelist_contract,
    store_contract,
    mock_oracle_ancillary_contract,
    currency
):
    finder_contract.changeImplementationAddress(constants.Store, store_contract.address, sender=deployer)
    finder_contract.changeImplementationAddress(
        constants.CollateralWhitelist,
        address_whitelist_contract.address,
        sender=deployer
    )
    finder_contract.changeImplementationAddress(
        constants.Oracle,
        mock_oracle_ancillary_contract.address,
        sender=deployer,
    )
    address_whitelist_contract.addToWhitelist(
        currency.address,
        sender=deployer,
    )
    identifier_whitelist_contract.addSupportedIdentifier(
        constants.default_identifier,
        sender=deployer,
    )
    final_fee = {"rawValue": int(constants.minimum_bond / 2)}
    store_contract.setFinalFee(
        currency.address,
        final_fee,
        sender=deployer,
    )


@pytest.fixture(scope="session")
def optimistic_oracle_v3(project, deployer, finder_contract, currency):
    """Fixture to deploy Optimistic Oracle V3."""
    oov3 = deployer.deploy(
        project.OOV3,
        finder_contract.address,
        currency.address,
        7200,
    )
    finder_contract.changeImplementationAddress(
        constants.OptimisticOracleV3,
        oov3.address,
        sender=deployer
    )
    yield oov3

@pytest.fixture(scope="session")
def expanded_token_blueprint(project, deployer):
    yield deployer.declare(
        project.ExpandedERC20,
        "Expanded Token",
         "EXT",
        18
    )
    
@pytest.fixture(scope="session")
def factory(project, deployer):
    yield deployer.deploy(
        project.OutComeTokenFactory,
        expanded_token_blueprint.contract_address
    )
@pytest.fixture(scope="session")
def deploy_market_contract(
    project,
    deployer,
    currency,
    factory,
    finder_contract,
    address_whitelist_contract,
    optimistic_oracle_v3,
    ancillary_data_contract
    ):
    mrk = deployer.deploy(
        project.PredictionMarket,
        finder_contract.address,
        address_whitelist_contract.address,
        optimistic_oracle_v3.address,
        ancillary_data_contract.address,
        currency.address,
        factory.address
    )
    factory.whitelist(mrk.address, sender=deployer)
    yield mrk