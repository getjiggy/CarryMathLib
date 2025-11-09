Kim## CarryMathLib

This is an unaudited exploratory library seeking ways to reduce protocol exploits due to rounding errors. DO NOT USE THIS IN PRODUCTION.

## Inspiration

Inspired by the recent Bunni.xyz and Balancer hacks, I had a thought. Solidity rounding is a fact of the language, however with some clever engineering, we can actually account for this loss by keeping track of the cumulative remainder.

## Isolation

This library attempts to provide easy to use isolation for important math operations. automatic isolation occurs on every (msg.sender, msg.sig) combination. Each external contract calling the library will automatically have one space for each of its own external functions. Additional isolation is achieved through namespace and counters. For a given namespace 'ns', you can further isolate operations with a counter. this is useful if you perform multiple important operations within the same external function, ie calculating interest and rewards in the same external function call. it is recommended to use memory counters, otherwise you must remember to reset the storage counter at the end of execution or otherwise ensure counters are properly tracked per operation. 

## Notes

This Repo is experimental, unaudited and was hacked together in a few hours. The first operation on a given slot can be expected to cost ~50000 gas. Subsequent operations can be expected to range as low as ~30000 gas, depending on the state of the storage slot and value being stored. Overall Pretty expensive for l1, but i think probably feasible for L2. 

Maybe I could squeeze a little more out of these numbers by doing a full yul implmentation (yikes!). The gain though will likely not be significant enough to warrant the additional complexity (except of course because im a masochist and ill do it anyway)

each call to mulDivMem is significantly cheaper, costing around 2000 gas. Of course this puts the burden of storing the carry on the developer and offers little benefit (imo) over simply rounding in favor of the protocol. The vast majority of exploits which a library such as this could address enter/exit functions on a contract repeatedly, which simply tracking the remainder in memory through the life of a function call cannot address, and thus tracking the remainder as part of state becomes almost a requirement to gain any benefit. 



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
