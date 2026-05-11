//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// Useful for debugging. Remove when deploying to a live network.
import "hardhat/console.sol";

// Use openzeppelin to inherit battle-tested implementations (ERC20, ERC721, etc)
// import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * A smart contract that allows changing a state variable of the contract and tracking the changes
 * It also allows the owner to withdraw the Ether in the contract
 * @author BuidlGuidl
 */
// SP/DX-License-Identifier: MIT
//pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./structs/JobStructs.sol";
import "./structs/MilestoneStructs.sol";

contract FreelanceEscrow is ReentrancyGuard {
    address public immutable arbitrator;
    uint256 public jobCounter;
    uint256 public constant AUTO_APPROVE_TIME = 3 days;

    mapping(uint256 => JobStructs.Job) public jobs;
    mapping(uint256 => MilestoneStructs.Milestone[]) public milestones;

                                //EVENTS
    event JobCreated(uint256 indexed jobId, address client, address freelancer, uint256 total);
    event JobAccepted(uint256 indexed jobId);
    event JobCancelled(uint256 indexed jobId, uint256 refund);
    event MilestoneSubmitted(uint256 indexed jobId, uint256 index);
    event MilestoneApproved(uint256 indexed jobId, uint256 index, uint256 amount);
    event MilestoneRejected(uint256 indexed jobId, uint256 index);
    event PaymentReleased(uint256 indexed jobId, uint256 index, uint256 amount);
    event DisputeRaised(uint256 indexed jobId, address raisedBy);
    event DisputeResolved(uint256 indexed jobId, uint256 clientRefund, uint256 freelancerPaid);
    event JobCompleted(uint256 indexed jobId);

    constructor(address _arbitrator) {
        require(_arbitrator != address(0), "Invalid arbitrator");
        arbitrator = _arbitrator;
    }

                               //MODIFIERS
    modifier onlyClient(uint256 jobId) {
        require(jobs[jobId].client == msg.sender, "Not client");
        _;
    }

    modifier onlyFreelancer(uint256 jobId) {
        require(jobs[jobId].freelancer == msg.sender, "Not freelancer");
        _;
    }

    modifier onlyArbitrator() {
        require(msg.sender == arbitrator, "Not arbitrator");
        _;
    }

    modifier jobExists(uint256 jobId) {
        require(jobs[jobId].exists, "Job does not exist");
        _;
    }

    modifier jobInState(uint256 jobId, JobStructs.JobStatus state) {
        require(jobs[jobId].status == state, "Invalid job state");
        _;
    }

                             //JOB LOGIC
    function createJob(
        address freelancer,
        string[] calldata titles,
        uint256[] calldata amounts
    ) external payable nonReentrant {
        require(freelancer != address(0), "Invalid freelancer");
        require(titles.length == amounts.length && titles.length > 0, "Invalid milestones");

        uint256 total;
        for (uint256 i; i < amounts.length; i++) {
            require(amounts[i] > 0, "Zero milestone");
            total += amounts[i];
        }
        require(msg.value == total, "Incorrect deposit");

        jobCounter++;
        jobs[jobCounter] = JobStructs.Job({
            client: msg.sender,
            freelancer: freelancer,
            status: JobStructs.JobStatus.Open,
            totalAmount: total,
            currentMilestone: 0,
            exists: true
        });

        for (uint256 i; i < titles.length; i++) {
            milestones[jobCounter].push(
                MilestoneStructs.Milestone({
                    title: titles[i],
                    amount: amounts[i],
                    status: MilestoneStructs.MilestoneStatus.Pending,
                    submittedAt: 0
                })
            );
        }

        emit JobCreated(jobCounter, msg.sender, freelancer, total);
    }

    function acceptJob(uint256 jobId)
        external
        jobExists(jobId)
        jobInState(jobId, JobStructs.JobStatus.Open)
        onlyFreelancer(jobId)
    {
        jobs[jobId].status = JobStructs.JobStatus.InProgress;
        emit JobAccepted(jobId);
    }

    function cancelJob(uint256 jobId)
        external
        jobExists(jobId)
        onlyClient(jobId)
        nonReentrant
    {
        JobStructs.Job storage job = jobs[jobId];
        require(job.status != JobStructs.JobStatus.Completed, "Already completed");

        uint256 refund = job.totalAmount;
        job.totalAmount = 0;
        job.status = JobStructs.JobStatus.Cancelled;

        (bool ok,) = payable(job.client).call{value: refund}("");
        require(ok, "Refund failed");

        emit JobCancelled(jobId, refund);
    }

    function raiseDispute(uint256 jobId)
        external
        jobExists(jobId)
    {
        require(
            msg.sender == jobs[jobId].client || msg.sender == jobs[jobId].freelancer,
            "Unauthorized"
        );
        jobs[jobId].status = JobStructs.JobStatus.Disputed;
        emit DisputeRaised(jobId, msg.sender);
    }

    function resolveDispute(
        uint256 jobId,
        uint256 clientRefund
    )
        external
        onlyArbitrator
        jobExists(jobId)
        jobInState(jobId, JobStructs.JobStatus.Disputed)
        nonReentrant
    {
        JobStructs.Job storage job = jobs[jobId];
        require(clientRefund <= job.totalAmount, "Invalid split");

        uint256 freelancerPay = job.totalAmount - clientRefund;
        job.totalAmount = 0;
        job.status = JobStructs.JobStatus.Completed;

        if (clientRefund > 0)
            payable(job.client).call{value: clientRefund}("");
        if (freelancerPay > 0)
            payable(job.freelancer).call{value: freelancerPay}("");

        emit DisputeResolved(jobId, clientRefund, freelancerPay);
    }

    /*//////////////////////////////////////////////////////////////
                          MILESTONE LOGIC
    //////////////////////////////////////////////////////////////*/
    function submitMilestone(uint256 jobId)
        external
        jobExists(jobId)
        onlyFreelancer(jobId)
        jobInState(jobId, JobStructs.JobStatus.InProgress)
    {
        uint256 idx = jobs[jobId].currentMilestone;
        MilestoneStructs.Milestone storage m = milestones[jobId][idx];

        require(m.status == MilestoneStructs.MilestoneStatus.Pending, "Invalid state");
        m.status = MilestoneStructs.MilestoneStatus.Submitted;
        m.submittedAt = block.timestamp;

        emit MilestoneSubmitted(jobId, idx);
    }

    function approveMilestone(uint256 jobId)
        external
        jobExists(jobId)
        onlyClient(jobId)
        nonReentrant
    {
        _approveMilestone(jobId);
    }

    function autoApprove(uint256 jobId)
        external
        jobExists(jobId)
        nonReentrant
    {
        uint256 idx = jobs[jobId].currentMilestone;
        MilestoneStructs.Milestone storage m = milestones[jobId][idx];

        require(
            m.status == MilestoneStructs.MilestoneStatus.Submitted &&
            block.timestamp >= m.submittedAt + AUTO_APPROVE_TIME,
            "Too early"
        );
        _approveMilestone(jobId);
    }

    function _approveMilestone(uint256 jobId) internal {
        JobStructs.Job storage job = jobs[jobId];
        uint256 idx = job.currentMilestone;
        MilestoneStructs.Milestone storage m = milestones[jobId][idx];

        m.status = MilestoneStructs.MilestoneStatus.Paid;
        job.currentMilestone++;

        payable(job.freelancer).call{value: m.amount}("");
        emit PaymentReleased(jobId, idx, m.amount);

        if (job.currentMilestone == milestones[jobId].length) {
            job.status = JobStructs.JobStatus.Completed;
            emit JobCompleted(jobId);
        }
    }
}
