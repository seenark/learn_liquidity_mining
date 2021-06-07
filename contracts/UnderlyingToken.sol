// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract UnderlyingToken is ERC20 {
    constructor() ERC20("MyToken", "MTKN") {}

    function faucet(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }
}
