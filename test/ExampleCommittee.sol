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

    mapping(uint256 => bytes32) public participantSigningKeyTree;
    mapping(address => uint256) public participantLeafIndices;

    constructor() {
        tree.initialize(INITIAL_CAPACITY);
    }

    function addParticipant(uint256 weight, address signingKey) external {
        require(
            weight >= MIN_PARTICIPANT_WEIGHT && weight <= MAX_PARTICIPANT_WEIGHT,
            "Weight out of range"
        );
        uint256 leafIndex = tree.add(weight);

        uint256 leafNodeIndex =
            SortitionTreeLib.leafIndexToNodeArrayIndex(leafIndex, INITIAL_CAPACITY);
        participantSigningKeyTree[leafNodeIndex] = bytes32(uint256(uint160(signingKey)));
        /// TODO: Handle if they're already added
        participantLeafIndices[msg.sender] = leafIndex;

        updateAggregateKeyHashes(leafIndex);
    }

    function updateParticipant(uint256 participantIndex, uint256 newWeight) external {
        require(
            newWeight >= MIN_PARTICIPANT_WEIGHT && newWeight <= MAX_PARTICIPANT_WEIGHT,
            "Weight out of range"
        );
        require(participantLeafIndices[msg.sender] == participantIndex, "Not the participant");
        tree.update(participantIndex, newWeight);
    }

    function updateParticipantSigningKey(
        uint256 participantIndex,
        address newSigningKey
    ) external {
        require(participantLeafIndices[msg.sender] == participantIndex, "Not the participant");
        require(
            participantIndex > 0 && participantIndex <= tree.getLeafCount(),
            "Invalid participant index"
        );

        uint256 leafNodeIndex =
            SortitionTreeLib.leafIndexToNodeArrayIndex(participantIndex, INITIAL_CAPACITY);
        participantSigningKeyTree[leafNodeIndex] = bytes32(uint256(uint160(newSigningKey)));

        updateAggregateKeyHashes(participantIndex);
    }

    function removeParticipant(
        uint256 participantIndex
    ) external {
        require(
            participantIndex > 0 && participantIndex <= tree.getLeafCount(),
            "Invalid participant index"
        );
        require(participantLeafIndices[msg.sender] == participantIndex, "Not the participant");
        tree.remove(participantIndex);
        uint256 participantNodeIndex =
            SortitionTreeLib.leafIndexToNodeArrayIndex(participantIndex, INITIAL_CAPACITY);
        delete participantSigningKeyTree[participantNodeIndex];
        delete participantLeafIndices[msg.sender];

        updateAggregateKeyHashes(participantIndex);
    }

    function updateAggregateKeyHashes(
        uint256 leafIndex
    ) internal {
        uint256 nodeIndex = SortitionTreeLib.leafIndexToNodeArrayIndex(leafIndex, INITIAL_CAPACITY);

        // Initialize the current hash with the participant's signing key
        bytes32 currentHash = participantSigningKeyTree[nodeIndex];

        // Traverse up the tree and update parent hashes
        while (nodeIndex > 1) {
            uint256 parentIndex = nodeIndex / 2;
            uint256 leftChildIndex = parentIndex * 2;
            uint256 rightChildIndex = leftChildIndex + 1;

            bytes32 leftHash = participantSigningKeyTree[leftChildIndex];
            bytes32 rightHash = participantSigningKeyTree[rightChildIndex];

            // Handle missing child hashes
            if (leftHash == bytes32(0)) {
                leftHash = bytes32(0);
            }
            if (rightHash == bytes32(0)) {
                rightHash = bytes32(0);
            }

            // Update the parent hash
            participantSigningKeyTree[parentIndex] =
                keccak256(abi.encodePacked(leftHash, rightHash));

            nodeIndex = parentIndex;
        }
    }

    function verifySignaturesFromNode(
        uint256 nodeIndex,
        bytes32 message,
        bytes[] calldata signatures
    ) external view returns (bool) {
        require(nodeIndex > 0 && nodeIndex < INITIAL_CAPACITY, "Invalid node index");

        // Get the leaf indices under the node
        uint256[] memory leafIndices = tree.getSubtreeLeafIndexes(nodeIndex);
        require(
            signatures.length == leafIndices.length,
            "Signature count does not match number of leaves"
        );

        bytes32[] memory expectedKeys = new bytes32[](leafIndices.length);
        for (uint256 i = 0; i < leafIndices.length; i++) {
            uint256 leafNodeIndex =
                SortitionTreeLib.leafIndexToNodeArrayIndex(leafIndices[i], INITIAL_CAPACITY);
            expectedKeys[i] = participantSigningKeyTree[leafNodeIndex];
        }

        for (uint256 i = 0; i < signatures.length; i++) {
            address recoveredSigner = recoverSigner(message, signatures[i]);
            bytes32 recoveredKey = bytes32(uint256(uint160(recoveredSigner)));
            require(recoveredKey == expectedKeys[i], "Recovered signer does not match expected key");
        }

        return true;
    }

    function setCommitteeRoot(
        uint256 newCommitteeRoot
    ) external {
        require(
            newCommitteeRoot > 0 && newCommitteeRoot < INITIAL_CAPACITY, "Invalid committee root"
        );
        uint256 subtreeWeight = tree.getSubtreeWeight(newCommitteeRoot);
        require(
            subtreeWeight >= MIN_COMMITTEE_WEIGHT && subtreeWeight <= MAX_COMMITTEE_WEIGHT,
            "Subtree weight out of bounds"
        );

        committeeRoot = newCommitteeRoot;
    }

    function selectCommittee(
        bytes32 seed
    ) external {
        committeeRoot = tree.selectSubtree(seed, MAX_COMMITTEE_WEIGHT, MIN_COMMITTEE_WEIGHT);
    }

    function getCommitteeMembers() external view returns (uint256[] memory) {
        require(committeeRoot != 0, "Committee not selected");
        return tree.getSubtreeLeafIndexes(committeeRoot);
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

    function getRootHash() external view returns (bytes32) {
        return participantSigningKeyTree[1];
    }

    function recoverSigner(
        bytes32 messageHash,
        bytes memory signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(messageHash, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Invalid signature 'v' value");
    }

    function computeNodeHash(
        bytes32[] memory keys
    ) internal pure returns (bytes32) {
        if (keys.length == 1) {
            return keys[0];
        }

        bytes32[] memory nextLevel = new bytes32[]((keys.length + 1) / 2);
        for (uint256 i = 0; i < keys.length; i += 2) {
            if (i + 1 < keys.length) {
                nextLevel[i / 2] = keccak256(abi.encodePacked(keys[i], keys[i + 1]));
            } else {
                nextLevel[i / 2] = keys[i];
            }
        }

        return computeNodeHash(nextLevel);
    }
}
