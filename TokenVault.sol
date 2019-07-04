pragma solidity 0.4.24;

import "./ERC20Interface.sol";
import './SafeMath.sol';

contract TokenVault {
    using SafeMath for uint256;
    ERC20Interface public TokenContract;
    address beneficiary;

    uint256 public firstRelease;
    uint256 public secondRelease;
    uint256 public thirdRelease;
    uint256 public fourthRelease;

    modifier atStage(Stages _stage) {
        if(stage == _stage) _;
    }

    Stages public stage = Stages.initClaim;

    enum Stages {
        initClaim,
        firstRelease,
        secondRelease,
        thirdRelease,
        fourthRelease
    }

    constructor (address _contractAddress, address _beneficiary) public {
        require(_contractAddress != address(0));
        TokenContract = ERC20Interface(_contractAddress);
        beneficiary = _beneficiary;
    }

    function changeBeneficiary(address newBeneficiary) external {
        require(newBeneficiary != address(0));
        require(msg.sender == beneficiary);
        beneficiary = newBeneficiary;
    }


    function checkBalance() public constant returns (uint256 tokenBalance) {
        return TokenContract.balanceOf(this);
    }

    function claim() external {
        require(msg.sender == beneficiary);
        uint256 balance = TokenContract.balanceOf(this);
        // in reverse order so stages changes don't carry within one claim
        third_release(balance);
        second_release(balance);
        first_release(balance);
        init_claim(balance);
    }

    function nextStage() private {
        stage = Stages(uint256(stage) + 1);
    }

    function init_claim(uint256 balance) private atStage(Stages.initClaim) {
        firstRelease = now + 26 weeks; // assign 4 claiming times
        secondRelease = firstRelease + 26 weeks;
        thirdRelease = secondRelease + 26 weeks;
        nextStage();
    }

    function first_release(uint256 balance) private atStage(Stages.firstRelease) {
        require(now > firstRelease);
        uint256 amountToTransfer = balance.div(4);
        TokenContract.transfer(beneficiary, amountToTransfer); // send 25 % of team releases
        nextStage();
    }

    function second_release(uint256 balance) private atStage(Stages.secondRelease) {
        require(now > secondRelease);
        uint256 amountToTransfer = balance.div(3);
        TokenContract.transfer(beneficiary, amountToTransfer); // send 25 % of team releases
        nextStage();
    }

    function third_release(uint256 balance) private atStage(Stages.thirdRelease) {
        require(now > thirdRelease);
        uint256 amountToTransfer = balance.div(2);
        TokenContract.transfer(beneficiary, amountToTransfer); // send 25 % of team releases
        nextStage();
    }

    function fourth_release(uint256 balance) private atStage(Stages.fourthRelease) {
        require(now > fourthRelease);
        uint256 amountToTransfer = balance;
        TokenContract.transfer(beneficiary, amountToTransfer); // send 25 % of team releases
        nextStage();
    }

    function claimOtherTokens(address _token) external {
        require(msg.sender == beneficiary);
        require(_token != address(0));
        ERC20Interface token = ERC20Interface(_token);
        require(token != TokenContract);
        uint256 balance = token.balanceOf(this);
        token.transfer(beneficiary, balance);
    }
}