// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/SortitionTreeLib.sol";

contract SortitionTreeHarness {
    using SortitionTreeLib for SortitionTreeLib.SortitionTree;

    SortitionTreeLib.SortitionTree private tree;

    function initialize(
        uint256 initialCapacity
    ) external {
        tree.initialize(initialCapacity);
    }

    function add(
        uint256 weight
    ) external returns (uint256) {
        return tree.add(weight);
    }

    function update(uint256 leafIndex, uint256 newWeight) external {
        tree.update(leafIndex, newWeight);
    }

    function select(
        bytes32 seed
    ) external view returns (uint256) {
        return tree.select(seed);
    }

    function selectMultiple(
        bytes32 seed,
        uint256 quantity
    ) external view returns (uint256[] memory) {
        return tree.selectMultiple(seed, quantity);
    }

    function selectSubtree(
        bytes32 seed,
        uint256 maxWeight,
        uint256 minimumWeight
    ) external view returns (uint256) {
        return tree.selectSubtree(seed, maxWeight, minimumWeight);
    }

    function selectFromSubtree(
        bytes32 seed,
        uint256 parentNodeIndex
    ) external view returns (uint256) {
        return tree.selectFromSubtree(seed, parentNodeIndex);
    }

    function selectMultipleFromSubtree(
        bytes32 seed,
        uint256 quantity,
        uint256 parentNodeIndex
    ) external view returns (uint256[] memory) {
        return tree.selectMultipleFromSubtree(seed, quantity, parentNodeIndex);
    }

    function isInSubtree(
        uint256 parentNodeIndex,
        uint256 leafNodeIndex
    ) external view returns (bool) {
        return tree.isInSubtree(parentNodeIndex, leafNodeIndex);
    }

    function getTotalWeight() external view returns (uint256) {
        return tree.getTotalWeight();
    }

    function getLeafWeight(
        uint256 leafIndex
    ) external view returns (uint256) {
        return tree.getLeafWeight(leafIndex);
    }

    function getSubtreeLeaves(
        uint256 parentNodeIndex
    ) external view returns (uint256[] memory) {
        return tree.getSubtreeLeaves(parentNodeIndex);
    }

    function getSubtreeLeafCount(
        uint256 parentNodeIndex
    ) external view returns (uint256) {
        return tree.getSubtreeLeafCount(parentNodeIndex);
    }

    function getChildNodes(
        uint256 nodeIndex
    ) external pure returns (uint256 left, uint256 right) {
        return SortitionTreeLib.getChildNodes(nodeIndex);
    }

    function getParentNode(
        uint256 nodeIndex
    ) external pure returns (uint256) {
        return SortitionTreeLib.getParentNode(nodeIndex);
    }

    function isLeafNode(
        uint256 nodeIndex
    ) external view returns (bool) {
        return tree.isLeafNode(nodeIndex);
    }

    function getSubtreeDepth(
        uint256 nodeIndex
    ) external view returns (uint256) {
        return tree.getSubtreeDepth(nodeIndex);
    }

    function getSubtreeWeight(
        uint256 nodeIndex
    ) external view returns (uint256) {
        return tree.getSubtreeWeight(nodeIndex);
    }

    function isValidLeafIndex(
        uint256 leafIndex
    ) external view returns (bool) {
        return tree.isValidLeafIndex(leafIndex);
    }

    function traverseSubtree(
        uint256 value
    ) external view returns (uint256) {
        return tree.traverseTree(value);
    }
}
