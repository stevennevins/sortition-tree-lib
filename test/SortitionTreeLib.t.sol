// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SortitionTreeLib} from "../src/SortitionTreeLib.sol";
import {RandomNumberLib} from "../src/RandomNumberLib.sol";

contract SortitionTreeLibTest is Test {
    using SortitionTreeLib for SortitionTreeLib.Tree;

    SortitionTreeLib.Tree internal tree;
    SortitionTreeLib.Tree internal newTree;

    function setUp() public {
        tree.initialize(10);
        tree.add(25);
        tree.add(25);
        tree.add(25);
        tree.add(25);
    }

    function testTreeShape() public {
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
                selectionCounts[i], expectedCount, 0.03e18, "Leaf selection count mismatch"
            );
        }
    }

    function test_Gas_Draw10_100Leaves() public {
        newTree.initialize(1000);
        for (uint256 i = 0; i < 1000; i++) {
            newTree.add(25);
        }

        uint256 seed = 12345;
        uint256 startGas = gasleft();
        uint256[] memory selectedLeaves = newTree.selectMultiple(seed, 10);
        uint256 gasUsed = startGas - gasleft();

        console.log("Gas used for selecting 10 leaves from 1000:", gasUsed);
    }

    function testPrintTreeStructure() public {
        printTreeStructure();
    }

    function printTreeStructure() internal {
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
