// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RandomNumberLib} from "./RandomNumberLib.sol";

/// @title SortitionTreeLib
/// @notice A library for implementing a sortition tree data structure
/// @dev This library provides functions to manage a weighted tree for random selection
library SortitionTreeLib {
    uint256 internal constant ROOT_INDEX = 1;

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
        /// Leaf indices:   [E, E, E, E, E, E, E, E, 1, 2,  3,  4,  5,  6,  7,  8]
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
    error MinimumWeightExceedsTotalWeight();
    error InvalidSubtreeSelection();
    error ParentNodeIndexIsLeaf();
    error NodeIndexOutOfBounds();
    error SubtreeDepthIsZero();

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
        uint256 nodeIndex = leafIndexToNodeArrayIndex(tree, participantIndex);

        tree.nodes[nodeIndex] = weight;
        tree.leafCount++;

        updateParentWeights(tree, nodeIndex, int256(weight));

        return participantIndex;
    }

    /// @notice Updates the weight of a leaf
    /// @param tree The Tree struct
    /// @param leafIndex The index of the leaf to update
    /// @param newWeight The new weight for the leaf
    function update(SortitionTree storage tree, uint256 leafIndex, uint256 newWeight) internal {
        if (newWeight <= 0) {
            revert WeightMustBeGreaterThanZero();
        }
        updateWeight(tree, leafIndex, newWeight);
    }

    /// @notice Removes a leaf from the tree
    /// @dev If the leaf to remove is not the last leaf, it swaps with the last leaf before removal
    /// @param tree The Tree struct
    /// @param leafIndex The index of the leaf to remove
    function remove(SortitionTree storage tree, uint256 leafIndex) internal {
        require(leafIndex <= tree.leafCount, "Doesn't exist");

        uint256 lastLeafIndex = tree.leafCount;
        uint256 lastLeafWeight = getLeafWeight(tree, lastLeafIndex);

        updateWeight(tree, lastLeafIndex, 0);
        tree.leafCount--;
        if (leafIndex != lastLeafIndex) {
            updateWeight(tree, leafIndex, lastLeafWeight);
        }
    }

    /// @notice Selects a leaf based on a random value
    /// @param tree The Tree struct
    /// @param seed A random value used for selection
    /// @return selectedLeaf The index of the selected leaf
    function select(
        SortitionTree storage tree,
        bytes32 seed
    ) internal view returns (uint256 selectedLeaf) {
        if (tree.leafCount == 0) {
            revert TreeIsEmpty();
        }
        uint256 value = RandomNumberLib.generate(uint256(seed), getTotalWeight(tree));

        uint256 nodeIndex = traverseTree(tree, value);

        return nodeArrayIndexToLeafIndex(tree, nodeIndex);
    }

    /// @notice Selects multiple leaves based on a single input seed
    /// @param tree The Tree struct
    /// @param seed A random value used for selection
    /// @param quantity The number of leaves to select
    /// @return selectedLeaves An array of indices of the selected leaves
    function selectMultiple(
        SortitionTree storage tree,
        bytes32 seed,
        uint256 quantity
    ) internal view returns (uint256[] memory) {
        if (quantity == 0) {
            revert QuantityMustBeGreaterThanZero();
        }

        uint256[] memory selectedLeaves = new uint256[](quantity);
        for (uint256 i = 0; i < quantity; i++) {
            bytes32 newSeed = keccak256(abi.encodePacked(seed, i));
            selectedLeaves[i] = select(tree, newSeed);
        }

        return selectedLeaves;
    }

    /// @notice Selects a subtree from tree that represents at least minimumWeight
    /// @dev This version randomly selects a leaf and then traverses up the tree
    /// @param tree The Tree struct
    /// @param seed A random value used for selection
    /// @param maxWeight The maximum weight of the subtree
    /// @param minimumWeight The minimum weight of the subtree
    /// @return parentNodeIndex The index of the selected parent node
    function selectSubTree(
        SortitionTree storage tree,
        bytes32 seed,
        uint256 maxWeight,
        uint256 minimumWeight
    ) internal view returns (uint256 parentNodeIndex) {
        uint256 totalTreeWeight = getTotalWeight(tree);
        if (minimumWeight > totalTreeWeight) {
            revert MinimumWeightExceedsTotalWeight();
        }

        // Randomly select a leaf
        uint256 selectedLeaf = select(tree, seed);
        uint256 nodeIndex = leafIndexToNodeArrayIndex(tree, selectedLeaf);

        // Traverse up the tree an return the subtree parent node that meets weight requirements
        while (nodeIndex > ROOT_INDEX) {
            uint256 subtreeWeight = tree.nodes[nodeIndex];
            if (subtreeWeight >= minimumWeight) {
                if (subtreeWeight > maxWeight) {
                    /// TODO: Depth check as well
                    /// Recurse if not valid
                    selectSubTree(tree, keccak256(bytes.concat(seed)), minimumWeight, maxWeight);
                } else {
                    return nodeIndex;
                }
            }
            nodeIndex = getParentNode(nodeIndex);
        }

        revert InvalidSubtreeSelection();
    }

    /// @notice Selects a leaf node from a specific subtree within the sortition tree
    /// @dev Uses a random seed to traverse the subtree and select a leaf
    /// @param tree The SortitionTree struct
    /// @param seed A random value used for selection
    /// @param parentNodeIndex The index of the parent node of the subtree to select from
    /// @return The index of the selected leaf node
    function selectFromSubtree(
        SortitionTree storage tree,
        bytes32 seed,
        uint256 parentNodeIndex
    ) internal view returns (uint256) {
        if (isLeafNode(tree, parentNodeIndex)) {
            revert ParentNodeIndexIsLeaf();
        }
        uint256 subtreeWeight = tree.nodes[parentNodeIndex];
        uint256 targetWeight = RandomNumberLib.generate(uint256(seed), subtreeWeight);
        uint256 nodeIndex = tranverseTreeFromNode(tree, targetWeight, parentNodeIndex);
        return nodeArrayIndexToLeafIndex(tree, nodeIndex);
    }

    /// @notice Selects multiple leaf nodes from a specific subtree within the sortition tree
    /// @dev Uses a random seed to repeatedly call selectFromSubtree for the specified quantity
    /// @param tree The SortitionTree struct
    /// @param seed A random value used as the base for selection
    /// @param quantity The number of leaf nodes to select
    /// @param parentNodeIndex The index of the parent node of the subtree to select from
    /// @return An array of selected leaf node indices
    function selectMultipleFromSubtree(
        SortitionTree storage tree,
        bytes32 seed,
        uint256 quantity,
        uint256 parentNodeIndex
    ) internal view returns (uint256[] memory) {
        uint256[] memory selectedLeaves = new uint256[](quantity);

        for (uint256 i = 0; i < quantity; i++) {
            bytes32 newSeed = keccak256(abi.encodePacked(seed, i));
            selectedLeaves[i] = selectFromSubtree(tree, newSeed, parentNodeIndex);
        }

        return selectedLeaves;
    }

    /// @notice Checks if a leaf node is within a specific subtree
    /// @dev Traverses up the tree from the leaf node to see if it reaches the parent node
    /// @param tree The SortitionTree struct
    /// @param parentNodeIndex The index of the parent node defining the subtree
    /// @param leafNodeIndex The index of the leaf node to check
    /// @return bool True if the leaf node is in the subtree, false otherwise
    function isInSubtree(
        SortitionTree storage tree,
        uint256 parentNodeIndex,
        uint256 leafNodeIndex
    ) internal view returns (bool) {
        uint256 nodeIndex = leafIndexToNodeArrayIndex(tree, leafNodeIndex);

        while (nodeIndex > parentNodeIndex) {
            nodeIndex = getParentNode(nodeIndex);
        }

        return nodeIndex == parentNodeIndex;
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
        return tree.nodes[leafIndexToNodeArrayIndex(tree, leafIndex)];
    }

    /// @notice Checks if a given leaf index is valid for the tree
    /// @param tree The SortitionTree struct
    /// @param leafIndex The index of the leaf to check
    /// @return bool True if the leaf index is valid, false otherwise
    function isValidLeafIndex(
        SortitionTree storage tree,
        uint256 leafIndex
    ) internal view returns (bool) {
        return leafIndex > 0 && leafIndex <= tree.leafCount;
    }

    /// @notice Converts a leaf index to its corresponding node array index
    /// @param tree The SortitionTree struct
    /// @param leafIndex The index of the leaf
    /// @return The corresponding node array index
    function leafIndexToNodeArrayIndex(
        SortitionTree storage tree,
        uint256 leafIndex
    ) internal view returns (uint256) {
        return leafIndex + tree.capacity - 1;
    }

    /// @notice Converts a node array index to its corresponding leaf index
    /// @dev This function is the inverse of leafIndexToNodeArrayIndex
    /// @param tree The SortitionTree struct
    /// @param nodeIndex The index of the node in the array
    /// @return The corresponding leaf index
    function nodeArrayIndexToLeafIndex(
        SortitionTree storage tree,
        uint256 nodeIndex
    ) internal view returns (uint256) {
        return nodeIndex - tree.capacity + 1;
    }

    /// @notice Traverses the tree from a given parent node to find a leaf based on a random value
    /// @param tree The SortitionTree struct
    /// @param value A random value used for traversal
    /// @param parentNodeIndex The index of the parent node to start traversal from
    /// @return The index of the selected leaf node
    function tranverseTreeFromNode(
        SortitionTree storage tree,
        uint256 value,
        uint256 parentNodeIndex
    ) internal view returns (uint256) {
        uint256 nodeIndex = parentNodeIndex;
        while (nodeIndex < tree.capacity) {
            nodeIndex *= 2;
            if (value >= tree.nodes[nodeIndex]) {
                value -= tree.nodes[nodeIndex];
                nodeIndex++;
            }
        }
        return nodeIndex;
    }

    /// @notice Traverses the tree from the root to find a leaf based on a random value
    /// @param tree The SortitionTree struct
    /// @param value A random value used for traversal
    /// @return The index of the selected leaf node
    function traverseTree(
        SortitionTree storage tree,
        uint256 value
    ) internal view returns (uint256) {
        return tranverseTreeFromNode(tree, value, ROOT_INDEX);
    }

    function getSubTreeLeaves(
        SortitionTree storage tree,
        uint256 parentNodeIndex
    ) internal view returns (uint256[] memory) {
        uint256[] memory leafNodeIndexes;
        uint256 nodeIndex = parentNodeIndex;
        while (nodeIndex < tree.capacity) {
            nodeIndex *= 2;
        }
        return leafNodeIndexes;
    }

    function getSubtreeLeafCount(
        SortitionTree storage tree,
        uint256 parentNodeIndex
    ) internal view returns (uint256) {
        if (isLeafNode(tree, parentNodeIndex)) {
            revert ParentNodeIndexIsLeaf();
        }

        uint256 subtreeDepth = getSubtreeDepth(tree, parentNodeIndex);
        uint256 maxLeafCount = 2 ** (subtreeDepth - 1);
        uint256 leftmostLeafIndex = parentNodeIndex * (2 ** (subtreeDepth - 1));

        uint256 actualLeafCount = 0;
        for (uint256 i = 0; i < maxLeafCount; i++) {
            if (leftmostLeafIndex + i >= tree.capacity + tree.leafCount) {
                break;
            }
            if (isLeafNode(tree, leftmostLeafIndex + i)) {
                actualLeafCount++;
            }
        }

        return actualLeafCount;
    }

    function isLeafNode(
        SortitionTree storage tree,
        uint256 nodeIndex
    ) internal view returns (bool) {
        // A node is a leaf if its index is greater than or equal to the capacity
        // and less than or equal to the capacity plus the number of leaves
        return nodeIndex >= tree.capacity && nodeIndex < tree.capacity + tree.leafCount;
    }

    function getTreeDepth(
        SortitionTree storage tree
    ) internal view returns (uint256) {
        return getSubtreeDepth(tree, ROOT_INDEX);
    }

    function getSubtreeDepth(
        SortitionTree storage tree,
        uint256 nodeIndex
    ) internal view returns (uint256) {
        uint256 depth;

        if (nodeIndex > tree.capacity + tree.leafCount) {
            revert NodeIndexOutOfBounds();
        }
        uint256 currentIndex = nodeIndex;

        while (currentIndex < tree.capacity) {
            depth++;
            currentIndex *= 2;
        }

        if (depth == 0) {
            revert SubtreeDepthIsZero();
        }

        return depth + 1;
    }

    function getLeafCount(
        SortitionTree storage tree
    ) internal view returns (uint256) {
        return tree.leafCount;
    }

    function getSubtreeWeight(
        SortitionTree storage tree,
        uint256 parentNodeIndex
    ) internal view returns (uint256) {
        if (parentNodeIndex >= tree.capacity + tree.leafCount) {
            revert NodeIndexOutOfBounds();
        }

        if (isLeafNode(tree, parentNodeIndex)) {
            revert ParentNodeIndexIsLeaf();
        }

        return tree.nodes[parentNodeIndex];
    }

    function getChildNodes(
        uint256 nodeIndex
    ) internal pure returns (uint256 left, uint256 right) {
        left = nodeIndex * 2;
        right = left + 1;
    }

    function getParentNode(
        uint256 nodeIndex
    ) internal pure returns (uint256) {
        return nodeIndex / 2;
    }

    function updateWeight(
        SortitionTree storage tree,
        uint256 leafIndex,
        uint256 newWeight
    ) private {
        uint256 oldWeight = getLeafWeight(tree, leafIndex);
        int256 weightDifference = int256(newWeight) - int256(oldWeight);
        uint256 nodeIndex = leafIndexToNodeArrayIndex(tree, leafIndex);
        tree.nodes[nodeIndex] = newWeight;

        updateParentWeights(tree, nodeIndex, weightDifference);
    }

    function updateParentWeights(
        SortitionTree storage tree,
        uint256 nodeIndex,
        int256 weightDifference
    ) private {
        while (nodeIndex > ROOT_INDEX) {
            nodeIndex /= 2;
            uint256 parentWeight = tree.nodes[nodeIndex];
            tree.nodes[nodeIndex] = uint256(int256(parentWeight) + weightDifference);
        }
    }
}
