// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";

contract Payee is FunctionsClient, ConfirmedOwner {

    using Address for address;
    using FunctionsRequest for FunctionsRequest.Request;


    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;

    error UnexpectedRequestID(bytes32 requestId);

    event Response(bytes32 indexed requestId, bytes response, bytes err);

    string public payeeId;
    AggregatorV3Interface internal dataFeed;


    // SCT = 1e6 usct 
    uint256 public SC = 1000;

    uint256  public confirmedFund;

    struct Payment{
        address sender;
        string dataId;
        string cid;
        uint80 roundId;
        uint256 amountA;
        uint256 amountB;
        uint256 createdAt;
        uint256 expiredAt;
        uint status; // 1: pending, 2: paid
    }

    mapping(string => Payment) public getPayment;

    event PaymentCreated(string dataId,string cid,uint256 amount, uint256 expiredAt);

    event PaymentConfirmed(string dataId);

    event Withdraw(address token, uint256 amount);

    constructor(address feed, address router)  FunctionsClient(router) ConfirmedOwner(tx.origin) {
        dataFeed = AggregatorV3Interface(feed);
    }


    /*
     * _cid: cid of the payment proposal 
     * _sao: amount aht the payee need to pay to network
     * _timeout: time to refund 
     *
     */
    function createPayment(string memory _cid, string memory _dataId, uint256 _sao, uint256 _timeout, uint256 _token) external payable {

        Payment memory p = getPayment[_dataId];

        require(p.roundId == 0, "dataId already exists");

        uint256 amountA = _token;

        (int price, uint80 roundId) = _getPrice();

        uint256 amountB = _sao * uint256(1e15) / uint256(price);

        // verify payment amount with latest round price feed
        require(amountA == amountB, "invalid payment amount");

        Payment memory payment;
        payment.dataId=  _dataId;
        payment.cid = _cid;
        payment.sender = tx.origin;
        payment.amountA = amountA;
        payment.roundId = roundId;
        payment.amountB = amountB;
        payment.createdAt = block.timestamp;
        payment.expiredAt = block.timestamp + _timeout;
        payment.status = 1;

        getPayment[_dataId] = payment;

        emit PaymentCreated(_dataId, _cid, amountB, payment.expiredAt);
    }

    function confirmPayment(string memory _dataId) external onlyOwner {
        
        Payment memory payment = getPayment[_dataId];

        require(payment.status == 1, "PAYMENT NOT IN PENDING");

        payment.status = 2;

        getPayment[_dataId] = payment;

        confirmedFund += payment.amountA;

        emit PaymentConfirmed(payment.dataId);
    }

    function withdraw() external onlyOwner {
        require(confirmedFund> 0, "NO AVAILABLE CONFIRMED FUND");
        require(address(this).balance >= confirmedFund, "INSUFFICIENT ETH BALANCE");

        Address.sendValue(payable(msg.sender), confirmedFund);

        confirmedFund = 0;

        emit Withdraw(msg.sender,confirmedFund);
    }

    function refund() external onlyOwner {
        require(confirmedFund> 0, "NO AVAILABLE CONFIRMED FUND");
        require(address(this).balance > confirmedFund, "INSUFFICIENT ETH BALANCE");

        Address.sendValue(payable(msg.sender), confirmedFund);

        confirmedFund = 0;

        emit Withdraw(msg.sender,confirmedFund);
    }

    function _getPrice() internal view returns (int, uint80) {
        (uint80 roundID, int answer,,,) = dataFeed.latestRoundData();
        return (answer, roundID);
    }

    /*=============== Chainlink Functions =============== */
    
    /**
     * @notice Send a simple request
     * @param source JavaScript source code
     * @param encryptedSecretsUrls Encrypted URLs where to fetch user secrets
     * @param donHostedSecretsSlotID Don hosted secrets slotId
     * @param donHostedSecretsVersion Don hosted secrets version
     * @param args List of arguments accessible from within the source code
     * @param bytesArgs Array of bytes arguments, represented as hex strings
     * @param subscriptionId Billing ID
     */
    function sendRequest(
        string memory source,
        bytes memory encryptedSecretsUrls,
        uint8 donHostedSecretsSlotID,
        uint64 donHostedSecretsVersion,
        string[] memory args,
        bytes[] memory bytesArgs,
        uint64 subscriptionId,
        uint32 gasLimit,
        bytes32 donID
    ) external onlyOwner returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source);
        if (encryptedSecretsUrls.length > 0)
            req.addSecretsReference(encryptedSecretsUrls);
        else if (donHostedSecretsVersion > 0) {
            req.addDONHostedSecrets(
                donHostedSecretsSlotID,
                donHostedSecretsVersion
            );
        }
        if (args.length > 0) req.setArgs(args);
        if (bytesArgs.length > 0) req.setBytesArgs(bytesArgs);
        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donID
        );
        return s_lastRequestId;
    }

    /**
     * @notice Store latest result/error
     * @param requestId The request ID, returned by sendRequest()
     * @param response Aggregated response from the user code
     * @param err Aggregated error from the user code or from the execution pipeline
     * Either response or error parameter will be set, but never both
     */
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId);
        }
        s_lastResponse = response;
        s_lastError = err;
        emit Response(requestId, s_lastResponse, s_lastError);
    }
}
