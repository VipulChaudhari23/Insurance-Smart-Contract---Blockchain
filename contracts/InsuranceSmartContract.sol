// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract InsuranceSmartContract {
    address public insurer;
    uint public policyCount;

    constructor() {
        insurer = msg.sender;
    }

    modifier onlyInsurer() {
        require(msg.sender == insurer, "Only insurer allowed");
        _;
    }

    struct Policy {
        address policyHolder;
        uint premium;
        uint coverage;
        uint startDate;
        uint endDate;
        bool isActive;
    }

    struct Claim {
        uint amount;
        string reason;
        bool approved;
        bool paid;
    }

    mapping(uint => Policy) public policies;
    mapping(uint => Claim[]) public policyClaims;

    // Events
    event PolicyIssued(uint policyId, address policyHolder);
    event PremiumPaid(uint policyId, address policyHolder);
    event ClaimSubmitted(uint policyId, uint claimId);
    event ClaimApproved(uint policyId, uint claimId);
    event ClaimPaid(uint policyId, uint claimId);

    // 1. Issue Policy
    function issuePolicy(
        address _policyHolder,
        uint _premium,
        uint _coverage,
        uint _duration
    ) public onlyInsurer returns (uint) {
        policies[policyCount] = Policy(
            _policyHolder,
            _premium,
            _coverage,
            block.timestamp,
            block.timestamp + _duration,
            true
        );

        emit PolicyIssued(policyCount, _policyHolder);
        policyCount++;
        return policyCount - 1;
    }

    // 2. Pay Premium
    function payPremium(uint _policyId) public payable {
        Policy storage policy = policies[_policyId];

        require(msg.sender == policy.policyHolder, "Not policy holder");
        require(policy.isActive, "Policy inactive");
        require(msg.value == policy.premium, "Incorrect premium");

        emit PremiumPaid(_policyId, msg.sender);
    }

    // 3. Submit Claim
    function submitClaim(
        uint _policyId,
        uint _amount,
        string memory _reason
    ) public returns (uint) {
        Policy storage policy = policies[_policyId];
        require(msg.sender == policy.policyHolder, "Not policy holder");
        require(policy.isActive, "Policy inactive");
        require(block.timestamp <= policy.endDate, "Policy expired");

        policyClaims[_policyId].push(Claim(_amount, _reason, false, false));
        uint claimId = policyClaims[_policyId].length - 1;

        emit ClaimSubmitted(_policyId, claimId);
        return claimId;
    }

    // 4. Approve Claim
    function approveClaim(uint _policyId, uint _claimId) public onlyInsurer {
        Claim storage claim = policyClaims[_policyId][_claimId];
        require(!claim.approved, "Already approved");

        claim.approved = true;
        emit ClaimApproved(_policyId, _claimId);
    }

    // 5. Pay Claim
    function payClaim(uint _policyId, uint _claimId) public onlyInsurer {
        Claim storage claim = policyClaims[_policyId][_claimId];
        Policy storage policy = policies[_policyId];

        require(claim.approved, "Not approved");
        require(!claim.paid, "Already paid");
        require(address(this).balance >= claim.amount, "Insufficient balance");

        claim.paid = true;
        payable(policy.policyHolder).transfer(claim.amount);

        emit ClaimPaid(_policyId, _claimId);
    }
}
