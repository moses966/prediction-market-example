#pragma version ^0.4.0

from ethereum.ercs import IERC20
from ethereum.ercs import IERC20Detailed

implements: IERC20
implements: IERC20Detailed


balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)
name: public(String[15])
symbol: public(String[5])
decimals: public(uint8)

@deploy
def __init__(_name: String[15], _symbol: String[5], _decimals: uint8):
    """
    @notice implements ERC20 standard.
    @param _name The name which describes the new token.
    @param _symbol The ticker abbreviation of the name. Ideally < 5 chars.
    @param _decimals The number of decimals to define token precision.
    """
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals

@external
def transfer(_to : address, _value : uint256) -> bool:
    """
    @dev Transfer tokens to a specified address.
    @param _to The address to transfer to.
    @param _value The amount to be transferred.
    @return bool Returns true if the transfer was successful.
    """
    self._transferTokens(msg.sender, _to, _value)
    return True


@external
def transferFrom(owner: address, to: address, amount: uint256) -> bool:
    """
    @dev Moves `amount` tokens from `owner`
         to `to` using the allowance mechanism.
         The `amount` is then deducted from the
         caller's allowance.
    @notice Note that `owner` and `to` cannot
            be the zero address. Also, `owner`
            must have a balance of at least `amount`.
            Eventually, the caller must have allowance
            for `owner`'s tokens of at least `amount`.

            WARNING: The function does not update the
            allowance if the current allowance is the
            maximum `uint256`.
    @param owner The 20-byte owner address.
    @param to The 20-byte receiver address.
    @param amount The 32-byte token amount to be transferred.
    @return bool The verification whether the transfer succeeded
            or failed. Note that the function reverts instead
            of returning `False` on a failure.
    """
    self._spend_allowance(owner, msg.sender, amount)
    self._transferTokens(owner, to, amount)
    return True



@internal
def _transferTokens(src: address, dst: address, amount: uint256):
    """
    @dev Internal function to handle token transfers.
    @param src Source address.
    @param dst Destination address.
    @param amount Amount of tokens to transfer.
    """
    assert src != empty(address), "Token: Can't transfer from empty address"
    assert dst != empty(address), "Token: Cannot transfer to the zero address"

    self._before_token_transfer(src, dst, amount)
    
    src_balance: uint256 = self.balanceOf[src]
    assert src_balance >= amount, "Token: Insufficient balance"
    self.balanceOf[src] -= amount
    self.balanceOf[dst] += amount
    log IERC20.Transfer(src, dst, amount)

    self._after_token_transfer(src, dst, amount)


@external
def approve(_spender : address, _value : uint256) -> bool:
    """
    @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
         Beware that changing an allowance with this method brings the risk that someone may use both the old
         and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
         race condition is the `decreaseAllowance` and `increaseAllowance` methods.
         https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will spend the funds.
    @param _value The amount of tokens to be spent.
    """
    self._approve(msg.sender, _spender, _value)
    return True

@internal
def _approve(owner: address, spender: address, amount: uint256):
    """
    @dev Sets `amount` as the allowance of `spender`
         over the `owner`'s tokens.
    @notice Note that `owner` and `spender` cannot
            be the zero address.
    @param owner The 20-byte owner address.
    @param spender The 20-byte spender address.
    @param amount The 32-byte token amount that is
           allowed to be spent by the `spender`.
    """
    assert owner != empty(address), "Token: approve from the zero address"
    assert spender != empty(address), "Token: approve to the zero address"

    self.allowance[owner][spender] = amount
    log IERC20.Approval(owner, spender, amount)

@external
def increaseAllowance(_spender: address, _added_value: uint256) -> bool:
    """
    @notice Increase the allowance granted to `_spender` by the caller
    @dev This is alternative to {approve} that can be used as a mitigation for
         the potential race condition
    @param _spender The address which will transfer the funds
    @param _added_value The amount of to increase the allowance
    @return bool success
    """
    allowance: uint256 = self.allowance[msg.sender][_spender] + _added_value
    self.allowance[msg.sender][_spender] = allowance

    log IERC20.Approval(msg.sender, _spender, allowance)
    return True

