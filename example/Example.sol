pragma solidity ^0.8.20;
// SPDX-License-Identifier: MIT
import {CarryMathLib} from "../src/CarryMathLib.sol";
import {FixedPointMathLib} from "@solady-utils/FixedPointMathLib.sol";
/* Example contract to demonstrate CarryMathLib usage using memory counters.
** This pattern will be most useful for complex functions requiring
** multiple carry-tracked operations in separate namespaces. */

contract Example {
    using FixedPointMathLib for uint256;
    // NAMESPACES
    bytes32 private rewardsNamespace = keccak256(bytes("rewards"));
    bytes32 private feesNamespace = keccak256(bytes("fees"));

    // rewards namespace and fees namespace within doSomeMath.selector are isolated
    function doSomeMath(uint256 x, uint256 y, uint256 d)
        external
        returns (uint256 rewardOne, uint256 rewardTwo, uint256 fee, uint256 normalCalc)
    {
        // two unique important operations so we use the same namespace but different counters
        // Use CarryMathLib syntax directly so we can still use FixedPointMathLib for math not needing carry tracking
        {
            uint256 rewardsCounter;
            rewardOne = CarryMathLib.mulDiv(x, y, d, rewardsNamespace, rewardsCounter);
            rewardTwo = CarryMathLib.mulDiv(x, y, d, rewardsNamespace, rewardsCounter++);
        }
        // fee is isolated in its own namespace and counter
        fee = CarryMathLib.mulDiv(x, y, d, feesNamespace, 0);

        // To avoid unnecessary gas costs, we can still use other math libs normally
        normalCalc = x.mulDiv(y, d);
    }

    // different function selector, so different isolation context
    function doSomeOtherMath(uint256 x, uint256 y, uint256 d) external returns (uint256 reward, uint256 fee) {
        // rewards and fees carry are preserved across function calls
        reward = CarryMathLib.mulDiv(x, y, d, rewardsNamespace, 0);
        fee = CarryMathLib.mulDiv(x, y, d, feesNamespace, 0);
    }
}

