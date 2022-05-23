// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {IERC1820RegistryUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/utils/introspection/IERC1820RegistryUpgradeable.sol";
import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ChunkedVestingVault} from "vesting/ChunkedVestingVault.sol";
import {VestingVault} from "vesting/VestingVault.sol";
import {IECOx} from "./interfaces/IECOx.sol";
import {IECOxLockup} from "./interfaces/IECOxLockup.sol";

/**
 * @notice VestingVault contract for the ECOx currency
 */
contract ECOxVestingVault is ChunkedVestingVault {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Lockup address is invalid
    error InvalidLockup();

    event Unstake(uint256 amount);

    IERC1820RegistryUpgradeable internal constant ERC1820 =
        IERC1820RegistryUpgradeable(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 internal constant LOCKUP_HASH =
        keccak256(abi.encodePacked("ECOxLockup"));

    address public lockup;

    /**
     * @notice Initializes the vesting vault
     * @dev this pulls in the required ERC20 tokens from the sender to setup
     */
    function initialize() public override initializer {
        ChunkedVestingVault._initialize();

        address _lockup = getECOxLockup();
        if (_lockup == address(0)) revert InvalidLockup();
        lockup = _lockup;

        stakeECOx();
        delegateECOx();
    }

    /**
     * @inheritdoc ChunkedVestingVault
     */
    function onClaim(uint256 amount) internal override {
        unstakeVestedECOx();
        super.onClaim(amount);
    }

    /**
     * @notice Fetches the ECOxLockup contract from ERC1820Registry
     * @return The ECOx Lockup contract
     */
    function getECOxLockup() internal returns (address) {
        address policy = IECOx(address(token())).policy();
        return ERC1820.getInterfaceImplementer(policy, LOCKUP_HASH);
    }

    /**
     * @notice Stakes ECOx in the lockup contract
     */
    function stakeECOx() internal {
        address _lockup = lockup;
        uint256 amount = token().balanceOf(address(this));
        token().approve(_lockup, amount);
        IECOxLockup(_lockup).deposit(amount);
    }

    /**
     * @notice Delegates staked ECOx back to the beneficiary
     */
    function delegateECOx() internal {
        IECOxLockup(lockup).delegate(beneficiary());
    }

    /**
     * @notice Unstakes any vested staked ECOx that hasn't already been unstaked
     * @dev this allows users to vote with unvested tokens while still
     * being able to claim vested tokens
     * @return The amount of ECOx unstaked
     */
    function unstakeVestedECOx() public returns (uint256) {
        if (msg.sender != beneficiary()) revert Unauthorized();
        uint256 amount = vested() - token().balanceOf(address(this));
        IECOxLockup(lockup).withdraw(amount);
        emit Unstake(amount);
        return amount;
    }

    /**
     * @inheritdoc VestingVault
     */
    function unvested() public view override returns (uint256) {
        return
            IERC20Upgradeable(lockup).balanceOf(address(this)) +
            token().balanceOf(address(this)) -
            vested();
    }
}
