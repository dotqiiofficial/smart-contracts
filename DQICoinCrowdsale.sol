pragma solidity 0.4.24;

import './Ownable.sol';
import './SafeMath.sol';
import './DQICoin.sol';

contract DQICoinCrowdsale is Ownable {
  using SafeMath for uint256;

  DQICoin public token;

  uint256 public startTime;
  uint256 public endTime;

  uint public minPurchase;
  uint public exchangeRate;

  bool public isFinalized = false;

  uint256 public totalToken;
  uint256 public goal;
  uint256 public tokenSaled = 0;
  address _token;
  address _ownerWallet;


  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event Finalized();
  event Withdraw(address to, uint value);

  function DQICoinCrowdsale(address _token, address _owner, uint256 _start, uint256 _end, uint256 _rate) public {
      _token = _token;
      _ownerWallet = _owner;

    require(_token != address(0));
    require(_ownerWallet != address(0));
    require (now >= _start);
    require (now < _end);
    require (_rate > 0);

    token = DQICoin(_token);
    startTime = _start;
    endTime = _end;
    require(endTime >= now);
    minPurchase = 0.001 ether;
    exchangeRate = _rate;
    totalToken = 90 * (10**6) * 10 ** uint256(token.decimals()); // 90M tokens

  }

  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());
    uint256 weiAmount = msg.value;
    // calculate token amount to be created
    uint256 buytokens = weiAmount.mul(exchangeRate);
    require(buytokens <= totalToken - tokenSaled);
    // update state
    tokenSaled = tokenSaled.add(buytokens);
    token.addToBalances(beneficiary, buytokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, buytokens);
    if(!_ownerWallet.send(msg.value)) throw;
  }

  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());
    Finalized();
    token.transfer(owner,token.balanceOf(this));
    isFinalized = true;
  }

  function hasEnded() public view returns (bool) {
    return now > endTime;
  }

  function validPurchase() internal view returns (bool) {
    bool withinStart = now >= startTime;
    bool withinPeriod = now < endTime;
    bool purchaseAmount = msg.value >= minPurchase;
    bool recruitAmount = tokenSaled < totalToken;
    return withinPeriod && purchaseAmount && recruitAmount && withinStart;
  }

  function updateExchangeRate(uint256 rate) onlyOwner public {
    exchangeRate = rate;
  }

  function sendTokens(address _contract, uint256 value) onlyOwner external {
    token.addToBalances(_contract, value);
    TokenPurchase(msg.sender, _contract, 0, value);
  }

}