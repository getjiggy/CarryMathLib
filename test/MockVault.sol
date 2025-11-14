pragma solidity ^0.8.20;
// SPDX-License-Identifier: MIT
/// @title CarryMathLib
/// @notice Deterministic hierarchical carry tracking for arithmetic operations.
import {CarryMathLib} from "../src/CarryMathLib.sol";

contract MockVault {
    function doMath(uint256 x, uint256 y, uint256 d, bytes32 name, uint256 counter) external returns (uint256) {
        return CarryMathLib.mulDiv(x, y, d, name, counter);
    }

    function getCarry(bytes32 name, uint256 counter) external view returns (uint256) {
        return CarryMathLib.getCarry(name, counter);
    }

    function resetCarry(bytes32 name, uint256 counter) external {
        CarryMathLib.resetCarry(name, counter);
    }

    function doMathMemory(uint256 x, uint256 y, uint256 d, CarryMathLib.Carry memory carry)  external pure returns (uint256, uint256) {
        return CarryMathLib.mulDivMem(x, y, d, carry);
    }

    function initCarryMem() external pure returns (CarryMathLib.Carry memory) {
        return CarryMathLib.initCarryMem();
    }
}