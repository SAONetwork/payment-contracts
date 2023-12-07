// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

contract PayeeX is OwnerIsCreator {
    error NothingToWithdraw(); // Used when trying to withdraw Ether but there's nothing to withdraw.
    error FailedToWithdrawEth(address owner, address target, uint256 value); // Used when the withdrawal of Ether fails.

    uint64 destinationChainSelector = 12532609583862916517;

    address immutable i_router;

    address public token;
    address public payee;
    address public link;
    address public portal;

    event PaymentCreated(bytes32 messageId, string dataId,string cid,uint256 amount, uint256 expiredAt);

    struct Data{
        address owner;
        address payee;
        string cid;
        string dataId;
        uint256 timeout;
        uint256 saoAmount;
        uint256 tokenAmount;
    }

    /// @notice Constructor initializes the contract with the router address.
    /// @param router The address of the router contract.
    constructor(address router, address _token, address _portal, address _payee, address _link) {
        i_router = router;
        token = _token;
        payee = _payee;
        link = _link;
        portal = _portal;
    }

    function createPayment(string memory _cid, string memory _dataId, uint256 _sao, uint256 _timeout, uint256 _tokenAmount) external payable {

        Data memory data;

        data.owner = msg.sender;
        data.payee = payee;
        data.cid = _cid;
        data.dataId = _dataId;
        data.saoAmount = _sao;
        data.timeout = _timeout;
        data.tokenAmount = _tokenAmount;

        Client.EVM2AnyMessage memory paymentMsg = Client.EVM2AnyMessage({
            receiver: abi.encode(portal), // ABI-encoded receiver address
            data: abi.encode(data), // ABI-encoded string message
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 2000_000, strict: false})
            ),
            feeToken: link
        });

        // Initialize a router client instance to interact with cross-chain router
        IRouterClient router = IRouterClient(i_router);

        IERC20(token).transferFrom(msg.sender, address(this), _tokenAmount);

        // Get the fee required to send the message
        uint256 fees = router.getFee(destinationChainSelector, paymentMsg);

        IERC20(link).approve(i_router, fees);

         if (fees > IERC20(link).balanceOf(address(this)))
            revert ("NEED MORE LINK");

        // Send the message through the router and store the returned message ID
        bytes32 messageId = router.ccipSend(
            destinationChainSelector,
            paymentMsg
        );

        emit PaymentCreated(messageId, _dataId, _cid, _sao, block.timestamp + _timeout);
    }


    receive() external payable {
        revert();
    }

    function withdraw(address beneficiary) public onlyOwner {
        // Retrieve the balance of this contract
        uint256 amount = address(this).balance;

        // Revert if there is nothing to withdraw
        if (amount == 0) revert NothingToWithdraw();

        // Attempt to send the funds, capturing the success status and discarding any return data
        (bool sent, ) = beneficiary.call{value: amount}("");

        // Revert if the send failed, with information about the attempted transfer
        if (!sent) revert FailedToWithdrawEth(msg.sender, beneficiary, amount);
    }

    function withdrawToken(
        address beneficiary,
        address _token
    ) public onlyOwner {
        // Retrieve the balance of this contract
        uint256 amount = IERC20(_token).balanceOf(address(this));

        // Revert if there is nothing to withdraw
        if (amount == 0) revert NothingToWithdraw();

        IERC20(_token).transfer(beneficiary, amount);
    }
}
