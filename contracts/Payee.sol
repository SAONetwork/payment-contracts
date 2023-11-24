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

    uint256 public paymentId = 0;

    // SCT = 1e6 usct 
    uint256 public SC = 1000;

    uint256  public confirmedFund;

    struct Payment{
        uint256 id;
        string cid;
        uint80 roundId;
        uint256 amountA;
        uint256 amountB;
        uint256 createdAt;
        uint256 expiredAt;
        uint status; // 1: pending, 2: paid
    }

    mapping(uint256 => Payment) public getPayment;

    event PaymentCreated(uint256 indexed paymentId ,string cid,uint256 amount, uint256 expiredAt);

    event PaymentConfirmed(uint256 indexed paymentId);

    event Withdraw(address token, uint256 amount);

    constructor(feed address) Ownable(tx.origin) {
        dataFeed = AggregatorV3Interface(feed);
    }

    /*
     * _cid: cid of the payment proposal 
     * _sao: amount need payee pay to network
     * _timeout: time to refund 
     *
     */
    function createPayment(string memory _cid, uint256 _sao, uint256 _timeout) external payable {

        paymentId += 1;

        uint256 amountA = msg.value;

        (int price, uint80 roundId) = _getPrice();

        uint256 amountB = _sao * 1e15 / price 

        require(msg.value == amountA, "invalid payment amount");

        Payment memory payment;
        payment.id =  paymentId;
        payment.cid = _cid;
        payment.amountA = amountA;
        payment.roundId = roundId;
        payment.amountB = amountB;
        payment.createdAt = block.timestamp;
        payment.expiredAt = block.timestamp + _timeout;
        payment.status = 1;

        getPayment[paymentId] = payment;

        emit PaymentCreated(paymentId, _cid, amountB, payment.expiredAt);
    }

    function confirmPayment(uint256 _paymentId) external onlyOwner {
        
        Payment memory payment = getPayment[_paymentId];

        require(payment.id == 1, "PAYMENT NOT IN PENDING");

        payment.status = 2;

        getPayment[_paymentId] = payment;

        confirmedFund += payment.amountA;

        emit PaymentConfirmed(payment.id);
    }

    function withdraw() external onlyOwner {
        require(confirmedFund> 0, "NO AVAILABLE CONFIRMED FUND");
        require(address(this).balance > confirmedFund, "INSUFFICIENT ETH BALANCE");

        Address.sendValue(payable(msg.sender), confirmedFund);

        confirmedFund = 0;

        emit Withdraw(token, confirmedFund);
    }

    function _getPrice() internal view returns (int, uint80) {
        (uint80 roundID, int answer,,,) = dataFeed.latestRoundData();
        return (answer, roundID);
    }
}
