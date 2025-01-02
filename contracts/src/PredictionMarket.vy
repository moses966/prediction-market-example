# pragma version ^0.4.0

"""
@notice This contract allows to initialize prediction markets each having a pair of binary outcome tokens. Anyone can mint
    and burn the same amount of paired outcome tokens for the default payout currency. Trading of outcome tokens is
    outside the scope of this contract. Anyone can assert 3 possible outcomes (outcome 1, outcome 2 or split) that is
    verified through Optimistic Oracle V3. If the assertion is resolved true then holders of outcome tokens can settle
    them for the payout currency based on resolved market outcome.
"""
# Importing modules
from contracts.src.modules import constants

# Importing Defined Interfaces
from contracts.src.modules.interfaces import IERC20
from contracts.src.modules.interfaces import ExpandedIERC20
from contracts.src.modules.interfaces import FinderInterface
from contracts.src.modules.interfaces import IAddressWhitelist
from contracts.src.modules.interfaces import IAncillaryDataInterface
from contracts.src.modules.interfaces import IOptimisticOracleV3
from contracts.src.modules.interfaces import IOptimisticOracleV3CallbackRecipient

# Initialization
initializes: constants

# Exportation
exports: constants.__interface__

# Events
event MarketInitialized:
    market_id: bytes32
    outcome1: String[16]
    outcome2: String[16]
    description: String[720]
    outcome1_token: address
    outcome2_token: address
    reward: uint256
    required_bond: uint256

event MarketAsserted:
    market_id: bytes32
    asserted_outcome: String[16]
    assertion_id: bytes32

event MarketResolved:
    market_id: bytes32

event TokensCreated:
    market_id: bytes32
    account: address
    tokens_created: uint256

event TokensRedeemed:
    market_id: bytes32
    account: address
    tokens_redeemed: uint256

event TokensSettled:
    market_id: bytes32
    account: address
    payout: uint256
    outcome1_tokens: uint256
    outcome2_tokens: uint256

# Define structs
struct Market:
    resolved: bool  # True if the market has been resolved and payouts can be settled.
    asserted_outcome_id: bytes32  # Hash of asserted outcome (outcome1, outcome2, or unresolvable).
    outcome1_token: address  # Address of ERC20 token representing the value of the first outcome.
    outcome2_token: address  # Address of ERC20 token representing the value of the second outcome.
    reward: uint256  # Reward available for asserting true market outcome.
    required_bond: uint256  # Expected bond to assert market outcome.
    outcome1: Bytes[16]  # Short name of the first outcome.
    outcome2: Bytes[16]  # Short name of the second outcome.
    description: Bytes[720]  # Description of the market.

struct AssertedMarket:
    asserter: address  # Address of the asserter used for reward payout.
    market_id: bytes32  # Identifier for markets mapping.

# State variables
finder_instance: FinderInterface # UMA protocol Finder contract
whitelist_instance: IAddressWhitelist
ancillary_data_instance: IAncillaryDataInterface
OOv3_instance: immutable(IOptimisticOracleV3) # Optimistic Oracle V3 interface
OOv3_callback_instance: IOptimisticOracleV3CallbackRecipient
markets: public(HashMap[bytes32, Market])
asserted_markets: public(HashMap[bytes32, AssertedMarket])
currency: public(immutable(IERC20))  # Currency used for all prediction markets
assertion_liveness: constant(uint64) = 7200  # 2 hours
default_identifier: immutable(bytes32)  # Default identifier for prediction markets
unresolvable: constant(Bytes[16]) = b"Unresolvable"
outcome_token_factory: immutable(address)

interface OutComeTokenFactory:
    def deploy_outcome_token(_name: String[22], _symbol: String[5], _decimals: uint8) -> address: nonpayable


@deploy
@payable
def __init__(
    _finder: address,
    _address_whitelist: address,
    _oov3: address,
    _ancillary: address,
    _currency: address,
    _outcome_token_factory: address
):
   """
   @param _finder Finder address
   @param _address_whitelist address for the AddressWhitelist contract.
   @param _oov3 OptimisticOracleV3 contract address
   @param _ancillary contract address for the deployed AncillaryDataInterface
   @param _currency Whitelisted token address
    @param _outcome_token_factory OutcomeTokenFactory contract address
   """
   self.finder_instance = FinderInterface(_finder)
   self.whitelist_instance = IAddressWhitelist(_address_whitelist)
   OOv3_instance = IOptimisticOracleV3(_oov3)
   self.ancillary_data_instance = IAncillaryDataInterface(_ancillary)

   self._confirm_collateral_whitelist(_currency)
   currency = IERC20(_currency)
   outcome_token_factory = _outcome_token_factory

   default_identifier = staticcall OOv3_instance.defaultIdentifier()

#############################################
#              External Functions           #
##############################################

@view
@external
def get_market(market_id: bytes32) -> Market:
    return self.markets[market_id]

