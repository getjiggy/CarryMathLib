pragma solidity ^0.8.20;
// SPDX-License-Identifier: MIT

library CarryMathLib {
    uint256 internal constant ONE = 1e18;

    // --- Internal storage namespace ---
    // keccak256("carry.math.slot") -> isolate from collisions
    bytes32 internal constant _CARRY_NAMESPACE = keccak256("carry.math.slot");

    struct CarrySlot {
        uint256 remainder;
    }

    // Compute a deterministic storage slot for each (caller, selector)
    function _slotFor(address account, bytes4 selector) private pure returns (bytes32 slot) {
        return keccak256(abi.encodePacked(_CARRY_NAMESPACE, account, selector));
    }

    // Load storage struct for current msg.sender + current function selector
    function _load() private view returns (CarrySlot storage s) {
        bytes32 slot = _slotFor(msg.sender, msg.sig);

        assembly {
            s.slot := slot
        }
    }

    /// @notice Multiply/divide with automatic carry tracking based on (caller, selector)
    function mulDiv(uint256 x, uint256 y, uint256 d) internal returns (uint256 z) {
        CarrySlot storage s = _load();

        uint256 mult = x * y;
        uint256 sum = mult + s.remainder;
        z = sum / d;
        s.remainder = sum % d;
    }

    /// @notice Peek current carry for this function (optional)
    function peekCarry() internal view returns (uint256) {
        CarrySlot storage s = _load();
        return s.remainder;
    }

    /// @notice Reset carry (e.g., during state resets or audits)
    function resetCarry() internal {
        CarrySlot storage s = _load();
        s.remainder = 0;
    }
}
