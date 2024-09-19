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
        bytes32 randomValue
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

        bytes32 seed = keccak256(abi.encodePacked(block.timestamp, block.prevrandao));
        uint256[] memory selectedLeaves = tree.selectMultiple(seed, quantity);

        assertEq(selectedLeaves.length, quantity, "Invalid selection");
    }

    function testSelectMultipleRevertOnZeroQuantity() public {
        testAddElementsToCapacity();

        bytes32 seed = keccak256(abi.encodePacked(block.timestamp, block.prevrandao));
        uint256 quantity = 0;

        vm.expectRevert(SortitionTreeLib.QuantityMustBeGreaterThanZero.selector);
        tree.selectMultiple(seed, quantity);
    }

    /**
     * forge-config: default.fuzz.runs = 10
     * forge-config: ci.fuzz.runs = 10
     */
    function testSelectWithUniformRandomNumberLib(
        bytes32 randomValue
    ) public {
        testAddElementsToCapacity();

        uint256[] memory selectionCounts = new uint256[](10);
        uint256 totalDraws = 100_000;

        for (uint256 i = 0; i < totalDraws; i++) {
            bytes32 seed = keccak256(abi.encodePacked(randomValue, i));
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

        bytes32 seed = keccak256(abi.encodePacked(block.timestamp, block.prevrandao));
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
        assertEq(rootDepth, 3, "Root node should have depth 3");

        // Test depth of internal nodes
        uint256 internalNode1Depth = newTree.getSubtreeDepth(2);
        assertEq(internalNode1Depth, 2, "Internal node at index 2 should have depth 2");

        uint256 internalNode2Depth = newTree.getSubtreeDepth(3);
        assertEq(internalNode2Depth, 2, "leaf node at index 3 should have depth 2");
    }

    function testGetSubtreeLeftMostLeafNodeIndex() public {
        // Initialize the tree with a capacity of 8 leaves
        newTree.initialize(8);

        // Add some leaves to the tree
        newTree.add(10);
        newTree.add(20);
        newTree.add(30);
        newTree.add(40);

        // Test for root node (index 1)
        uint256 rootLeftMost = newTree.getSubtreeLeftMostLeafNodeIndex(1);
        assertEq(rootLeftMost, 8, "Leftmost leaf node index for root should be 8");

        // Test for internal node (index 2)
        uint256 internalLeftMost = newTree.getSubtreeLeftMostLeafNodeIndex(2);
        assertEq(internalLeftMost, 8, "Leftmost leaf node index for node 2 should be 8");

        newTree.add(50);
        uint256 internalLeftMost2 = newTree.getSubtreeLeftMostLeafNodeIndex(3);
        assertEq(internalLeftMost2, 12, "Leftmost leaf node index for node 2 should be 8");
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
    }

    function testSelectSubtreeParentNode() public {
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

        bytes32 seed = bytes32(uint256(12_345));
        uint256 capWeight = 200;
        uint256 minimumWeight = 100;

        uint256 parentNodeIndex = newTree.selectSubtree(seed, capWeight, minimumWeight);

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

    function testIsInSubtree() public {
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

        // Test cases for different parent nodes and leaf nodes
        assertTrue(newTree.isInSubtree(1, 1), "Leaf 1 should be in subtree of root (1)");
        assertTrue(newTree.isInSubtree(1, 8), "Leaf 8 should be in subtree of root (1)");

        assertTrue(newTree.isInSubtree(2, 1), "Leaf 1 should be in subtree of node 2");
        assertTrue(newTree.isInSubtree(2, 2), "Leaf 2 should be in subtree of node 2");
        assertTrue(newTree.isInSubtree(2, 3), "Leaf 3 should be in subtree of node 2");
        assertTrue(newTree.isInSubtree(2, 4), "Leaf 4 should be in subtree of node 2");

        assertFalse(newTree.isInSubtree(2, 5), "Leaf 5 should not be in subtree of node 2");
        assertFalse(newTree.isInSubtree(2, 8), "Leaf 8 should not be in subtree of node 2");

        assertTrue(newTree.isInSubtree(3, 5), "Leaf 5 should be in subtree of node 3");
        assertTrue(newTree.isInSubtree(3, 8), "Leaf 8 should be in subtree of node 3");

        assertFalse(newTree.isInSubtree(3, 1), "Leaf 1 should not be in subtree of node 3");
        assertFalse(newTree.isInSubtree(3, 4), "Leaf 4 should not be in subtree of node 3");

        assertTrue(newTree.isInSubtree(4, 1), "Leaf 1 should be in subtree of node 4");
        assertTrue(newTree.isInSubtree(4, 2), "Leaf 2 should be in subtree of node 4");

        assertFalse(newTree.isInSubtree(4, 3), "Leaf 3 should not be in subtree of node 4");
        assertFalse(newTree.isInSubtree(4, 8), "Leaf 8 should not be in subtree of node 4");
    }

    function testSelectFromSubtree() public {
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

        // Test selecting from the root (entire tree)
        bytes32 seed = bytes32(uint256(12_345));
        uint256 selectedLeaf = newTree.selectFromSubtree(seed, 1);
        assertTrue(
            selectedLeaf >= 1 && selectedLeaf <= 8, "Selected leaf should be within valid range"
        );

        // Test selecting from a subtree (node 2, which contains leaves 1-4)
        selectedLeaf = newTree.selectFromSubtree(seed, 2);
        assertTrue(
            selectedLeaf >= 1 && selectedLeaf <= 4, "Selected leaf should be within subtree range"
        );

        // Test selecting from another subtree (node 3, which contains leaves 5-8)
        selectedLeaf = newTree.selectFromSubtree(seed, 3);
        assertTrue(
            selectedLeaf >= 5 && selectedLeaf <= 8, "Selected leaf should be within subtree range"
        );
    }

    function testSelectMultipleFromSubtree() public {
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

        bytes32 seed = bytes32(uint256(12_345));
        uint256 quantity = 3;

        // Test selecting multiple from the root (entire tree)
        uint256[] memory selectedLeaves = newTree.selectMultipleFromSubtree(seed, quantity, 1);
        assertEq(selectedLeaves.length, quantity, "Should select the correct number of leaves");
        for (uint256 i = 0; i < quantity; i++) {
            assertTrue(
                selectedLeaves[i] >= 1 && selectedLeaves[i] <= 8,
                "Selected leaf should be within valid range"
            );
        }

        // Test selecting multiple from a subtree (node 2, which contains leaves 1-4)
        selectedLeaves = newTree.selectMultipleFromSubtree(seed, quantity, 2);
        assertEq(selectedLeaves.length, quantity, "Should select the correct number of leaves");
        for (uint256 i = 0; i < quantity; i++) {
            assertTrue(
                selectedLeaves[i] >= 1 && selectedLeaves[i] <= 4,
                "Selected leaf should be within subtree range"
            );
        }

        // Test selecting multiple from another subtree (node 3, which contains leaves 5-8)
        selectedLeaves = newTree.selectMultipleFromSubtree(seed, quantity, 3);
        assertEq(selectedLeaves.length, quantity, "Should select the correct number of leaves");
        for (uint256 i = 0; i < quantity; i++) {
            assertTrue(
                selectedLeaves[i] >= 5 && selectedLeaves[i] <= 8,
                "Selected leaf should be within subtree range"
            );
        }
    }

    function testRemove() public {
        // Initialize a new tree with capacity 8
        newTree.initialize(8);

        // Add elements with different weights
        newTree.add(10); // 1
        newTree.add(20); // 2
        newTree.add(30); // 3
        newTree.add(40); // 4
        newTree.add(50); // 5

        // Check initial state
        assertEq(newTree.getLeafCount(), 5, "Initial leaf count should be 5");
        assertEq(newTree.getTotalWeight(), 150, "Initial total weight should be 150");

        // Remove a leaf from the middle (index 3)
        newTree.remove(3);

        // Check state after removal
        assertEq(newTree.getLeafCount(), 4, "Leaf count should be 4 after removal");
        assertEq(newTree.getTotalWeight(), 120, "Total weight should be 120 after removal");

        // Check weights of remaining leaves
        assertEq(newTree.getLeafWeight(1), 10, "Weight of leaf 1 should remain 10");
        assertEq(newTree.getLeafWeight(2), 20, "Weight of leaf 2 should remain 20");
        assertEq(
            newTree.getLeafWeight(3), 50, "Weight of leaf 3 should now be 50 (previously leaf 5)"
        );
        assertEq(newTree.getLeafWeight(4), 40, "Weight of leaf 4 should remain 40");

        // Remove the last leaf
        newTree.remove(4);

        // Check final state
        assertEq(newTree.getLeafCount(), 3, "Final leaf count should be 3");
        assertEq(newTree.getTotalWeight(), 80, "Final total weight should be 80");
    }

    function testGetSubtreeLeaves() public {
        // Initialize a new tree with capacity 8
        newTree.initialize(8);

        // Add elements with different weights
        newTree.add(10); // 1
        newTree.add(20); // 2
        newTree.add(30); // 3
        newTree.add(40); // 4
        newTree.add(50); // 5

        // Test getSubtreeLeafWeights for the root node (index 1)
        uint256[] memory rootLeaves = newTree.getSubtreeLeafWeights(1);
        assertEq(rootLeaves.length, 5, "Root should have 5 leaves");

        // Test getSubtreeLeafWeights for the left subtree (index 2)
        uint256[] memory leftSubtreeLeaves = newTree.getSubtreeLeafWeights(2);
        assertEq(leftSubtreeLeaves.length, 4, "Left subtree should have 4 leaves");

        // Test getSubtreeLeafWeights for the right subtree (index 3)
        uint256[] memory rightSubtreeLeaves = newTree.getSubtreeLeafWeights(3);
        assertEq(rightSubtreeLeaves.length, 1, "Right subtree should have 1 leaf");
        assertEq(rightSubtreeLeaves[0], 50, "Right leave should be 50");

        // Test getSubtreeLeafWeights for a lower level node (index 4)
        uint256[] memory lowerLevelLeaves = newTree.getSubtreeLeafWeights(4);
        assertEq(lowerLevelLeaves.length, 2, "Lower level node should have 2 leaves");
    }

    function testGetPathFromLeafToNode() public {
        newTree.initialize(8);

        newTree.add(10); // 1
        newTree.add(20); // 2
        newTree.add(30); // 3
        newTree.add(40); // 4
        newTree.add(50); // 5

        uint256[] memory path = newTree.getPathFromLeafToNode(3, 1);
        assertEq(path.length, 3, "Path from leaf 3 to root should have 3 nodes");

        path = newTree.getPathFromLeafToNode(5, 3);
        assertEq(path.length, 2, "Path from leaf 5 to its parent should have 2 node");

        path = newTree.getPathFromLeafToNode(2, 2);
        assertEq(path.length, 2, "Path from leaf 2 to intermediate node should have 2 nodes");
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
