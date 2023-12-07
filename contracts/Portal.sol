// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

import "./Payee.sol";
import "hardhat/console.sol";

contract Portal is CCIPReceiver, ConfirmedOwner {

    event MessageReceived(
        bytes32 latestMessageId,
        uint64 latestSourceChainSelector,
        address latestSender,
        Data latestMessage
    );

    bool public checkFund;

    struct Data{
        address owner;
        address payee;
        string cid;
        string dataId;
        uint256 timeout;
        uint256 saoAmount;
        uint256 tokenAmount;
    }


    constructor(address router) CCIPReceiver(router) ConfirmedOwner(tx.origin){}

    function setCheckFund(bool _checkFund) onlyOwner external {
        checkFund = _checkFund;
    }

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

        payee.createPaymentX(latestMessage.owner, latestMessage.cid, latestMessage.dataId, latestMessage.saoAmount, latestMessage.timeout, latestMessage.tokenAmount, checkFund);

    }

}
