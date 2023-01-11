// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ERC20Upgradeable} from
    "../../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Upgradeable} from
    "../../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from
    "../../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC1820ImplementerUpgradeable} from
    "../../../lib/openzeppelin-contracts-upgradeable/contracts/utils/introspection/IERC1820ImplementerUpgradeable.sol";
import {IERC1820RegistryUpgradeable} from
    "../../../lib/openzeppelin-contracts-upgradeable/contracts/utils/introspection/IERC1820RegistryUpgradeable.sol";
import {IECOx} from "../../interfaces/IECOx.sol";
import {IECOxLockup} from "../../interfaces/IECOxLockup.sol";

contract MockLockup is IECOxLockup, ERC20Upgradeable, IERC1820ImplementerUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice User cannot withdraw after voting
    error Voted();

    bytes32 internal constant ERC1820_ACCEPT_MAGIC = keccak256(abi.encodePacked("ERC1820_ACCEPT_MAGIC"));

    address public eco;
    mapping(address => address) delegates;
    mapping(address => mapping(address => uint256)) delegatedAmounts;
    bool voted;

    constructor(address _eco) {
        eco = _eco;
    }

    function canImplementInterfaceForAddress(bytes32, address) public pure override returns (bytes32) {
        return ERC1820_ACCEPT_MAGIC;
    }

    function deposit(uint256 _amount) external {
        IERC20Upgradeable(eco).safeTransferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
    }

    function delegate(address delegatee) public {
        delegates[msg.sender] = delegatee;
    }

    function delegateAmount(address delegatee, uint256 amount) external {
        delegate(delegatee);
    }

    function undelegate() external {
        delegates[msg.sender] = address(0);
    }

    function undelegateFromAddress(address delegatee) external {
        delegatedAmounts[msg.sender][delegatee] = 0;
    }

    function isDelegated(address from, address delegatee) external view returns (bool) {
        return delegates[from] == delegatee;
    }

    function setVoted(bool value) external {
        voted = value;
    }

    function withdraw(uint256 _amount) external {
        if (voted) revert Voted();
        IERC20Upgradeable(eco).safeTransfer(msg.sender, _amount);
        _burn(msg.sender, _amount);
    }
}