@external
def initialize_market(
    outcome1: String[16], # Short name of the first outcome.
    outcome2: String[16], # Short name of the second outcome.
    description: String[720], # Description of the market(Limited to only Bytes[720]).
    reward: uint256, # Reward available for asserting true market outcome.
    required_bond: uint256 # Expected bond to assert market outcome (OOv3 can require higher bond).
):
    assert len(outcome1) > 0, "Empty First Outcome"
    assert len(outcome2) > 0, "Empty Second Outcome"
    assert keccak256(outcome1) != keccak256(outcome2), "Outcomes are the same"
    assert len(description) > 0, "Empty Description"
    market_id: bytes32 = keccak256(abi_encode(block.number, description))
    assert self.markets[market_id].outcome1_token == empty(address), "Market already exists."
    # assert reward > 0, "Low reward amount."

    # Create position tokens with this contract having minter and burner roles.
    _decimals: uint8 = 18
    outcome1_token_address: address = extcall OutComeTokenFactory(outcome_token_factory).deploy_outcome_token(
        concat(outcome1, " Token"),
        "O1T",
        _decimals
    )
    assert outcome1_token_address != empty(address), "Outcome1 token creation failed"
    outcome2_token_address: address = extcall OutComeTokenFactory(outcome_token_factory).deploy_outcome_token(
        concat(outcome2, " Token"),
        "O2T",
        _decimals
    )
    assert outcome2_token_address != empty(address), "Outcome2 token creation failed"

    extcall ExpandedIERC20(outcome1_token_address).add_minter(self)
    extcall ExpandedIERC20(outcome2_token_address).add_minter(self)
    extcall ExpandedIERC20(outcome1_token_address).add_burner(self)
    extcall ExpandedIERC20(outcome2_token_address).add_burner(self)

    self.markets[market_id] = Market(
        resolved=False,
        asserted_outcome_id=empty(bytes32),
        outcome1_token=outcome1_token_address,
        outcome2_token=outcome2_token_address,
        reward=reward,
        required_bond=required_bond,
        outcome1=convert(outcome1, Bytes[16]),
        outcome2=convert(outcome2, Bytes[16]),
        description=convert(description, Bytes[720])
    )
    if reward > 0:
        extcall currency.transferFrom(msg.sender, self, reward, default_return_value=True) # Pull Reward.
    
    log MarketInitialized(
            market_id,
            outcome1,
            outcome2,
            description,
            outcome1_token_address,
            outcome2_token_address,
            reward,
            required_bond
        )

@external
def assert_market(market_id: bytes32, asserted_outcome: String[16]) -> bytes32:
    """
    @notice Assert the market with any of 3 possible outcomes: names of outcome1, outcome2 or unresolvable.
    """
    market: Market = self.markets[market_id]
    assert market.outcome1_token != empty(address), "Market does not exist"
    _asserted_outcome_id: bytes32 = keccak256(convert(asserted_outcome, Bytes[16]))
    assert market.asserted_outcome_id == empty(bytes32), "Assertion active or resolved"
    assert (
        _asserted_outcome_id == keccak256(market.outcome1) or
        _asserted_outcome_id == keccak256(market.outcome2) or
        _asserted_outcome_id == keccak256(unresolvable)
    ), "Invalid asserted Outcome"

    
    market.asserted_outcome_id = _asserted_outcome_id
    minimum_bond: uint256 = staticcall OOv3_instance.getMinimumBond(currency.address)
    bond: uint256 = market.required_bond
    if market.required_bond <= minimum_bond:
        bond = minimum_bond

    claim: Bytes[920] = self._compose_claim(asserted_outcome, market.description)

    # Pull bond and make the assertion.
    extcall currency.transferFrom(msg.sender, self, bond, default_return_value=True)
    extcall currency.approve(OOv3_instance.address, bond, default_return_value=True)
    assertion_id: bytes32 = self._assert_truth_with_defaults(claim, bond)

    # Store the asserter and marketId for the assertionResolvedCallback.
    self.asserted_markets[assertion_id] = AssertedMarket(asserter=msg.sender, market_id=market_id)

    # update markets
    self.markets[market_id] = market

    log MarketAsserted(market_id, asserted_outcome, assertion_id)

    return assertion_id

@external
def assertionResolvedCallback(assertion_id: bytes32, asserted_truthfully: bool):
    """
    @notice Callback from settled assertion.
        If the assertion was resolved true, then the asserter gets the reward and the market is marked as resolved.
        Otherwise, asserted_outcome_id is reset and the market can be asserted again.
    """
    assert msg.sender == OOv3_instance.address, "Not authorized"
    _market_id: bytes32 = self.asserted_markets[assertion_id].market_id
    market: Market = self.markets[_market_id]
    if asserted_truthfully:
        market.resolved = True
        self.markets[_market_id] = market
        if market.reward > 0 :
            extcall currency.transfer(
                self.asserted_markets[assertion_id].asserter,
                market.reward,
                default_return_value=True
            )
        log MarketResolved(self.asserted_markets[assertion_id].market_id)
    else:
        market.asserted_outcome_id = empty(bytes32)
        self.markets[_market_id] = market
    self.asserted_markets[assertion_id] = empty(AssertedMarket) # delete record

