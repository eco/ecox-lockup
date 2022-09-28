pragma solidity 0.8.15;

import {ClonesWithImmutableArgs} from "clones-with-immutable-args/ClonesWithImmutableArgs.sol";
import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IVestingVaultFactory} from "vesting/interfaces/IVestingVaultFactory.sol";
import {ECOxEmployeeLockup} from "./ECOxEmployeeLockup.sol";

contract ECOxEmployeeLockupFactory is IVestingVaultFactory {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ClonesWithImmutableArgs for address;

    address public immutable implementation;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    /**
     * @notice Creates a new vesting vault
     * @param token The ERC20 token to vest over time
     * @param beneficiary The address who will receive tokens over time
     * @param admin The address that can claw back unvested funds
     * @param amount The total ecoX to be dripped to employee
     */

    function createVault(
        address token,
        address beneficiary,
        address admin,
        uint256 amount, 
        uint256 timestamp
    ) public returns (address) {
        uint256 len = 1;
        bytes memory data = abi.encodePacked(
            token,
            beneficiary,
            len,
            [amount],
            [timestamp]
        );
        ECOxEmployeeLockup clone = ECOxEmployeeLockup(implementation.clone(data));

        //
        // uint256 totalTokens = clone.vestedOn(type(uint256).max);

        // IERC20Upgradeable(token).safeTransferFrom(
        //     msg.sender,
        //     address(clone),
        //     amount
        // );
        // IERC20Upgradeable(token).approve(address(clone), amount);
        // clone.initialize(admin);
        emit VaultCreated(token, beneficiary, address(clone));
        return address(clone);
    }
}