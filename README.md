## CarryMathLib

This is an unaudited exploratory library seeking ways to reduce protocol exploits due to rounding errors. DO NOT USE THIS IN PRODUCTION. 

## Inspiration
Inspired by the recent Bunni.xyz and Balancer hacks, I had a thought. Solidity rounding is a fact of the language, however with some clever engineering, we can actually account for this loss by keeping track of the cumulative remainder. 

## Isolation
This contract attempts to make it easy for developers to plug and play and track cumulative remainders across multiple functions. We store each remainder in a slot determined by keccak256(msg.sender, msg.sig). This isolates the remainder tracking so an external contract can use tracking in multiple places. A key stipulation of the current implementation is that all calls to CarryMathLib.mulDiv() that originate from the same contract and function signature will increment the carried amount. Basically you can only track one carry amount per external function on a contract that implements CarryMathLib. 

## Notes
I fully expect someone to rip this apart and tell me its a terrible idea. But worth nothing that when I plug this lib into the BunniV2 codebase, the exploit becomes impossible. Check for yourself here on this fork https://github.com/getjiggy/bunni-v2. This Repo is experimental, unaudited and was hacked together in a few hours. 

## Usage
```solidity
import {CarryMathLib} from "CarryMathLib/CarryMathLib.sol";

function importantMath(uint x, uint y, uint z) external {
          uint256 result = CarryMathLib.mulDiv(x, y, z);
}
```


