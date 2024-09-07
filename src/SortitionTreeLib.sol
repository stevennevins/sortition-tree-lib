// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RandomNumberLib} from "./RandomNumberLib.sol";
/// @title SortitionTreeLib
/// @notice A library for implementing a sortition tree data structure
/// @dev This library provides functions to manage a weighted tree for random selection

library SortitionTreeLib {
    uint256 private constant ROOT_INDEX = 1;

    /// TODO: Update function pointer
    /// It should take in LeafIndex/NodeIndex.  This will give it access to the previous value to
    /// Calculate diffs against to update parents.  The updateParents flow should have an abstraction
    /// To receive arbitrary data to update the node appropriately
    struct SortitionTree {
        /// @dev nodes represents a binary tree structure stored as an array
        /// The first `capacity - 1` elements are internal nodes (non-leaves)
        /// The leaves start at index `capacity` and go up to `2 * capacity - 1`
        ///
        /// Visual representation with 8 leaves:
        ///
        ///                 1
        ///         2               3
        ///     4       5       6       7
        ///   8   9   10  11  12  13  14  15
        ///
        /// Array indices:  [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
        /// Node types:     [E, R, I, I, I, I, I, I, L, L,  L,  L,  L,  L,  L,  L]
        ///
        /// Where E = Empty, R = Root, I = Internal Node, L = Leaf
        ///
        mapping(uint256 => uint256) nodes;
        uint256 leafCount;
        uint256 capacity;
    }

    error InitialCapacityMustBeGreaterThanZero();
    error TreeAlreadyInitialized();
    error WeightMustBeGreaterThanZero();
    error TreeCapacityReached();
    error InvalidLeafIndex();
    error TreeIsEmpty();
    error QuantityMustBeGreaterThanZero();

    /// @notice Initializes the tree with a given capacity
    /// @param tree The Tree struct
    /// @param initialCapacity The initial capacity of the tree
    function initialize(SortitionTree storage tree, uint256 initialCapacity) internal {
        if (initialCapacity <= 0) {
            revert InitialCapacityMustBeGreaterThanZero();
        }
        if (tree.capacity != 0) {
            revert TreeAlreadyInitialized();
        }
        tree.leafCount = 0;
        tree.capacity = initialCapacity;
    }

    /// @notice Adds a new participant to the tree
    /// @param tree The Tree struct
    /// @param weight The weight of the new participant
    /// @return participantIndex The index of the newly added participant
    function add(
        SortitionTree storage tree,
        uint256 weight
    ) internal returns (uint256 participantIndex) {
        if (weight <= 0) {
            revert WeightMustBeGreaterThanZero();
        }
        if (tree.leafCount >= tree.capacity) {
            revert TreeCapacityReached();
        }

        participantIndex = tree.leafCount + 1;
        uint256 nodeIndex = participantIndex + tree.capacity - 1;

        tree.nodes[nodeIndex] = weight;
        tree.leafCount++;

        while (nodeIndex > 1) {
            nodeIndex /= 2;
            tree.nodes[nodeIndex] += weight;
        }

        return participantIndex;
    }

    /// @notice Updates the weight of a leaf
    /// @param tree The Tree struct
    /// @param leafIndex The index of the leaf to update
    /// @param newWeight The new weight for the leaf
    function update(SortitionTree storage tree, uint256 leafIndex, uint256 newWeight) internal {
        if (!isValidLeafIndex(tree, leafIndex)) {
            revert InvalidLeafIndex();
        }
        if (newWeight <= 0) {
            revert WeightMustBeGreaterThanZero();
        }

        uint256 nodeIndex = leafIndex + tree.capacity - 1;
        uint256 weightDifference = newWeight > tree.nodes[nodeIndex]
            ? newWeight - tree.nodes[nodeIndex]
            : tree.nodes[nodeIndex] - newWeight;

        bool isIncrease = newWeight > tree.nodes[nodeIndex];

        while (nodeIndex > 0) {
            if (isIncrease) {
                tree.nodes[nodeIndex] += weightDifference;
            } else {
                tree.nodes[nodeIndex] -= weightDifference;
            }
            nodeIndex /= 2;
        }
    }

    /// @notice Selects a leaf based on a random value
    /// @param tree The Tree struct
    /// @param seed A random value used for selection
    /// @return selectedLeaf The index of the selected leaf
    function select(
        SortitionTree storage tree,
        uint256 seed
    ) internal view returns (uint256 selectedLeaf) {
        if (tree.leafCount == 0) {
            revert TreeIsEmpty();
        }
        uint256 value = RandomNumberLib.generate(seed, getTotalWeight(tree));

        /// Start off at the root
        uint256 nodeIndex = ROOT_INDEX;

        while (nodeIndex < tree.capacity) {
            nodeIndex *= 2;
            if (value >= tree.nodes[nodeIndex]) {
                value -= tree.nodes[nodeIndex];
                nodeIndex++;
            }
        }

        return nodeIndex - tree.capacity + 1;
    }

    /// @notice Selects multiple leaves based on a single input seed
    /// @param tree The Tree struct
    /// @param seed A random value used for selection
    /// @param quantity The number of leaves to select
    /// @return selectedLeaves An array of indices of the selected leaves
    function selectMultiple(
        SortitionTree storage tree,
        uint256 seed,
        uint256 quantity
    ) internal view returns (uint256[] memory) {
        if (quantity == 0) {
            revert QuantityMustBeGreaterThanZero();
        }

        uint256[] memory selectedLeaves = new uint256[](quantity);
        for (uint256 i = 0; i < quantity; i++) {
            uint256 newSeed = uint256(keccak256(abi.encodePacked(seed, i)));
            selectedLeaves[i] = select(tree, newSeed);
        }

        return selectedLeaves;
    }

    /// @notice Gets the total weight of the tree
    /// @param tree The Tree struct
    /// @return The total weight
    function getTotalWeight(
        SortitionTree storage tree
    ) internal view returns (uint256) {
        return tree.nodes[ROOT_INDEX];
    }

    /// @notice Gets the weight of a specific leaf
    /// @param tree The Tree struct
    /// @param leafIndex The index of the leaf
    /// @return The weight of the leaf
    function getLeafWeight(
        SortitionTree storage tree,
        uint256 leafIndex
    ) internal view returns (uint256) {
        if (!isValidLeafIndex(tree, leafIndex)) {
            revert InvalidLeafIndex();
        }
        return tree.nodes[leafIndex + tree.capacity - 1];
    }

    function isValidLeafIndex(
        SortitionTree storage tree,
        uint256 leafIndex
    ) private view returns (bool) {
        return leafIndex > 0 && leafIndex <= tree.leafCount;
    }

    function leafToNodeIndex(
        SortitionTree storage tree,
        uint256 leafIndex
    ) private view returns (uint256) {
        return leafIndex + tree.capacity - 1;
    }

    function nodeToLeafIndex(
        SortitionTree storage tree,
        uint256 nodeIndex
    ) private view returns (uint256) {
        return nodeIndex - tree.capacity + 1;
    }
}
