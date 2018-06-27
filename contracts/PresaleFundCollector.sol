pragma solidity ^0.4.23;


import "./Crowdsale.sol";
import "./SafeMathLib.sol";

/**
 * Collect funds from presale investors to be send to the crowdsale smart contract later.
 *
 * - Collect funds from pre-sale investors
 * - Send funds to the crowdsale when it opens
 * - Allow owner to set the crowdsale
 * - Have refund after X days as a safety hatch if the crowdsale doesn't materilize
 *
 */
contract PresaleFundCollector is Ownable {

  using SafeMathLib for uint;

  /** How many investors when can carry per a single contract */
  uint public MAX_INVESTORS = 32;
    
  /** Addresses that are allowed to invest even before ICO offical opens. For testing, for ICO partners, etc. */
  mapping (address => bool) public earlyParticipantWhitelist;
  
  /** How many investors we have now */
  uint public investorCount;

  /** Who are our investors (iterable) */
  address[] public investors;

  /** How much they have invested */
  mapping(address => uint) public balances;

  /** When our refund freeze is over (UNIX timestamp) */
  uint public freezeEndsAt;

  /** What is the minimum buy in */
  uint public weiMinimumLimit;

  /** Have we begun to move funds */
  bool public moving;

  /** Our ICO contract where we will move the funds */
  Crowdsale public crowdsale;

  event Invested(address investor, uint value);
  event Refunded(address investor, uint value);
  event Whitelisted(address addr, bool status);
  /**
   * Create presale contract where lock up period is given days
   */
  constructor(address _owner, uint _freezeEndsAt, uint _weiMinimumLimit) public{

    owner = _owner;

    // Give argument
    require(_freezeEndsAt != 0);

    // Give argument
    require(_weiMinimumLimit != 0);
    
    weiMinimumLimit = _weiMinimumLimit;
    freezeEndsAt = _freezeEndsAt;
  }

  /**
   * Participate to a presale.
   */
  //function invest() public payable {
  function() public payable {  
    // Whitelisted address can only invest
    require(earlyParticipantWhitelist[msg.sender]);

    // Cannot invest anymore through crowdsale when moving has begun
    require(!moving);

    address investor = msg.sender;

    bool existing = balances[investor] > 0;

    balances[investor] = balances[investor].plus(msg.value);

    // Need to fulfill minimum limit
    //require(balances[investor] > weiMinimumLimit);

    // This is a new investor
    if(!existing) {
      // Limit number of investors to prevent too long loops
      require(investorCount <= MAX_INVESTORS);

      investors.push(investor);
      investorCount++;
    }

    emit Invested(investor, msg.value);
  }
  
   /**
   * Allow addresses to do early participation.
   *
   */
  function setEarlyParticipantWhitelist(address addr, bool status) onlyOwner public {
    earlyParticipantWhitelist[addr] = status;
    emit Whitelisted(addr, status);
  }

  /**
   * Load funds to the crowdsale for a single investor.
   */
  function participateCrowdsaleInvestor(address investor) public {

    // Crowdsale not yet set
    require(address(crowdsale) != 0);

    moving = true;

    if(balances[investor] > 0) {
      uint amount = balances[investor];
      delete balances[investor];
      crowdsale.invest.value(amount)(investor);
    }
  }

  /**
   * Load funds to the crowdsale for all investor.
   *
   */
  function participateCrowdsaleAll() public {
    // We might hit a max gas limit in this loop,
    // and in this case you can simply call participateCrowdsaleInvestor() for all investors
    for(uint i=0; i < investors.length; i++) {
      participateCrowdsaleInvestor(investors[i]);
    }
  }

  /**
   * ICO never happened. Allow refund.
   */
  function refund() public {

    // Trying to ask refund too soon
    require(now > freezeEndsAt);

    // We have started to move funds
    moving = true;

    address investor = msg.sender;
    require(balances[investor] != 0);
    uint amount = balances[investor];
    delete balances[investor];
    emit Refunded(investor, amount);
    investor.transfer(amount);
  }

  /**
   * Set the target crowdsale where we will move presale funds when the crowdsale opens.
   */
  function setCrowdsale(Crowdsale _crowdsale) public onlyOwner {
    crowdsale = _crowdsale;
  }

  /** Explicitly call function from your wallet. */
  // function() public payable {
  //   revert();
  // }
}