@external
def assertionDisputedCallback(assertionId: bytes32):
    pass

@external
def create_outcome_tokens(market_id: bytes32, tokens_to_create: uint256):
    """
    @notice Mints pair of tokens representing the value of outcome1 and outcome2. Trading of outcome tokens is outside of the
        scope of this contract. The caller must approve this contract to spend the currency tokens.
    """
    market: Market = self.markets[market_id]
    ot1: address = market.outcome1_token
    ot2: address = market.outcome2_token
    assert ot1 != empty(address), "Market does not exist"

    extcall currency.transferFrom(msg.sender, self, tokens_to_create, default_return_value=True)
    
    extcall ExpandedIERC20(ot1).mint(msg.sender, tokens_to_create)
    extcall ExpandedIERC20(ot2).mint(msg.sender, tokens_to_create)
    log TokensCreated(market_id, msg.sender, tokens_to_create)

@external
def redeem_outcome_tokens(market_id: bytes32, tokens_to_redeem: uint256):
    """
    @notice Burns equal amount of outcome1 and outcome2 tokens returning settlement currency tokens.
    """
    market: Market = self.markets[market_id]
    assert market.outcome1_token != empty(address), "Market does not exist"

    extcall ExpandedIERC20(market.outcome1_token).burn_from(msg.sender, tokens_to_redeem)
    extcall ExpandedIERC20(market.outcome2_token).burn_from(msg.sender, tokens_to_redeem)

    extcall currency.transfer(msg.sender, tokens_to_redeem, default_return_value=True)

    log TokensRedeemed(market_id, msg.sender, tokens_to_redeem)

@external
def settle_outcome_tokens(market_id: bytes32) -> uint256:
    """
    @notice If the market is resolved, then all of caller's outcome tokens are burned and currency payout is made depending
        on the resolved market outcome and the amount of outcome tokens burned. If the market was resolved to the first
        outcome, then the payout equals balance of outcome1_token while outcome2_token provides nothing. If the market was
        resolved to the second outcome, then the payout equals balance of outcome2_token while outcome1_token provides
        nothing. If the market was resolved to the split outcome, then both outcome tokens provides half of their balance
        as currency payout.
    """
    market: Market = self.markets[market_id]
    assert market.resolved, "Market not resolved"

    outcome1_balance: uint256 = staticcall ExpandedIERC20(market.outcome1_token).balanceOf(msg.sender)
    outcome2_balance: uint256 = staticcall ExpandedIERC20(market.outcome2_token).balanceOf(msg.sender)
    payout: uint256 = 0
    
    if market.asserted_outcome_id == keccak256(market.outcome1):
        payout = outcome1_balance
    elif market.asserted_outcome_id == keccak256(market.outcome2):
        payout = outcome2_balance
    else:
        payout = (outcome1_balance + outcome2_balance) // 2

    extcall ExpandedIERC20(market.outcome1_token).burn_from(msg.sender, outcome1_balance)
    extcall ExpandedIERC20(market.outcome2_token).burn_from(msg.sender, outcome2_balance)
    extcall currency.transfer(msg.sender, payout, default_return_value=True)

    log TokensSettled(market_id, msg.sender, payout, outcome1_balance, outcome2_balance)

    return payout
        
#############################################
#              Internal Functions           #
##############################################

@view
@internal
def _confirm_collateral_whitelist(_addr: address):
    _address: address = staticcall self.finder_instance.getImplementationAddress(
        convert(
            constants.CollateralWhitelist,
            bytes32
        )
    )
    assert staticcall self.whitelist_instance.isOnWhitelist(_addr), "Unsupported Currency!"

@internal
def _compose_claim(outcome: String[16], description: Bytes[720]) -> Bytes[920]:
    return concat(
        b"As of assertion timestamp ",
        extcall self.ancillary_data_instance.toUtf8BytesUint(block.timestamp),
        b", the described prediction market outcome is: ",
        convert(outcome, Bytes[16]),
        b". The market description is: ",
        description
    )

@internal
def _assert_truth_with_defaults(_claim: Bytes[920], bond: uint256) -> bytes32:
    assertion_id: bytes32 = extcall OOv3_instance.assertTruth(
        _claim,
        msg.sender, # asserter
        self, # Receive callback in this contract.
        empty(address), # No sovereign security.
        assertion_liveness,
        currency.address,
        bond,
        default_identifier,
        empty(bytes32) # No bond
    )
    return assertion_id