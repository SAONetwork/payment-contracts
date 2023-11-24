// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Payee.sol";
import "hardhat/console.sol";

contract Portal {


    mapping(address => address) public getPayee;
    mapping(address => uint) public createdAt;

    event PayeeCreated(address indexed owner, address indexed payee);

    /*
        message Proposal {
          string owner = 1;
          string provider = 2;
          string groupId = 3;
          uint64 duration = 4;
          int32 replica = 5;
          int32 timeout = 6;
          string alias = 7;
          string dataId = 8;
          string commitId = 9;
          repeated string tags = 10; 
          string cid = 11;
          string rule = 12;
          string extendInfo = 13; 
          uint64 size = 14;
          uint32 operation = 15; // 0: new|update, 1:force-push
          repeated string readonlyDids = 16;
          repeated string readwriteDids = 17;
        }
    */

    constructor()  {

    }

    function createPayee() external returns(address payee) {

        require(getPayee[msg.sender] == address(0), "PAYEE EXISTS");

        bytes memory bytecode = type(Payee).creationCode;

        bytes32 salt = keccak256(abi.encodePacked(msg.sender));

        assembly {
            payee := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        console.log(payee);

        getPayee[msg.sender] = payee;
        createdAt[payee] = block.number;

        emit PayeeCreated(msg.sender, payee);
    }
}
