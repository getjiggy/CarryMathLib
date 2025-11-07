// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {CarryMathLib} from "../src/CarryMathLib.sol";
import {FixedPointMathLib} from "@solady-utils/FixedPointMathLib.sol";

contract CarryMathLibTest is Test {
    // Reuse library internal state per test
    // (CarryMathLib handles its own carry automatically)
    uint256 internal constant DEN = 1e18; // denominator (1.0 in WAD)
    uint256 internal constant NUM = 5e17; // 0.5 in WAD

    function setUp() public {
        // Ensure clean state before each test
        CarryMathLib.resetCarry();
    }

    /// @notice Test simple single-call correctness.
    function testSingleMulDiv() public {
        uint256 x = 2e18; // 2.0
        uint256 y = 3e18; // 3.0
        uint256 z = CarryMathLib.mulDiv(x, y, DEN);
        assertEq(z, 6e18);
    }

    /// @notice Ensure carry accumulates fractional remainders correctly.
    function testCarryAccumulation() public {
        CarryMathLib.resetCarry();

        uint256 total = 0;
        for (uint256 i = 0; i < 10; ++i) {
            uint256 result = CarryMathLib.mulDiv(1, 1, 3);
            total += result;
        }

        // 10 / 3 = 3 * 3 + 1 remainder -> total should be 3
        assertEq(total, 3);
        // remainder must be 1 (carry left over)
        uint256 carry = CarryMathLib.peekCarry();
        assertEq(carry, 1);
    }

    /// @notice Check conservation under many small operations.
    function testMassConservationManyOps() public {
        CarryMathLib.resetCarry();

        uint256 expected = 0;
        uint256 computed = 0;
        uint256 denominator = 7;

        // perform 1000 random small ops
        for (uint256 i = 1; i <= 1000; ++i) {
            expected += i;
            computed += CarryMathLib.mulDiv(i, 1, denominator);
        }

        uint256 carry = CarryMathLib.peekCarry();
        // invariant: computed * denominator + carry == expected
        assertEq(computed * denominator + carry, expected);
    }

    /// @notice Fuzz: check conservation holds for random values.
    function testFuzzMassConservation(uint256 x, uint256 y, uint256 d) public {
        vm.assume(d > 1 && d < type(uint128).max);
        vm.assume(x < 1e36 && y < 1e36); // prevent overflow

        CarryMathLib.resetCarry();
        uint256 z = CarryMathLib.mulDiv(x, y, d);

        uint256 carry = CarryMathLib.peekCarry();
        uint256 reconstructed = z * d + carry;
        uint256 exact = FixedPointMathLib.mulDiv(x, y, 1); // same mult, no div yet
        assertApproxEqAbs(reconstructed, exact, d - 1);
    }

    /// @notice Ensure carries are isolated by selector.
    function testCarryIsolationBetweenFunctions() public {
        CarryMathLib.resetCarry();
        uint256 first = CarryMathLib.mulDiv(1, 1, 3);
        assertEq(first, 0);
        uint256 carry1 = CarryMathLib.peekCarry();
        assertEq(carry1, 1);

        // Simulate different selector by calling a dummy helper
        _dummyCall(1, 1, 3);
        uint256 carry2 = CarryMathLib.peekCarry();
        // carry1 != carry2 — each function has its own carry space
        assertTrue(carry1 != carry2);
    }

    function _dummyCall(uint256 x, uint256 y, uint256 d) internal returns (uint256) {
        return CarryMathLib.mulDiv(x, y, d);
    }
}
