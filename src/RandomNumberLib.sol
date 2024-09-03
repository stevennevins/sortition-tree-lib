// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library RandomNumberLib {
    error MinUpperBound();

    /// @notice Select a random number without modulo bias using a random seed and upper bound
    /// @param seed The seed for randomness
    /// @param upperBound The upper bound of the desired number
    /// @return A random number less than the upperBound
    function generate(uint256 seed, uint256 upperBound) internal pure returns (uint256) {
        if (upperBound == 0) {
            revert MinUpperBound();
        }
        uint256 min = (type(uint256).max - upperBound + 1) % upperBound;
        while (seed < min) {
            seed = uint256(keccak256(abi.encodePacked(seed)));
        }

        return seed % upperBound;
    }
}
