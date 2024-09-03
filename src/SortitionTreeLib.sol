// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SortitionTreeLib
/// @notice A library for implementing a sortition tree data structure
/// @dev This library provides functions to manage a weighted tree for random selection
library SortitionTreeLib {
    struct Tree {
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
    error RandomValueOutOfRange();

    /// @notice Initializes the tree with a given capacity
    /// @param self The Tree struct
    /// @param initialCapacity The initial capacity of the tree
    function initialize(Tree storage self, uint256 initialCapacity) internal {
        if (initialCapacity <= 0) {
            revert InitialCapacityMustBeGreaterThanZero();
        }
        if (self.capacity != 0) {
            revert TreeAlreadyInitialized();
        }
        self.leafCount = 0;
        self.capacity = initialCapacity;
    }

    /// @notice Adds a new participant to the tree
    /// @param self The Tree struct
    /// @param weight The weight of the new participant
    /// @return participantIndex The index of the newly added participant
    function add(Tree storage self, uint256 weight) internal returns (uint256 participantIndex) {
        if (weight <= 0) {
            revert WeightMustBeGreaterThanZero();
        }
        if (self.leafCount >= self.capacity) {
            revert TreeCapacityReached();
        }

        participantIndex = self.leafCount + 1;
        uint256 nodeIndex = participantIndex + self.capacity - 1;

        self.nodes[nodeIndex] = weight;
        self.leafCount++;

        while (nodeIndex > 1) {
            nodeIndex /= 2;
            self.nodes[nodeIndex] += weight;
        }

        return participantIndex;
    }

    /// @notice Updates the weight of a leaf
    /// @param self The Tree struct
    /// @param leafIndex The index of the leaf to update
    /// @param newWeight The new weight for the leaf
    function update(Tree storage self, uint256 leafIndex, uint256 newWeight) internal {
        if (leafIndex <= 0 || leafIndex > self.leafCount) {
            revert InvalidLeafIndex();
        }
        if (newWeight <= 0) {
            revert WeightMustBeGreaterThanZero();
        }

        uint256 nodeIndex = leafIndex + self.capacity - 1;
        uint256 weightDifference = newWeight > self.nodes[nodeIndex]
            ? newWeight - self.nodes[nodeIndex]
            : self.nodes[nodeIndex] - newWeight;

        bool isIncrease = newWeight > self.nodes[nodeIndex];

        while (nodeIndex > 0) {
            if (isIncrease) {
                self.nodes[nodeIndex] += weightDifference;
            } else {
                self.nodes[nodeIndex] -= weightDifference;
            }
            nodeIndex /= 2;
        }
    }

    /// @notice Selects a leaf based on a random value
    /// @param self The Tree struct
    /// @param randomValue A random value used for selection
    /// @return selectedLeaf The index of the selected leaf
    function select(
        Tree storage self,
        uint256 randomValue
    ) internal view returns (uint256 selectedLeaf) {
        if (self.leafCount == 0) {
            revert TreeIsEmpty();
        }
        if (randomValue >= getTotalWeight(self)) {
            revert RandomValueOutOfRange();
        }

        uint256 nodeIndex = 1;
        while (nodeIndex < self.capacity) {
            nodeIndex *= 2;
            if (randomValue >= self.nodes[nodeIndex]) {
                randomValue -= self.nodes[nodeIndex];
                nodeIndex++;
            }
        }

        return nodeIndex - self.capacity + 1;
    }

    /// @notice Gets the total weight of the tree
    /// @param self The Tree struct
    /// @return The total weight
    function getTotalWeight(Tree storage self) internal view returns (uint256) {
        return self.nodes[1];
    }

    /// @notice Gets the weight of a specific leaf
    /// @param self The Tree struct
    /// @param leafIndex The index of the leaf
    /// @return The weight of the leaf
    function getLeafWeight(Tree storage self, uint256 leafIndex) internal view returns (uint256) {
        if (leafIndex <= 0 || leafIndex > self.leafCount) {
            revert InvalidLeafIndex();
        }
        return self.nodes[leafIndex + self.capacity - 1];
    }
}
