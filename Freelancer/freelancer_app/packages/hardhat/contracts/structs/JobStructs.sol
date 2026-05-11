// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./MilestoneStructs.sol";

library JobStructs {

    enum JobStatus {
        Open,
        Accepted,
        InProgress,
        Completed,
        Cancelled,
        Disputed
    }

    struct Job {
        address client;
        address freelancer;
        JobStatus status;
        uint256 totalAmount;
        uint256 currentMilestone;
        bool exists;
    }
}
