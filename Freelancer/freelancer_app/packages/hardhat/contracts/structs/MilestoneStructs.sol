// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

library MilestoneStructs {

    enum MilestoneStatus {
        Pending,
        Submitted,
        Approved,
        Rejected,
        Paid
    }

    struct Milestone {
        string title;
        uint256 amount;
        MilestoneStatus status;
    }
}
