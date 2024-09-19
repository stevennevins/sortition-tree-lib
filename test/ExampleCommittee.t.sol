// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Committee} from "./ExampleCommittee.sol";
import {SortitionTreeLib} from "../src/SortitionTreeLib.sol";

contract ExampleCommitteeTest is Test {
    using SortitionTreeLib for SortitionTreeLib.SortitionTree;

    Committee internal committee;

    function setUp() public {
        committee = new Committee(16);
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

    function testSetCommitteeRoot() public {
        // Add participants to the committee
        for (uint256 i = 1; i <= 10; i++) {
            address signingKey = vm.addr(i);
            vm.prank(signingKey);
            committee.addParticipant(20, signingKey);
        }

        // Set a valid committee root
        uint256 validRoot = 2; // This should be a valid internal node index
        committee.setCommitteeRoot(validRoot);

        // Check if the committee root was set correctly
        assertEq(
            committee.committeeRoot(), validRoot, "Committee root should be set to the valid value"
        );

        // Verify the committee weight is within the allowed range
        uint256 committeeWeight = committee.getCommitteeWeight();
        assertTrue(committeeWeight == 160, "Committee weight should be within the allowed range");
    }

    function testVerifySignaturesFromNode() public {
        // Add participants to the committee
        uint256 numParticipants = 4;
        address[] memory signingKeys = new address[](numParticipants);
        for (uint256 i = 0; i < numParticipants; i++) {
            signingKeys[i] = vm.addr(i + 1);
            vm.prank(signingKeys[i]);
            committee.addParticipant(20, signingKeys[i]);
        }

        // Create a message to sign
        bytes32 message = keccak256("Test message");

        // Create signatures
        bytes[] memory signatures = new bytes[](numParticipants);
        for (uint256 i = 0; i < numParticipants; i++) {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(i + 1, message);
            signatures[i] = abi.encodePacked(r, s, v);
        }

        // Verify signatures from the root node (index 1)
        uint256 rootNodeIndex = 1;
        bool isValid = committee.verifySignaturesFromNode(rootNodeIndex, message, signatures);
        assertTrue(isValid, "Signatures should be valid for the root node");

        uint256 internalNodeIndex = 8;
        bytes[] memory internalNodeSignatures = new bytes[](2);
        internalNodeSignatures[0] = signatures[0];
        internalNodeSignatures[1] = signatures[1];

        bool isValidInternal =
            committee.verifySignaturesFromNode(internalNodeIndex, message, internalNodeSignatures);
        assertTrue(isValidInternal, "Signatures should be valid for the internal node");
    }

    function testVerifySignaturesForLargeCommittee() public {
        uint256 numParticipants = 256;
        committee = new Committee(numParticipants);

        address[] memory signingKeys = new address[](numParticipants);

        for (uint256 i = 0; i < numParticipants; i++) {
            signingKeys[i] = vm.addr(i + 1);
            vm.prank(signingKeys[i]);
            committee.addParticipant(20, signingKeys[i]);
        }

        bytes32 message = keccak256("Large committee test message");

        // Verify signatures from internal node 8
        uint256 internalNodeIndex = 8;
        uint256 internalNode8Participants = 32;
        bytes[] memory signatures = new bytes[](internalNode8Participants);

        for (uint256 i = 0; i < internalNode8Participants; i++) {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(i + 1, message);
            signatures[i] = abi.encodePacked(r, s, v);
        }

        bool isValid = committee.verifySignaturesFromNode(internalNodeIndex, message, signatures);

        assertTrue(isValid, "Signatures should be valid for internal node 8 in a large committee");
    }
}
