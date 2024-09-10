// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Committee} from "./ExampleCommittee.sol";
import {SortitionTreeLib} from "../src/SortitionTreeLib.sol";

contract ExampleCommitteeTest is Test {
    using SortitionTreeLib for SortitionTreeLib.SortitionTree;

    Committee internal committee;

    function setUp() public {
        committee = new Committee();
    }

    function testAddParticipant() public {
        uint256 weight = 20;
        address signingKey = vm.addr(1); // Create a signing key using Forge's vm.addr
        committee.addParticipant(weight, signingKey);
    }

    function testRemoveParticipant() public {
        uint256 weight1 = 20;
        uint256 weight2 = 20;
        address signingKey1 = vm.addr(1);
        address signingKey2 = vm.addr(2);
        committee.addParticipant(weight1, signingKey1);
        committee.addParticipant(weight2, signingKey2);

        committee.removeParticipant(2);
    }

    function testUpdateParticipant() public {
        uint256 initialWeight = 20;
        uint256 newWeight = 15;
        address signingKey = vm.addr(1);
        committee.addParticipant(initialWeight, signingKey);

        committee.updateParticipant(1, newWeight);
    }

    function testSelectCommittee() public {
        for (uint256 i = 1; i <= 5; i++) {
            address signingKey = vm.addr(i);
            vm.prank(signingKey);
            committee.addParticipant(20, signingKey);
        }

        bytes32 seed = keccak256(abi.encodePacked(block.timestamp, block.difficulty));
        committee.selectCommittee(seed);

        uint256[] memory committeeMembers = committee.getCommitteeMembers();
        assertTrue(committeeMembers.length > 0, "Committee should be selected");

        for (uint256 i = 0; i < committeeMembers.length; i++) {
            assertTrue(
                committeeMembers[i] > 0 && committeeMembers[i] <= 5,
                "Selected committee member index should be valid"
            );
        }
    }
}
