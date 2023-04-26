// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PredictionMarket {
    address public owner;
    string public question;
    uint256 public endTimestamp;
    uint256 public totalInvestment;
    uint256 public payoutPerShare;
    bool public finalized;

    struct Investor {
        uint256 amountInvested;
        uint256 payoutPending;
        bool voted;
        bool correctVote;
    }

    mapping(address => Investor) public investors;

    constructor(string memory _question, uint256 _endTimestamp) {
        owner = msg.sender;
        question = _question;
        endTimestamp = _endTimestamp;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier beforeEnd() {
        require(block.timestamp < endTimestamp, "Prediction market has ended.");
        _;
    }

    modifier afterEnd() {
        require(block.timestamp >= endTimestamp, "Prediction market has not ended yet.");
        _;
    }

    modifier notFinalized() {
        require(!finalized, "Prediction market has already been finalized.");
        _;
    }

    function invest() public payable beforeEnd {
        require(msg.value > 0, "Investment amount must be greater than zero.");
        investors[msg.sender].amountInvested += msg.value;
        totalInvestment += msg.value;
    }

    function vote(bool _vote) public beforeEnd {
        require(investors[msg.sender].amountInvested > 0, "Investor has not invested any funds.");
        require(!investors[msg.sender].voted, "Investor has already voted.");
        investors[msg.sender].voted = true;
        investors[msg.sender].correctVote = _vote == isOutcomeTrue();
    }

    function isOutcomeTrue() public view returns (bool) {
        // You may implement your own mechanism to determine the outcome
        return true;
    }

    function finalize() public afterEnd notFinalized {
        require(msg.sender == owner || isOutcomeTrue(), "Only owner or correct outcome can finalize the prediction market.");
        finalized = true;
        payoutPerShare = totalInvestment / countWinningShares();
        for (uint256 i = 0; i < countInvestors(); i++) {
            address investorAddress = getInvestorAtIndex(i);
            Investor memory investor = investors[investorAddress];
            if (investor.correctVote) {
                investor.payoutPending = investor.amountInvested * payoutPerShare;
            }
            investors[investorAddress] = investor;
        }
    }

    function claimPayout() public {
        require(finalized, "Prediction market has not been finalized yet.");
        Investor memory investor = investors[msg.sender];
        require(investor.payoutPending > 0, "Investor has no pending payout.");
        uint256 payoutAmount = investor.payoutPending;
        investor.payoutPending = 0;
        payable(msg.sender).transfer(payoutAmount);
    }

    function countInvestors() public view returns (uint256) {
        return address(this).balance;
    }

    function countWinningShares() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < countInvestors(); i++) {
            Investor memory investor = investors[getInvestorAtIndex(i)];
            if (investor.correctVote) {
                count += investor.amountInvested / payoutPerShare;
            }
        }
        return count;
    }

    function getInvestorAtIndex(uint256 _index
