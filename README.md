## CarryMathLib

This is an unaudited exploratory library seeking ways to reduce protocol exploits due to rounding errors. DO NOT USE THIS IN PRODUCTION.

## Inspiration

Inspired by the recent Bunni.xyz and Balancer hacks, I had a thought. Solidity rounding is a fact of the language, however with some clever engineering, we can actually account for this loss by keeping track of the cumulative remainder.

## Isolation

This library attempts to provide easy to use isolation for important math operations. automatic isolation occurs on every (msg.sender, msg.sig) combination. Each external contract calling the library will automatically have one space for each of its own external functions. Additional isolation is achieved through namespace and counters. For a given namespace 'ns', you can further isolate operations with a counter. this is useful if you perform multiple important operations within the same external function, ie calculating interest and rewards in the same external function call. it is recommended to use memory counters, otherwise you must remember to reset the storage counter at the end of execution or otherwise ensure counters are properly tracked per operation. 

## Notes

This Repo is experimental, unaudited and was hacked together in a few hours.

## Usage

```solidity
import {CarryMathLib} from "CarryMathLib/CarryMathLib.sol";
contract NeedsAccurateMath {
    // NAMESPACES
    bytes32 private rewardsNamespace = keccak256(bytes("rewards"));
    bytes32 private interestNamespace = keccak256(bytes("interest"));

    function importantMath(uint256 x, uint256 y, uint256 z)
        external
        returns (uint256 rewardsResultOne, uint256 rewardsResultTwo, uint256 interestResultOne)
    {
        // counter for seperation within namespace and msg.sig
        uint256 rewardsCounter;
        rewardsResultOne = CarryMathLib.mulDivAuto(1, 1, 3, rewardsNameSpace, rewardsCounter);
        rewardsResultTwo = CarryMathLib.mulDivAuto(1, 1, 3, rewardsNameSpace, rewardsCounter++);
        interestResultOne = CarryMathLib.mulDivAuto(1, 1, 3, interestNameSpace, 0);
    }
}
```