@external
def decreaseAllowance(_spender: address, _subtracted_value: uint256) -> bool:
    """
    @notice Decrease the allowance granted to `_spender` by the caller
    @dev This is alternative to {approve} that can be used as a mitigation for
         the potential race condition
    @param _spender The address which will transfer the funds
    @param _subtracted_value The amount of to decrease the allowance
    @return bool success
    """
    allowance: uint256 = self.allowance[msg.sender][_spender] - _subtracted_value
    self.allowance[msg.sender][_spender] = allowance

    log IERC20.Approval(msg.sender, _spender, allowance)
    return True


@internal
def _mint(_to: address, _value: uint256):
    """
    @dev Mint an amount of the token and assigns it to an account.
         This encapsulates the modification of balances such that the
         proper events are emitted.
    @param _to The account that will receive the created tokens.
    @param _value The amount that will be created.
    """
    assert _to != empty(address), "Can't mint to the zero address!"
    self._before_token_transfer(empty(address), _to, _value)
    self.totalSupply += _value
    self.balanceOf[_to] += _value
    log IERC20.Transfer(empty(address), _to, _value)

    self._after_token_transfer(empty(address), _to, _value)


@internal
def _burn(_to: address, _value: uint256):
    """
    @dev Internal function that burns an amount of the token of a given
         account.
    @param _to The account whose tokens will be burned.
    @param _value The amount that will be burned.
    """
    assert _to != empty(address)
    self._before_token_transfer(_to, empty(address), _value)

    wallet_balance: uint256 = self.balanceOf[_to]
    assert _value <= wallet_balance, "You don't have those many tokens to burn."
    self.totalSupply -= _value
    self.balanceOf[_to] -= _value
    log IERC20.Transfer(_to, empty(address), _value)

    self._after_token_transfer(_to, empty(address), _value)


@internal
def _spend_allowance(owner: address, spender: address, amount: uint256):
    """
    @dev Updates `owner`'s allowance for `spender`
         based on spent `amount`.
    @notice WARNING: Note that it does not update the
            allowance `amount` in case of infinite
            allowance. Also, it reverts if not enough
            allowance is available.
    @param owner The 20-byte owner address.
    @param spender The 20-byte spender address.
    @param amount The 32-byte token amount that is
           allowed to be spent by the `spender`.
    """
    current_allowance: uint256 = self.allowance[owner][spender]
    if (current_allowance != max_value(uint256)):
        # The following line allows the commonly known address
        # poisoning attack, where `transferFrom` instructions
        # are executed from arbitrary addresses with an `amount`
        # of 0. However, this poisoning attack is not an on-chain
        # vulnerability. All assets are safe. It is an off-chain
        # log interpretation issue.
        assert current_allowance >= amount, "erc20: insufficient allowance"
        self._approve(owner, spender, unsafe_sub(current_allowance, amount))


@internal
def _before_token_transfer(owner: address, to: address, amount: uint256):
    """
    @dev Hook that is called before any transfer of tokens.
         This includes minting and burning.
    @notice The calling conditions are:
            - when `owner` and `to` are both non-zero,
              `amount` of `owner`'s tokens will be
              transferred to `to`,
            - when `owner` is zero, `amount` tokens will
              be minted for `to`,
            - when `to` is zero, `amount` of `owner`'s
              tokens will be burned,
            - `owner` and `to` are never both zero.
    @param owner The 20-byte owner address.
    @param to The 20-byte receiver address.
    @param amount The 32-byte token amount to be transferred.
    """
    pass


@internal
def _after_token_transfer(owner: address, to: address, amount: uint256):
    """
    @dev Hook that is called after any transfer of tokens.
         This includes minting and burning.
    @notice The calling conditions are:
            - when `owner` and `to` are both non-zero,
              `amount` of `owner`'s tokens has been
              transferred to `to`,
            - when `owner` is zero, `amount` tokens
              have been minted for `to`,
            - when `to` is zero, `amount` of `owner`'s
              tokens have been burned,
            - `owner` and `to` are never both zero.
    @param owner The 20-byte owner address.
    @param to The 20-byte receiver address.
    @param amount The 32-byte token amount that has
           been transferred.
    """
    pass