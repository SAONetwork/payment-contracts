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

    mapping(address => uint256 ) public confirmedFund;

        uint256 id;
        string cid;
        address token;
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

    constructor() Ownable(tx.origin) {
        dataFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    }

    /*
     * _cid: cid of the payment proposal 
     * _roundID: dataFeed roundID
     * _timeout: time to refund 
     *
     */
    function createPayment(string memory _cid,uint80 _roundId, uint256 _timeout) external payable {

        paymentId += 1;

        uint256 amountA = msg.value;

        (int price, uint80 roundId) = _getPrice();

        require(_roundId == roundId, "INVALID DATAFEED ROUND");

        uint256 amountB = amountA * uint256(price);

        Payment memory payment;
        payment.id =  paymentId;
        payment.cid = _cid;
        payment.token = address(0);
        payment.amountA = amountA;
        payment.amountB = amountB;
        payment.createdAt = block.timestamp;
        payment.expiredAt = block.timestamp + _timeout;
        payment.status = 1;

        getPayment[paymentId] = payment;

        emit PaymentCreated(paymentId, _cid, amountB, payment.expiredAt);
    }

    /*
     * paymentId
     *
     */
    function confirmPayment(uint256 paymentId) external onlyOwner {
        
        Payment memory payment = getPayment[paymentId];

        require(payment.id == 1, "PAYMENT NOT IN PENDING");

        payment.status = 2;

        getPayment[paymentId] = payment;

        confirmedFund[payment.token] += payment.amountA;

        emit PaymentConfirmed(payment.id);
    }

    function withdraw(address token) external onlyOwner {
        uint256 val = confirmedFund[token];
        require(val > 0, "NO AVAILABLE CONFIRMED FUND");
        if (token == address(0)) {
            require(address(this).balance > val, "INSUFFICIENT ETH BALANCE");
            Address.sendValue(payable(msg.sender), val);
        } else {
            require(IERC20(token).balanceOf(address(this)) > val, "INSUFFICIENT TOKEN BALANCE");
            IERC20(token).transfer(msg.sender, val);
        }

        confirmedFund[token] -= val;

        emit Withdraw(token, val);
    }

    function _getPrice() internal view returns (int, uint80) {
        (uint80 roundID, int answer,,,) = dataFeed.latestRoundData();
        return (answer, roundID);
    }
}
