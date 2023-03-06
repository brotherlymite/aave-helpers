// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library EngineFlags {
  /// @dev magic value to be used as flag to keep unchanged any current configuration
  /// Strongly assumes that the value `type(uint256).max - 42` will be used, which seems reasonable
  uint256 public constant KEEP_CURRENT = type(uint256).max - 42;

  /// @dev value to be used as flag for bool value true
  uint256 public constant ENABLED = 1;

  /// @dev value to be used as flag for bool value false
  uint256 public constant DISABLED = 0;
}
