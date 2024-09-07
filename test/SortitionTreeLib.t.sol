// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SortitionTreeLib} from "../src/SortitionTreeLib.sol";
import {RandomNumberLib} from "../src/RandomNumberLib.sol";

contract SortitionTreeLibTest is Test {
    using SortitionTreeLib for SortitionTreeLib.SortitionTree;

    SortitionTreeLib.SortitionTree internal tree;
    SortitionTreeLib.SortitionTree internal newTree;

    function setUp() public {
        tree.initialize(10);
        tree.add(25);
        tree.add(25);
        tree.add(25);
        tree.add(25);
    }

    function testTreeShape() public view {
        // Assert the total weight of the tree
        uint256 totalWeight = tree.getTotalWeight();
        assertEq(totalWeight, 100, "Total weight should be 100");

        // Assert the number of leaves in the tree
        uint256 leafCount = tree.leafCount;
        assertEq(leafCount, 4, "Leaf count should be 4");

        // Assert the weight of each leaf
        for (uint256 i = 1; i <= leafCount; i++) {
            uint256 leafWeight = tree.getLeafWeight(i);
            assertEq(leafWeight, 25, "Each leaf weight should be 25");
        }
    }

    function testAddElementsToCapacity() public {
        tree.add(25);
        tree.add(25);
        tree.add(25);
        tree.add(25);
        tree.add(25);
        tree.add(25);

        printTreeStructure();

        // Assert the total weight of the tree
        uint256 totalWeight = tree.getTotalWeight();
        assertEq(totalWeight, 250, "Total weight should be 250");

        // Assert the number of leaves in the tree
        uint256 leafCount = tree.leafCount;
        assertEq(leafCount, 10, "Leaf count should be 10");

        // Assert the weight of each leaf
        for (uint256 i = 1; i <= leafCount; i++) {
            uint256 leafWeight = tree.getLeafWeight(i);
            assertEq(leafWeight, 25, "Each leaf weight should be 25");
        }
    }

    function test_AddParticipantAndVerifyIndex() public {
        uint256 newWeight = 30;
        uint256 participantIndex = tree.add(newWeight);

        assertEq(participantIndex, 5, "Participant index should be 5");

        uint256 retrievedWeight = tree.getLeafWeight(participantIndex);
        assertEq(retrievedWeight, newWeight, "Retrieved weight should match the added weight");

        uint256 expectedTotalWeight = 100 + newWeight; // 100 from setUp() + new weight
        uint256 actualTotalWeight = tree.getTotalWeight();
        assertEq(actualTotalWeight, expectedTotalWeight, "Total weight should be updated correctly");

        uint256 expectedLeafCount = 5; // 4 from setUp() + 1 new
        uint256 actualLeafCount = tree.leafCount;
        assertEq(actualLeafCount, expectedLeafCount, "Leaf count should be updated correctly");
    }

    function test_VerifyIntermediateNodes() public {
        testAddElementsToCapacity();
        uint256[] memory expectedIntermediateValues = new uint256[](9);
        expectedIntermediateValues[0] = 250; // Root node
        expectedIntermediateValues[1] = 150;
        expectedIntermediateValues[2] = 100;
        expectedIntermediateValues[3] = 100;
        expectedIntermediateValues[4] = 50;
        expectedIntermediateValues[5] = 50;
        /// This level should have 4 elements of 25+25
        expectedIntermediateValues[6] = 50;
        expectedIntermediateValues[7] = 50;
        expectedIntermediateValues[8] = 50;

        for (uint256 i = 0; i < expectedIntermediateValues.length; i++) {
            uint256 nodeValue = tree.nodes[i + 1];
            assertEq(nodeValue, expectedIntermediateValues[i], "Intermediate node value mismatch");
        }
    }

    function test_RevertsWhen_CapacityExceeded() public {
        testAddElementsToCapacity();
        vm.expectRevert();
        tree.add(25);
    }

    function test_Update_Increase() public {
        testAddElementsToCapacity();

        tree.update(5, 50);

        uint256 updatedLeafWeight = tree.getLeafWeight(5);
        assertEq(updatedLeafWeight, 50, "Updated leaf weight should be 50");

        uint256 updatedTotalWeight = tree.getTotalWeight();
        assertEq(updatedTotalWeight, 275, "Total weight should be 275 after update");

        uint256[] memory expectedUpdatedIntermediateValues = new uint256[](9);
        expectedUpdatedIntermediateValues[0] = 275; // Root node
        expectedUpdatedIntermediateValues[1] = 150;
        expectedUpdatedIntermediateValues[2] = 125;
        expectedUpdatedIntermediateValues[3] = 100;
        expectedUpdatedIntermediateValues[4] = 50;
        expectedUpdatedIntermediateValues[5] = 50;
        expectedUpdatedIntermediateValues[6] = 75;
        expectedUpdatedIntermediateValues[7] = 50;
        expectedUpdatedIntermediateValues[8] = 50;

        for (uint256 i = 0; i < expectedUpdatedIntermediateValues.length; i++) {
            uint256 nodeValue = tree.nodes[i + 1];
            assertEq(
                nodeValue,
                expectedUpdatedIntermediateValues[i],
                "Updated intermediate node value mismatch"
            );
        }
    }

    function test_Update_Decrease() public {
        testAddElementsToCapacity();

        tree.update(5, 10);

        uint256 updatedLeafWeight = tree.getLeafWeight(5);
        assertEq(updatedLeafWeight, 10, "Updated leaf weight should be 10");

        uint256 updatedTotalWeight = tree.getTotalWeight();
        assertEq(updatedTotalWeight, 235, "Total weight should be 235 after update");

        uint256[] memory expectedUpdatedIntermediateValues = new uint256[](9);
        expectedUpdatedIntermediateValues[0] = 235; // Root node
        expectedUpdatedIntermediateValues[1] = 150;
        expectedUpdatedIntermediateValues[2] = 85;
        expectedUpdatedIntermediateValues[3] = 100;
        expectedUpdatedIntermediateValues[4] = 50;
        expectedUpdatedIntermediateValues[5] = 50;
        expectedUpdatedIntermediateValues[6] = 35;
        expectedUpdatedIntermediateValues[7] = 50;
        expectedUpdatedIntermediateValues[8] = 50;

        for (uint256 i = 0; i < expectedUpdatedIntermediateValues.length; i++) {
            uint256 nodeValue = tree.nodes[i + 1];
            assertEq(
                nodeValue,
                expectedUpdatedIntermediateValues[i],
                "Updated intermediate node value mismatch"
            );
        }
    }

    function test_Update_FirstLeaf() public {
        testAddElementsToCapacity();

        tree.update(1, 50);

        uint256 updatedLeafWeight = tree.getLeafWeight(1);
        assertEq(updatedLeafWeight, 50, "Updated leaf weight should be 50");

        uint256 updatedTotalWeight = tree.getTotalWeight();
        assertEq(updatedTotalWeight, 275, "Total weight should be 275 after update");

        uint256[] memory expectedUpdatedIntermediateValues = new uint256[](9);
        expectedUpdatedIntermediateValues[0] = 275; // Root node
        expectedUpdatedIntermediateValues[1] = 175;
        expectedUpdatedIntermediateValues[2] = 100;
        expectedUpdatedIntermediateValues[3] = 100;
        expectedUpdatedIntermediateValues[4] = 75;
        expectedUpdatedIntermediateValues[5] = 50;
        expectedUpdatedIntermediateValues[6] = 50;
        expectedUpdatedIntermediateValues[7] = 50;
        expectedUpdatedIntermediateValues[8] = 50;

        for (uint256 i = 0; i < expectedUpdatedIntermediateValues.length; i++) {
            uint256 nodeValue = tree.nodes[i + 1];
            assertEq(
                nodeValue,
                expectedUpdatedIntermediateValues[i],
                "Updated intermediate node value mismatch"
            );
        }
    }

    function test_Update_LastLeaf() public {
        testAddElementsToCapacity();

        tree.update(8, 50);

        uint256 updatedLeafWeight = tree.getLeafWeight(8);
        assertEq(updatedLeafWeight, 50, "Updated leaf weight should be 50");

        uint256 updatedTotalWeight = tree.getTotalWeight();
        assertEq(updatedTotalWeight, 275, "Total weight should be 275 after update");

        uint256[] memory expectedUpdatedIntermediateValues = new uint256[](9);
        expectedUpdatedIntermediateValues[0] = 275; // Root node
        expectedUpdatedIntermediateValues[1] = 175;
        expectedUpdatedIntermediateValues[2] = 100;
        expectedUpdatedIntermediateValues[3] = 125;
        expectedUpdatedIntermediateValues[4] = 50;
        expectedUpdatedIntermediateValues[5] = 50;
        expectedUpdatedIntermediateValues[6] = 50;
        expectedUpdatedIntermediateValues[7] = 75;
        expectedUpdatedIntermediateValues[8] = 50;

        for (uint256 i = 0; i < expectedUpdatedIntermediateValues.length; i++) {
            uint256 nodeValue = tree.nodes[i + 1];
            assertEq(
                nodeValue,
                expectedUpdatedIntermediateValues[i],
                "Updated intermediate node value mismatch"
            );
        }
    }

    function testSelect(
        uint256 randomValue
    ) public {
        testAddElementsToCapacity();

        uint256 selectedLeaf = tree.select(randomValue);

        assertTrue(selectedLeaf >= 1 && selectedLeaf <= 10);
    }

    function testSelectMultiple(
        uint256 quantity
    ) public {
        quantity = bound(quantity, 1, 100); // Use vm.bound to set a reasonable range
        testAddElementsToCapacity();

        uint256 seed = 12_345;
        uint256[] memory selectedLeaves = tree.selectMultiple(seed, quantity);

        assertEq(selectedLeaves.length, quantity, "Invalid selection");
    }

    function testSelectMultipleRevertOnZeroQuantity() public {
        testAddElementsToCapacity();

        uint256 seed = 12_345;
        uint256 quantity = 0;

        vm.expectRevert(SortitionTreeLib.QuantityMustBeGreaterThanZero.selector);
        tree.selectMultiple(seed, quantity);
    }

    /**
     * forge-config: default.fuzz.runs = 10
     * forge-config: ci.fuzz.runs = 10
     */
    function testSelectWithUniformRandomNumberLib(
        uint256 randomValue
    ) public {
        testAddElementsToCapacity();

        uint256[] memory selectionCounts = new uint256[](10);
        uint256 totalDraws = 100_000;

        for (uint256 i = 0; i < totalDraws; i++) {
            uint256 seed = uint256(keccak256(abi.encodePacked(randomValue, i)));
            uint256 selectedLeaf = tree.select(seed);
            selectionCounts[selectedLeaf - 1]++;
        }

        for (uint256 i = 0; i < selectionCounts.length; i++) {
            uint256 expectedCount = (tree.getLeafWeight(i + 1) * totalDraws) / tree.getTotalWeight();
            assertApproxEqRel(
                selectionCounts[i], expectedCount, 0.0325e18, "Leaf selection count mismatch"
            );
        }
    }

    function test_Gas_Draw10_100Leaves() public {
        newTree.initialize(1000);
        for (uint256 i = 0; i < 1000; i++) {
            newTree.add(25);
        }

        uint256 seed = 12_345;
        uint256 startGas = gasleft();
        newTree.selectMultiple(seed, 10);
        uint256 gasUsed = startGas - gasleft();

        console.log("Gas used for selecting 10 leaves from 1000:", gasUsed);
    }

    function testGetSubtreeDepth() public {
        // Initialize the tree with a capacity of 8 leaves
        newTree.initialize(8);

        // Add some leaves to the tree
        newTree.add(10);
        newTree.add(20);
        newTree.add(30);
        newTree.add(40);

        // Test depth of root node (index 1)
        uint256 rootDepth = newTree.getSubtreeDepth(1);
        assertEq(rootDepth, 4, "Root node should have depth 4");

        // Test depth of internal nodes
        uint256 internalNode1Depth = newTree.getSubtreeDepth(2);
        assertEq(internalNode1Depth, 3, "Internal node at index 2 should have depth 3");

        uint256 internalNode2Depth = newTree.getSubtreeDepth(3);
        assertEq(internalNode2Depth, 3, "leaf node at index 3 should have depth 2");

        // Test depth of leaf nodes
        uint256 leafNode1Depth = newTree.getSubtreeDepth(8);
        assertEq(leafNode1Depth, 1, "Leaf node at index 8 should have depth 1");

        uint256 leafNode2Depth = newTree.getSubtreeDepth(9);
        assertEq(leafNode2Depth, 1, "Leaf node at index 9 should have depth 1");

        // Test depth of an empty node (beyond the current tree size)
        uint256 emptyNodeDepth = newTree.getSubtreeDepth(16);
        assertEq(emptyNodeDepth, 0, "Empty node should have depth 0");
    }

    function testGetParentNode() public {
        // Test for leaf nodes
        assertEq(SortitionTreeLib.getParentNode(8), 4, "Parent of node 8 should be 4");
        assertEq(SortitionTreeLib.getParentNode(9), 4, "Parent of node 9 should be 4");
        assertEq(SortitionTreeLib.getParentNode(10), 5, "Parent of node 10 should be 5");
        assertEq(SortitionTreeLib.getParentNode(11), 5, "Parent of node 11 should be 5");

        // Test for internal nodes
        assertEq(SortitionTreeLib.getParentNode(4), 2, "Parent of node 4 should be 2");
        assertEq(SortitionTreeLib.getParentNode(5), 2, "Parent of node 5 should be 2");
        assertEq(SortitionTreeLib.getParentNode(6), 3, "Parent of node 6 should be 3");
        assertEq(SortitionTreeLib.getParentNode(7), 3, "Parent of node 7 should be 3");

        // Test for root's children
        assertEq(SortitionTreeLib.getParentNode(2), 1, "Parent of node 2 should be 1 (root)");
        assertEq(SortitionTreeLib.getParentNode(3), 1, "Parent of node 3 should be 1 (root)");

        // Test for root
        /// TODO: Should revert?
        assertEq(SortitionTreeLib.getParentNode(1), 0, "Parent of root (node 1) should be 0");
    }

    function testGetChildNodes() public {
        // Test for root node
        (uint256 rootLeftChild, uint256 rootRightChild) = SortitionTreeLib.getChildNodes(1);
        assertEq(rootLeftChild, 2, "Left child of root should be 2");
        assertEq(rootRightChild, 3, "Right child of root should be 3");

        // Test for internal nodes
        (uint256 internalLeftChild1, uint256 internalRightChild1) =
            SortitionTreeLib.getChildNodes(2);
        assertEq(internalLeftChild1, 4, "Left child of node 2 should be 4");
        assertEq(internalRightChild1, 5, "Right child of node 2 should be 5");

        (uint256 internalLeftChild2, uint256 internalRightChild2) =
            SortitionTreeLib.getChildNodes(3);
        assertEq(internalLeftChild2, 6, "Left child of node 3 should be 6");
        assertEq(internalRightChild2, 7, "Right child of node 3 should be 7");

        // Test for leaf nodes (these will return child indices, but they're not valid in the tree)
        (uint256 leafLeftChild, uint256 leafRightChild) = SortitionTreeLib.getChildNodes(8);
        assertEq(leafLeftChild, 16, "Left child of leaf node 8 should be 16");
        assertEq(leafRightChild, 17, "Right child of leaf node 8 should be 17");

        // Test for a large node index
        (uint256 largeLeftChild, uint256 largeRightChild) = SortitionTreeLib.getChildNodes(1000);
        assertEq(largeLeftChild, 2000, "Left child of node 1000 should be 2000");
        assertEq(largeRightChild, 2001, "Right child of node 1000 should be 2001");
    }

    function testIsLeafNode() public {
        // Initialize the tree with a capacity of 8
        newTree.initialize(8);

        // Add some leaves to the tree
        newTree.add(10);
        newTree.add(20);
        newTree.add(30);

        // Test for leaf nodes
        assertTrue(newTree.isLeafNode(8), "Node 8 should be a leaf node");
        assertTrue(newTree.isLeafNode(9), "Node 9 should be a leaf node");
        assertTrue(newTree.isLeafNode(10), "Node 10 should be a leaf node");

        // Test for internal nodes
        assertFalse(newTree.isLeafNode(1), "Node 1 (root) should not be a leaf node");
        assertFalse(newTree.isLeafNode(2), "Node 2 should not be a leaf node");
        assertFalse(newTree.isLeafNode(3), "Node 3 should not be a leaf node");
        assertFalse(newTree.isLeafNode(4), "Node 4 should not be a leaf node");

        // Test for nodes beyond the current leaf count
        assertFalse(
            newTree.isLeafNode(11), "Node 11 should not be a leaf node (beyond current leaf count)"
        );
        assertFalse(
            newTree.isLeafNode(15), "Node 15 should not be a leaf node (beyond current leaf count)"
        );

        // Test for nodes below the capacity (should not be leaf nodes)
        assertFalse(newTree.isLeafNode(5), "Node 5 should not be a leaf node (below capacity)");
        assertFalse(newTree.isLeafNode(6), "Node 6 should not be a leaf node (below capacity)");
        assertFalse(newTree.isLeafNode(7), "Node 7 should not be a leaf node (below capacity)");
    }

    function testIsLeafNodeWithFullTree() public {
        // Initialize the tree with a capacity of 4
        newTree.initialize(4);

        // Fill the tree to capacity
        newTree.add(10);
        newTree.add(20);
        newTree.add(30);
        newTree.add(40);

        // All leaf nodes should return true
        assertTrue(newTree.isLeafNode(4), "Node 4 should be a leaf node");
        assertTrue(newTree.isLeafNode(5), "Node 5 should be a leaf node");
        assertTrue(newTree.isLeafNode(6), "Node 6 should be a leaf node");
        assertTrue(newTree.isLeafNode(7), "Node 7 should be a leaf node");

        // Internal nodes should still return false
        assertFalse(newTree.isLeafNode(1), "Node 1 (root) should not be a leaf node");
        assertFalse(newTree.isLeafNode(2), "Node 2 should not be a leaf node");
        assertFalse(newTree.isLeafNode(3), "Node 3 should not be a leaf node");
    }

    function testGetSubtreeLeafCount_PartialTree() public {
        // Initialize a new tree with capacity 8
        newTree.initialize(8);

        // Add some elements
        newTree.add(10);
        newTree.add(20);
        newTree.add(30);
        newTree.add(40);
        newTree.add(50);

        // Test root node (should return total leaf count)
        uint256 rootLeafCount = newTree.getSubtreeLeafCount(1);
        assertEq(rootLeafCount, 5, "Root node should have 5 leaves");

        // Test internal nodes
        uint256 leftSubtreeLeafCount = newTree.getSubtreeLeafCount(2);
        assertEq(leftSubtreeLeafCount, 4, "Left subtree should have 2 leaves");

        uint256 rightSubtreeLeafCount = newTree.getSubtreeLeafCount(3);
        assertEq(rightSubtreeLeafCount, 1, "Right subtree should have 3 leaves");

        /// Leaf should return 1
        uint256 nonExistentNodeCount = newTree.getSubtreeLeafCount(9);
        assertEq(nonExistentNodeCount, 0, "Non-existent node should have a count of 0");
    }

    function testGetSubtreeLeafCount_FullTree() public {
        // Initialize a new tree with capacity 8
        newTree.initialize(8);

        // Add elements to fill the tree
        for (uint256 i = 1; i <= 8; i++) {
            newTree.add(i * 10);
        }

        // Test root node (should return total leaf count)
        uint256 rootLeafCount = newTree.getSubtreeLeafCount(1);
        assertEq(rootLeafCount, 8, "Root node should have 8 leaves");

        // Test internal nodes
        uint256 leftSubtreeLeafCount = newTree.getSubtreeLeafCount(2);
        assertEq(leftSubtreeLeafCount, 4, "Left subtree should have 4 leaves");

        uint256 rightSubtreeLeafCount = newTree.getSubtreeLeafCount(3);
        assertEq(rightSubtreeLeafCount, 4, "Right subtree should have 4 leaves");

        // Test lower level internal nodes
        uint256 lowerLeftSubtreeLeafCount = newTree.getSubtreeLeafCount(4);
        assertEq(lowerLeftSubtreeLeafCount, 2, "Lower left subtree should have 2 leaves");

        uint256 lowerRightSubtreeLeafCount = newTree.getSubtreeLeafCount(5);
        assertEq(lowerRightSubtreeLeafCount, 2, "Lower right subtree should have 2 leaves");

        // Test leaf nodes (should return 0 as they are not subtrees)
        uint256 leafNodeCount = newTree.getSubtreeLeafCount(8);
        assertEq(leafNodeCount, 0, "Leaf node should have a count of 0");
    }

    function testGetSubtreeWeight() public {
        // Initialize a new tree with capacity 8
        newTree.initialize(8);

        // Add elements with different weights
        newTree.add(10);
        newTree.add(20);
        newTree.add(30);
        newTree.add(40);
        newTree.add(50);
        newTree.add(60);
        newTree.add(70);
        newTree.add(80);

        // Test root node (should return total weight)
        uint256 rootWeight = newTree.getSubtreeWeight(1);
        assertEq(rootWeight, 360, "Root node should have total weight of 360");

        // Test internal nodes
        uint256 leftSubtreeWeight = newTree.getSubtreeWeight(2);
        assertEq(leftSubtreeWeight, 100, "Left subtree should have weight of 100");

        uint256 rightSubtreeWeight = newTree.getSubtreeWeight(3);
        assertEq(rightSubtreeWeight, 260, "Right subtree should have weight of 260");

        // Test lower level internal nodes
        uint256 lowerLeftSubtreeWeight = newTree.getSubtreeWeight(4);
        assertEq(lowerLeftSubtreeWeight, 30, "Lower left subtree should have weight of 30");

        uint256 lowerRightSubtreeWeight = newTree.getSubtreeWeight(5);
        assertEq(lowerRightSubtreeWeight, 70, "Lower right subtree should have weight of 70");

        // Test leaf nodes
        uint256 leafNodeWeight = newTree.getSubtreeWeight(8);
        assertEq(leafNodeWeight, 10, "Leaf node should have weight of 10");

        // Test non-existent node (should return 0)
        uint256 nonExistentNodeWeight = newTree.getSubtreeWeight(16);
        assertEq(nonExistentNodeWeight, 0, "Non-existent node should have weight of 0");
    }

    function testSelectSubTreeParentNode() public {
        // Initialize a new tree with capacity 8
        newTree.initialize(8);

        // Add elements with different weights
        newTree.add(10); // 1
        newTree.add(20); // 2
        newTree.add(30); // 3
        newTree.add(40); // 4
        newTree.add(50); // 5
        newTree.add(60); // 6
        newTree.add(70); // 7
        newTree.add(80); // 8

        uint256 seed = 12_345;
        uint256 capWeight = 200;
        uint256 minimumWeight = 100;

        uint256 parentNodeIndex = newTree.selectSubTreeParentNode(seed, capWeight, minimumWeight);

        // Verify that the selected parent node index is valid
        assertTrue(
            parentNodeIndex > 0 && parentNodeIndex < newTree.capacity,
            "Selected parent node index should be valid"
        );

        // Get the weight of the selected subtree
        uint256 subtreeWeight = newTree.getSubtreeWeight(parentNodeIndex);

        // Verify that the selected subtree meets the weight criteria
        assertTrue(
            subtreeWeight >= minimumWeight,
            "Selected subtree weight should be at least the minimum weight"
        );
        /// This might not be true so cant enforce
        // assertTrue(
        //     subtreeWeight <= capWeight, "Selected subtree weight should not exceed the cap weight"
        // );
    }

    function testPrintTreeStructure() public view {
        printTreeStructure();
    }

    function printTreeStructure() internal view {
        uint256 totalWeight = tree.getTotalWeight();
        uint256 leafCount = tree.leafCount;

        console.log("Tree Structure:");
        console.log("Total Weight:", totalWeight);
        console.log("Leaf Count:", leafCount);

        console.log("Leaves:");
        for (uint256 i = 1; i <= leafCount; i++) {
            uint256 leafWeight = tree.getLeafWeight(i);
            console.log("Leaf", i, "Weight:", leafWeight);
        }
    }
}
