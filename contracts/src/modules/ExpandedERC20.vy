# pragma version ^0.4.0

"""
@title ExpandedERC20
@author Muwawu Moses
@notice Creates ERC20 contracts with extended minter and burner roles.
"""

from snekmate.auth import access_control as ctl
from contracts.src.modules import constants
import ERC20 as erc20
from .interfaces import ExpandedIERC20

implements: ExpandedIERC20

initializes: ctl
initializes: erc20
exports: (
    ctl.__interface__,
    erc20.__interface__
)



@deploy
@payable
def __init__(
    _name: String[15],
    _symbol: String[5],
    _decimals: uint8
):
    """
    @notice Constructs the ExpandedERC20.
    """
    erc20.__init__(_name, _symbol, _decimals)
    ctl.__init__()
    
    # set 'admin_role' as "role's" admin role
    ctl._set_role_admin(constants.MINT_ROLE, constants.MANAGER_ROLE)
    ctl._set_role_admin(constants.BURN_ROLE, constants.MANAGER_ROLE)

    # set role admin
    ctl._grant_role(constants.MANAGER_ROLE, msg.sender)

@external
def mint(_recipient: address, _value: uint256):
    """
    @dev Mints `_value` tokens to `_recipient`, returning true on success.
    @param _recipient address to mint to.
    @param _value amount of tokens to mint.
    """
    ctl._check_role(constants.MINT_ROLE, msg.sender)
    erc20._mint(_recipient, _value)
    
@external
def burn(_value: uint256):
    """
    @dev Burns `_value` tokens owned by `msg.sender`.
    @param _value amount of tokens to burn.
    """
    ctl._check_role(constants.BURN_ROLE, msg.sender)
    erc20._burn(msg.sender, _value)

@external
def burn_from(_recipient: address, amount: uint256):
    """
    @dev Destroys `amount` tokens from `owner`,
         deducting from the caller's allowance.
    @notice Note that `msg.sender` must have
        `BURN_ROLE`.
    @param _recipient address to burn tokens from.
    @param amount The 32-byte token amount to be destroyed.
    """
    ctl._check_role(constants.BURN_ROLE, msg.sender)
    erc20._burn(_recipient, amount)

@external
def add_minter(_account: address):
    """
    @notice Grant Minter Role to an account.
    @dev The caller must have the `MANAGER_ROLE` role.
    @param _account The address to which the Minter role is added.
    """
    ctl._check_role(constants.MANAGER_ROLE, msg.sender)
    ctl._grant_role(constants.MINT_ROLE, _account)
    
@external
def add_burner(account: address):
    """
    @notice Grant Burner role to account.
    @dev The caller must have the `MANAGER_ROLE` role.
    @param account The address to which the Burner role is added.
    """
    ctl._check_role(constants.MANAGER_ROLE, msg.sender)
    ctl._grant_role(constants.BURN_ROLE, account)