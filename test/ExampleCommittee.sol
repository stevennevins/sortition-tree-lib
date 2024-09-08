// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SortitionTreeLib} from "../src/SortitionTreeLib.sol";

contract Committee {
    using SortitionTreeLib for SortitionTreeLib.SortitionTree;

    SortitionTreeLib.SortitionTree private tree;
    uint256 private constant INITIAL_CAPACITY = 16;
    uint256 private constant MIN_COMMITTEE_WEIGHT = 100;
    uint256 private constant MAX_COMMITTEE_WEIGHT = 500;
    uint256 private constant MIN_PARTICIPANT_WEIGHT = 10;
    uint256 private constant MAX_PARTICIPANT_WEIGHT = 100;

    uint256 public committeeRoot;

    constructor() {
        tree.initialize(INITIAL_CAPACITY);
    }

    function addParticipant(
        uint256 weight
    ) external {
        require(
            weight >= MIN_PARTICIPANT_WEIGHT && weight <= MAX_PARTICIPANT_WEIGHT,
            "Weight out of range"
        );
        tree.add(weight);
    }

    function updateParticipantWeight(uint256 participantIndex, uint256 newWeight) external {
        require(
            newWeight >= MIN_PARTICIPANT_WEIGHT && newWeight <= MAX_PARTICIPANT_WEIGHT,
            "Weight out of range"
        );
        tree.update(participantIndex, newWeight);
    }

    function removeParticipant(
        uint256 participantIndex
    ) external {
        require(
            participantIndex > 0 && participantIndex <= tree.getLeafCount(),
            "Invalid participant index"
        );
        tree.remove(participantIndex);
    }

    function selectCommittee(
        bytes32 seed
    ) external {
        committeeRoot = tree.selectSubTree(seed, MAX_COMMITTEE_WEIGHT, MIN_COMMITTEE_WEIGHT);
    }

    function getCommitteeMembers() external view returns (uint256[] memory) {
        require(committeeRoot != 0, "Committee not selected");
        return tree.getSubTreeLeaves(committeeRoot);
    }

    function isCommitteeMember(
        uint256 leafIndex
    ) external view returns (bool) {
        require(committeeRoot != 0, "Committee not selected");
        return tree.isInSubtree(committeeRoot, leafIndex);
    }

    function getCommitteeWeight() external view returns (uint256) {
        require(committeeRoot != 0, "Committee not selected");
        return tree.getSubtreeWeight(committeeRoot);
    }

    function getWeightOf(
        uint256 participantIndex
    ) external view returns (uint256) {
        return tree.getLeafWeight(participantIndex);
    }
}
