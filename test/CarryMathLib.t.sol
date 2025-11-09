// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {CarryMathLib} from "../src/CarryMathLib.sol";
import {FixedPointMathLib} from "@solady-utils/FixedPointMathLib.sol";

contract CarryMathLibTest is Test {
    uint256 constant DEN = 1e18;
    uint256 constant NUM = 5e17;
    

    /// @notice simple single-call correctness
    function testSingleMulDiv() public {
        uint256 x = 2e18;
        uint256 y = 3e18;
        uint256 z = CarryMathLib.mulDivAuto(x, y, DEN, "main", 0);
        assertEq(z, 6e18);
    }

    /// @notice carry accumulates correctly for repeated fractional ops
    function testCarryAccumulation() public {
        uint256 counter;
        string memory ns = "accum";
        uint256 total;
        for (uint256 i = 0; i < 10; ++i) {
            uint256 result = CarryMathLib.mulDivAuto(1, 1, 3, ns, counter);
            total += result;
        }

        // 10 / 3 = 3 * 3 + 1 remainder
        assertEq(total, 3);
        uint256 carry = CarryMathLib.getCarry(keccak256(bytes(ns)), counter);
        assertEq(carry, 1);
    }

    /// @notice ensure resetting a carry zeroes the storage
    function testResetCarry() public {
        uint256 counter;
        string memory ns = "reset";
        CarryMathLib.mulDivAuto(5, 1, 3, ns, 0);
        uint256 carryBefore = CarryMathLib.getCarry(keccak256(bytes(ns)), counter);
        assertGt(carryBefore, 0);

        CarryMathLib.resetCarry(keccak256(bytes(ns)), counter);
        uint256 carryAfter = CarryMathLib.getCarry(keccak256(bytes(ns)), counter);
        assertEq(carryAfter, 0);
    }

    /// @notice fuzz: reconstructed value == x*y within denominator tolerance
    function testFuzzMassConservation(uint256 x, uint256 y, uint256 d) public {
        vm.assume(d > 1 && d < type(uint128).max);
        vm.assume(x < 1e36 && y < 1e36);

        string memory ns = "fuzz";
        uint256 z = CarryMathLib.mulDivAuto(x, y, d, ns, 0);
        uint256 carry = CarryMathLib.getCarry(keccak256(bytes(ns)), 0);

        // z * d + carry == x*y approximately
        uint256 reconstructed = z * d + carry;
        uint256 exact = FixedPointMathLib.mulDiv(x, y, 1);
        assertApproxEqAbs(reconstructed, exact, d - 1);
    }

    /// @notice ensure carries are isolated between namespaces
    function testNamespaceIsolation() public {
        uint256 a = CarryMathLib.mulDivAuto(1, 1, 3, "A", 0);
        uint256 b = CarryMathLib.mulDivAuto(1, 1, 3, "B", 0);
        assertEq(a, b); // same arithmetic
        uint256 carryA = CarryMathLib.getCarry(keccak256("A"), 0);
        uint256 carryB = CarryMathLib.getCarry(keccak256("B"), 0);
        assertTrue(carryA != 0 && carryB != 0);
        assertTrue(carryA == carryB); // same remainder logic
        // but ensure isolation by writing again and checking separation
        CarryMathLib.resetCarry(keccak256("A"), 0);
        uint256 carryAAfter = CarryMathLib.getCarry(keccak256("A"), 0);
        uint256 carryBAfter = CarryMathLib.getCarry(keccak256("B"), 0);
        assertEq(carryAAfter, 0);
        assertEq(carryBAfter, carryB);
    }

    /// @notice ensure carries are isolated by counter within same namespace
    function testCounterIsolation() public {
        string memory ns = "counter";
        CarryMathLib.mulDivAuto(1, 1, 3, ns, 0);
        CarryMathLib.mulDivAuto(2, 1, 3, ns, 1);

        uint256 c0 = CarryMathLib.getCarry(keccak256(bytes(ns)), 0);
        uint256 c1 = CarryMathLib.getCarry(keccak256(bytes(ns)), 1);
        assertTrue(c0 != c1);
    }

    /// @notice ensure carries are isolated by selector (msg.sig)
    function testSelectorIsolation() public {
        string memory ns = "selector";
        // carry should be 1
        CarryMathLib.mulDivAuto(1, 1, 3, ns, 0);
        uint256 carry1 = CarryMathLib.getCarry(keccak256(bytes(ns)), 0);
        assertTrue(carry1 == 1, "carry1 check");

        // external call triggers a new msg.sig.
        // carry should be 2
        uint256 carry2 = this.dummyCall(1, 2, 3, ns, 0);
        console.logUint(carry2);
        assertTrue(carry2 == 2, "carry2 check");
        // ensure carry1 has not changed
        uint256 carry1After = CarryMathLib.getCarry(keccak256(bytes(ns)), 0);
        assertEq(carry1, carry1After);

        // call again to dummyCall for gas reporting
        uint256 carry3 = this.dummyCall(3, 1, 3, ns, 0);
        uint256 carry4 = this.dummyCall(3, 1, 3, ns, 0);
        assertTrue(carry3 == 0, "carry3 check");
        assertTrue(carry4 == 1, "carry4 check");

    }

    function dummyCall(uint256 x, uint256 y, uint256 d, string memory ns, uint256 counter) external returns (uint256) {
        CarryMathLib.mulDivAuto(x, y, d, ns, counter);
        return CarryMathLib.getCarry(keccak256(bytes(ns)), counter);
    }

    /// @notice deterministic reproducibility under identical inputs
    function testDeterministicResults() public {
        string memory ns = "determinism";
        uint256 r1 = CarryMathLib.mulDivAuto(7, 5, 3, ns, 0);
        uint256 c1 = CarryMathLib.getCarry(keccak256(bytes(ns)), 0);

        CarryMathLib.resetCarry(keccak256(bytes(ns)), 0);
        uint256 r2 = CarryMathLib.mulDivAuto(7, 5, 3, ns, 0);
        uint256 c2 = CarryMathLib.getCarry(keccak256(bytes(ns)), 0);

        assertEq(r1, r2);
        assertEq(c1, c2);
    }

    function testCarryMem() public pure {
        CarryMathLib.Carry memory carry = CarryMathLib.initCarryMem();
        uint256 x = 7;
        uint256 y = 5;
        uint256 d = 3;

        (uint256 z1, uint256 rem1) = CarryMathLib.mulDivMem(x, y, d, carry);
        carry.remainder = rem1;
        // 7 * 5 = 35 / 3 = 11 remainder 2
        // remainder must be 2
        assertEq(rem1, 2, "rem1 check");
        (uint256 z2, uint256 rem2) = CarryMathLib.mulDivMem(x, y, d, carry);
        carry.remainder = rem2;
        // 7 * 5 = 35 + 2 = 37 / 3 = 12 remainder 1
        // remainder must be 1
        assertEq(rem2, 1, "rem2 check"); 
        (uint256 z3, uint256 rem3) = CarryMathLib.mulDivMem(x, y, d, carry);
        // 7 * 5 = 35 + 1 = 36 / 3 = 12 remainder 0
        // remainder must be 0
        assertEq(rem3, 0, "rem3 check");

        uint256 totalZ = z1 + z2 + z3;
        uint256 totalReconstructed = totalZ * d + rem3;
        uint256 exact = FixedPointMathLib.mulDiv(x, y, 1) * 3;

        assertApproxEqAbs(totalReconstructed, exact, d - 1);
    }

    function dummyCallMem(uint x, uint y, uint d, CarryMathLib.Carry memory carry) external pure returns (uint z, CarryMathLib.Carry memory) {
        (z, carry.remainder) = CarryMathLib.mulDivMem(x, y, d, carry);

        return (z, carry);
    }
    function testCarryMemForGas() public view { 
        CarryMathLib.Carry memory carry = CarryMathLib.initCarryMem();
        uint256 x = 7;
        uint256 y = 5;
        uint256 d = 3;

        (, CarryMathLib.Carry memory carryOut) = this.dummyCallMem(x, y, d, carry);
        assertEq(carryOut.remainder, 2, "rem1 check");
        
    }
}
