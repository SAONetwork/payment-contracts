// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

import "./Payee.sol";
import "hardhat/console.sol";

contract Portal is CCIPReceiver{

    mapping(address => address) public getPayee;
    mapping(address => uint) public createdAt;

    event PayeeCreated(address indexed owner, address indexed payee);

    event MessageReceived(
        bytes32 latestMessageId,
        uint64 latestSourceChainSelector,
        address latestSender,
        Data latestMessage
    );

    struct Data{
        address payee;
        string cid;
        string dataId;
        uint256 timeout;
        uint256 saoAmount;
        uint256 tokenAmount;
    }

    constructor(address router) CCIPReceiver(router) {}

    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal override {
        bytes32 latestMessageId = message.messageId;
        uint64 latestSourceChainSelector = message.sourceChainSelector;
        address latestSender = abi.decode(message.sender, (address));
        Data memory latestMessage = abi.decode(message.data, (Data));
        emit MessageReceived(
            latestMessageId,
            latestSourceChainSelector,
            latestSender,
            latestMessage
        );
        Payee payee = Payee(latestMessage.payee);

        payee.createPayment(latestMessage.cid, latestMessage.dataId, latestMessage.saoAmount, latestMessage.timeout, latestMessage.tokenAmount);
        emit MessageReceived(
            latestMessageId,
            latestSourceChainSelector,
            latestSender,
            latestMessage
        );
    }


    function createPayee() external returns(address) {

        require(getPayee[msg.sender] == address(0), "PAYEE EXISTS");

//        bytes memory bytecode = type(Payee).creationCode;

        bytes32 salt = keccak256(abi.encodePacked(msg.sender));

//        assembly {
//            payee := create2(0, add(bytecode, 32), mload(bytecode), salt)
//        }
        Payee payee = new Payee{salt:salt}(address(0x694AA1769357215DE4FAC081bf1f309aDC325306));

//        console.log(payee);

        getPayee[msg.sender] = address(payee);
        createdAt[address(payee)] = block.number;

        emit PayeeCreated(msg.sender, address(payee));
        return address(payee);
    }
}
