// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract WMATIC is ERC20 {

    constructor() ERC20("Wrapped Matic", "MATIC") {
        _mint(msg.sender, 1000000 ether);
    }
}
