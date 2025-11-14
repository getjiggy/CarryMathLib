pragma solidity ^0.8.20;

/// @title CarryMathLib
import {MockVault} from "./MockVault.sol";
import "forge-std/Test.sol";

contract MockVaultTest is Test {
    MockVault vault;
    address constant USER = address(0xBEEF);

    function setUp() public {
        vault = new MockVault();
    }

    function testDoMath() public {
        uint256 result = vault.doMath(2e18, 3e18, 1e18, "test", 0);
        assertEq(result, 6e18);
    }

    function testGetAndResetCarry() public {
        vm.startPrank(USER);
        bytes32 ns = keccak256(bytes("carryTest"));
        vault.doMath(5, 1, 3, ns, 0);
        uint256 carry = vault.getCarry(ns, 0);
        assertEq(carry, 2);

        vault.resetCarry(ns, 0);
        uint256 resetCarry = vault.getCarry(ns, 0);
        assertEq(resetCarry, 0);
        vm.stopPrank();
    }

    function testCarryAccumulation() public {
        vm.startPrank(USER);
        bytes32 ns = keccak256(bytes("accumTest"));
        uint256 total;
        for (uint256 i = 0; i < 10; ++i) {
            uint256 result = vault.doMath(1, 1, 3, ns, 0);
            total += result;
        }

        // 10 / 3 = 3 * 3 + 1 remainder
        assertEq(total, 3);
        uint256 carry = vault.getCarry(ns, 0);
        assertEq(carry, 1);
        vm.stopPrank();
    }
}
