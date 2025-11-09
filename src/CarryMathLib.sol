// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


/// @title CarryMathLib
/// @notice Deterministic hierarchical carry tracking for arithmetic operations.
/// @dev Each carry is stored directly in the caller's storage, isolated by
///      (account, function selector, namespace, counter).
library CarryMathLib {

    bytes32 private constant _CARRY_NAMESPACE = keccak256("CarryMathLib.StorageRoot");

    struct Carry {
        uint256 remainder;
    }

    /// @dev Derive root for (account, selector)
    function _rootFor(address account, bytes4 selector) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_CARRY_NAMESPACE, account, selector));
    }

    /// @dev Derive deterministic slot for (account, selector, name, counter)
    function _slotFor(address account, bytes4 selector, bytes32 name, uint256 counter) private pure returns (bytes32) {
        bytes32 root = _rootFor(account, selector);
        return keccak256(abi.encodePacked(root, name, counter));
    }

    /// @notice Multiply/divide with persistent carry, stored directly in caller's storage.
    function mulDiv(uint256 x, uint256 y, uint256 d, bytes32 name, uint256 counter) internal returns (uint256 z) {
        bytes32 slot = _slotFor(msg.sender, msg.sig, name, counter);
        uint256 carryIn;
        uint256 newRemainder;
        
        // adapted from FixedPointMathLib.mulDiv
        /// @solidity memory-safe-assembly
        assembly {
            // read remainder from caller’s storage
            carryIn := sload(slot)
            if gt(x, div(not(0), y)) {
                if y {
                    mstore(0x00, 0xbac65e5b) // `MulWadFailed()`.
                    revert(0x1c, 0x04)
                }
            }
            let total := add(mul(x, y), carryIn)
            z := div(total, d)
            newRemainder := mod(total, d)

            // write new remainder to caller’s storage
            sstore(slot, newRemainder)
        }
    }

    /// @notice Read the carry remainder for a given namespace/counter.
    function getCarry(bytes32 name, uint256 counter) internal view returns (uint256 remainder) {
        bytes32 slot = _slotFor(msg.sender, msg.sig, name, counter);
        assembly {
            remainder := sload(slot)
        }
    }

    /// @notice Reset (zero) the carry for a given namespace/counter.
    function resetCarry(bytes32 name, uint256 counter) internal {
        bytes32 slot = _slotFor(msg.sender, msg.sig, name, counter);
        assembly {
            sstore(slot, 0)
        }
    }

    /// @notice Convenience wrapper with a string namespace.
    function mulDivAuto(uint256 x, uint256 y, uint256 d, string memory name, uint256 counter)
        internal
        returns (uint256)
    {
        return mulDiv(x, y, d, keccak256(bytes(name)), counter);
    }

    function mulDivMem(uint256 x, uint256 y, uint256 d, Carry memory carry)
        internal
        pure
        returns (uint256 z, uint256 newRemainder)
    {
        uint carryIn = carry.remainder;
        assembly {
            
            if gt(x, div(not(0), y)) {
                if y {
                    mstore(0x00, 0xbac65e5b) // `MulWadFailed()`.
                    revert(0x1c, 0x04)
                }
            }
            let total := add(mul(x, y), carryIn)
            z := div(total, d)
            newRemainder := mod(total, d)
        }
    }
        /// @notice Helper to seed/reset carry (e.g., on pool initialization).
    function initCarryMem() internal pure returns (Carry memory) {
        return Carry({ remainder: 0 });
    }
}
