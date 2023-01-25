pragma solidity ^0.8.0;

import {ClonesWithImmutableArgs} from "clones-with-immutable-args/ClonesWithImmutableArgs.sol";
import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IVestingVaultFactory} from "vesting/interfaces/IVestingVaultFactory.sol";
import {ECOxEmployeeLockup} from "./ECOxEmployeeLockup.sol";

contract ECOxEmployeeLockupFactory is IVestingVaultFactory {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ClonesWithImmutableArgs for address;

    address public immutable implementation;

    address public immutable token;

    address public immutable staking;

    constructor(
        address _implementation,
        address _token,
        address _staking
    ) {
        implementation = _implementation;
        token = _token;
        staking = _staking;
    }

    /**
     * @notice Creates a new vesting vault
     * @param beneficiary The address who will receive tokens over time
     * @param admin The address that can claw back unvested funds
     * @param timestamp The cliff timestamp at which tokens vest
     * @return The address of the ECOxEmployeeLockup contract created
     */

    function createVault(
        address beneficiary,
        address admin,
        uint256 timestamp
    ) public returns (address) {
        uint256 len = 1;
        bytes memory data = abi.encodePacked(
            token,
            beneficiary,
            len,
            [0],
            [timestamp]
        );
        ECOxEmployeeLockup clone = ECOxEmployeeLockup(
            implementation.clone(data)
        );

        clone.initialize(admin, staking);
        emit VaultCreated(token, beneficiary, address(clone));
        return address(clone);
    }
}
