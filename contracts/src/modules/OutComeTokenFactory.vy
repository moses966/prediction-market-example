# pragma version ^0.4.0

"""
@title OutComeTokenFactory
@author Muwawu Moses
@notice Factory contract to deploy outcome tokens.
"""
from contracts.src.modules import constants
from contracts.src.modules.interfaces import ExpandedIERC20

target: public(immutable(address))
owner: public(immutable(address))
is_whitelisted: public(HashMap[address, bool])


@deploy
@payable
def __init__(_target: address):
    target = _target
    owner = msg.sender

@external
def deploy_outcome_token(
    _name: String[22],
    _symbol: String[5],
    _decimals: uint8
) -> address:
    """
    @notice Generically Deploys a new outcome token.
    @param _name Name of the token.
    @param _symbol Symbol of the token.
    @param _decimals Decimals of the token.
    @return address Address of the deployed token.
    """
    assert self.is_whitelisted[msg.sender], "Only whitelisted addresses can deploy outcome tokens."
    new_contract_address: address = create_from_blueprint(
        target,
        _name,
        _symbol,
        _decimals,
    )
    extcall ExpandedIERC20(new_contract_address).grantRole(
        constants.MANAGER_ROLE,
        msg.sender
    )

    return new_contract_address

@external
def whitelist(_addr: address):
    """
    @notice Whitelist an address.
    @dev The caller must be the owner.
    @param _addr The address to be whitelisted.
    """
    assert msg.sender == owner, "Only the owner can whitelist an address."
    self.is_whitelisted[_addr] = True

@external
def blacklist(_addr: address):
    """
    @notice Blacklist an address.
    @dev The caller must be the owner.
    @param _addr The address to be blacklisted.
    """
    assert msg.sender == owner, "Only the owner can blaclist an address."
    self.is_whitelisted[_addr] = False