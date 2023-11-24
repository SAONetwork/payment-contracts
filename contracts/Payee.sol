// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Payee is Ownable {

    using Address for address;

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

    constructor(address feed) Ownable(tx.origin) {
        dataFeed = AggregatorV3Interface(feed);
    }

    /*
     * _cid: cid of the payment proposal 
     * _sao: amount aht the payee need to pay to network
     * _timeout: time to refund 
     *
     */
    function createPayment(string memory _cid, string memory _dataId, uint256 _sao, uint256 _timeout) external payable {

        Payment memory p = getPayment[_dataId];

        require(p.roundId == 0, "dataId already exists");

        uint256 amountA = msg.value;

        (int price, uint80 roundId) = _getPrice();

        uint256 amountB = _sao * uint256(1e15) / uint256(price);

        // verify payment amount with latest round price feed
        require(msg.value == amountB, "invalid payment amount");

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
}
