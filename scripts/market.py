import os
from ape import accounts, project, chain
from hexbytes import HexBytes
from scripts.utils import edit_value, get_value
from scripts import constants


class PredictionMarketManager:
    def __init__(self):
        self.deployer = accounts.load("account1")
        self.user = accounts.load("account2")
        self.asserter_wallet = accounts.load("account3")
        self.finder = get_value("finder_address")
        self.oov3 = get_value("OOV3_address")
        self.currency = get_value("currency_address")
        self.ancillary = get_value("ancillary_data_address")
        self.address_whitelist = get_value("address_whitelist")

    def _allocate_and_approve_tokens(self, wallet, amount):
        """Allocate and approve tokens for the wallet."""
        _address = get_value("market_address")
        token = project.TestERC20.at(self.currency, fetch_from_explorer=False)
        token.allocateTo(wallet, amount, sender=wallet)
        token.approve(_address, amount, sender=wallet)

    def get_addresses(self):
        """Retrieve and print addresses."""
        oov3_address = project.FinderContract.at(self.finder, fetch_from_explorer=False).getImplementationAddress(
            constants.OptimisticOracleV3,
            sender=self.deployer
        )
        default_currency = project.OOV3.at(self.oov3, fetch_from_explorer=False).defaultCurrency()
        print(f"OptimisticOracleV3 address: {oov3_address}")
        print(f"Currency: {default_currency}")

    def deploy_prediction_market(self):
        """Deploy the prediction market contract."""

        # deploy expanded token blueprint
        expanded_token_blueprint = self.deployer.declare(
            project.ExpandedERC20,
            "Expanded Token",
            "EXT",
            18
        )
        edit_value("expanded_token_blueprint_address", expanded_token_blueprint.contract_address)

        # deploy outcome token factory
        outcome_token_factory = self.deployer.deploy(
            project.OutComeTokenFactory,
            expanded_token_blueprint.contract_address
        )
        edit_value("outcome_token_factory_address", outcome_token_factory.address)

        # deploy the prediction market
        contract = self.deployer.deploy(
            project.Experiment,
            self.finder,
            self.address_whitelist,
            self.oov3,
            self.ancillary,
            self.currency,
            outcome_token_factory.address
            
        )
        edit_value("market_address", contract.address)
        print(f"Market deployed at: {contract.address}")

        # whitelist market contract
        outcome_token_factory.whitelist(contract.address, sender=self.deployer)


    def init_market(self):
        """Initialize the prediction market."""
    
        # Load the deployed contract
        _address = get_value("market_address")
        
        # Mint and approve tokens for the market
        self._allocate_and_approve_tokens(self.deployer, constants.reward)
        token = project.TestERC20.at(self.currency, fetch_from_explorer=False)
        print(f"Deployer Balance before market Initialization: {contract_balance}")

        pred_market = project.Experiment.at(_address, fetch_from_explorer=False)
    
        # Call the initialize_market function
        receipt = pred_market.initialize_market(
            constants.outcome_one,
            constants.outcome_two,
            constants.description,
            constants.reward,
            constants.required_bond,
            sender=self.deployer
        )
        
        contract_balance = token.balanceOf(_address)
        print(f"Deployer Balance after market Initialization: {contract_balance}")
    
        # Decode logs to find the MarketInitialized event
        decoded_logs = receipt.decode_logs()
        for log in decoded_logs:
            if log.event_name == "MarketInitialized":
                # extract the market_id
                _market_id = log.market_id.hex()
                edit_value("market_id", _market_id)

                # extract the outcome token addresses
                outcome_token_one = log.outcome1_token
                edit_value("outcome1_token_address", outcome_token_one)
                outcome_token_two = log.outcome2_token
                edit_value("outcome2_token_address", outcome_token_two)
                break

    def create_outcome_tokens(self):
        """Create the outcome tokens."""

        _address = get_value("market_address")
        _id = get_value("market_id")
        _market_id = HexBytes(_id)

        # Mint and approve currency tokens for use
        token = project.TestERC20.at(self.currency, fetch_from_explorer=False)
        self._allocate_and_approve_tokens(self.deployer, constants.amount)
        balance = token.balanceOf(self.deployer)
        print(f"Deployer's currency balance before creating outcome tokens: {balance / 1e18}")

        pred_market = project.Experiment.at(_address, fetch_from_explorer=False)
        print("Market Struct: ", pred_market.markets(_market_id)) # visually confirm market was initialized.

        pred_market.create_outcome_tokens(_market_id, constants.amount, sender=self.deployer)
        balance = token.balanceOf(self.deployer)
        print(f"Deployer's currency balance after creating outcome tokens: {balance / 1e18}")

        outcome_token_one = get_value("outcome1_token_address")
        outcome_token_two = get_value("outcome2_token_address")
        token_one = project.ExpandedERC20.at(outcome_token_one, fetch_from_explorer=False)
        token_two = project.ExpandedERC20.at(outcome_token_two, fetch_from_explorer=False)
        
        # With an amount 10,000 units of default_currency we get 10,000 outcome1_token and 10,000 outcome2_token tokens
        balance_one = token_one.balanceOf(self.deployer)
        balance_two = token_two.balanceOf(self.deployer)
        print(f"Outcome token 1 balance: {balance_one / 1e18}")
        print(f"Outcome token 2 balance: {balance_two / 1e18}")
    
    def redeem_outcome_tokens(self):
        """
        At any point before the market is settled we can redeem outcome tokens. 
        By redeeming an amount we are burning the same amount of outcome_token_one 
        and outcome_token_two to receive that amount of default_currency(currency).
        """
        _id = get_value("market_id")
        _market_id = HexBytes(_id)
        _address = get_value("market_address")
        outcome_token_one = get_value("outcome1_token_address")
        outcome_token_two = get_value("outcome2_token_address")

        pred_market = project.Experiment.at(_address, fetch_from_explorer=False)
        pred_market.redeem_outcome_tokens(_market_id, constants.redeem_amount, sender=self.deployer)

        # After redeeming 5,000 tokens we can see how both balances of outcome_token_one 
        # and outcome_token_two have decreased by 5,000 and default_currency(currency) has increased that same amount.
        token_one = project.ExpandedERC20.at(outcome_token_one, fetch_from_explorer=False)
        token_two = project.ExpandedERC20.at(outcome_token_two, fetch_from_explorer=False)
        token = project.TestERC20.at(self.currency, fetch_from_explorer=False)

        balance_one = token_one.balanceOf(self.deployer)
        balance_two = token_two.balanceOf(self.deployer)
        balance = token.balanceOf(self.deployer)
        print(f"Outcome token 1 balance: {balance_one / 1e18}")
        print(f"Outcome token 2 balance: {balance_two / 1e18}")
        print(f"Deployer's currency balance after redeeming tokens: {balance / 1e18}")

    def simulate_trade(self):
        """
        Transfer the remaining 5,000 outcome_token_one tokens to another(user) account.
        """
        outcome_token_one = get_value("outcome1_token_address")

        token_one = project.ExpandedERC20.at(outcome_token_one, fetch_from_explorer=False)
        token_one.transfer(self.user, constants.transfer_amount, sender=self.deployer)
        balance_one = token_one.balanceOf(self.user)
        print(f"User's outcome token 1 balance: {balance_one / 1e18}")

    def assert_market(self):
        """
        Assert the market state.
        """
        _id = get_value("market_id")
        _market_id = HexBytes(_id)
        _address = get_value("market_address")

        # Mint and approve currency tokens for the asserter
        token = project.TestERC20.at(self.currency, fetch_from_explorer=False)
        self._allocate_and_approve_tokens(self.asserter_wallet, constants.required_bond)
        balance = token.balanceOf(self.asserter_wallet)
        print(f"Asserter's balance before market assertion: {balance / 1e18}")

        pred_market = project.Experiment.at(_address, fetch_from_explorer=False)
        receipt = pred_market.assert_market(_market_id, constants.outcome_one, sender=self.asserter_wallet) # assert market

        balance = token.balanceOf(self.asserter_wallet)
        print(f"Asserter's balance after market assertion: {balance / 1e18}")

        _id = receipt.return_value
        edit_value("assertion_id", _id.hex())

    def settle_assertion(self):
        """
        Settle assertion in OOV3
        """
        chain.pending_timestamp += constants.duration # increase timestamp by 2 hours

        _id = HexBytes(get_value("assertion_id"))
        assertion = project.OOV3.at(self.oov3, fetch_from_explorer=False)

        assertion.settleAssertion(_id, sender=self.deployer)

        # Print the assertion state
        print(f"Assertion State: {assertion.assertions(_id)}")

        currency = project.TestERC20.at(self.currency, fetch_from_explorer=False)
        balance = currency.balanceOf(self.asserter_wallet)
        print(f"Asserter's balance after settling assertion: {balance / 1e18}")

    def settle_outcome_tokens(self):
        """
        Settle Outcome Tokens
        """
        pred_market = project.Experiment.at(get_value("market_address"), fetch_from_explorer=False)
       
        pred_market.settle_outcome_tokens(HexBytes(get_value("market_id")), sender=self.deployer)
        pred_market.settle_outcome_tokens(HexBytes(get_value("market_id")), sender=self.user)
        
    def display_all_final_token_balances(self):
        """
        Get final balances for outcome tokens and default currency for all wallets.
        """
        outcome1_token = project.ExpandedERC20.at(get_value("outcome1_token_address"), fetch_from_explorer=False)
        outcome2_token = project.ExpandedERC20.at(get_value("outcome2_token_address"), fetch_from_explorer=False)
        currency = project.TestERC20.at(self.currency, fetch_from_explorer=False)

        print(f"DEPLOYER WALLET BALANCE OUTCOME TOKEN ONE: {outcome1_token.balanceOf(self.deployer) / 1e18}")
        print(f"DEPLOYER WALLET BALANCE OUTCOME TOKEN TWO: {outcome2_token.balanceOf(self.deployer) / 1e18}")
        print(f"DEPLOYER WALLET BALANCE DEFAULT CURRENCY: {currency.balanceOf(self.deployer) / 1e18}")
        print(f"USER BALANCE OUTCOME TOKEN ONE: {outcome1_token.balanceOf(self.user) / 1e18}")
        print(f"USER BALANCE OUTCOME TOKEN TWO: {outcome2_token.balanceOf(self.user) / 1e18}")
        print(f"USER BALANCE DEFAULT CURRENCY: {currency.balanceOf(self.user) / 1e18}")
    
def main():
    method_flag = os.getenv("APE_METHOD") # get method flag from environment variable
    manager = PredictionMarketManager()

    if method_flag == 'get_addresses':
        manager.get_addresses()
    elif method_flag == 'deploy_market':
        manager.deploy_prediction_market()
    elif method_flag == 'init':
        manager.init_market()
    elif method_flag == 'create':
        manager.create_outcome_tokens()
    elif method_flag == 'redeem':
        manager.redeem_outcome_tokens()
    elif method_flag == 'trade':
        manager.simulate_trade()
    elif method_flag == 'assert':
        manager.assert_market()
    elif method_flag == 'settle_assertion':
        manager.settle_assertion()
    elif method_flag == 'settle_tokens':
        manager.settle_outcome_tokens()
    elif method_flag == 'balances':
        manager.display_all_final_token_balances()
    else:
        print("Invalid method string.")

if __name__ == "__main__":
    main()
