// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";
import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {MockECOx} from "./mock/MockECOx.sol";
import {MockBeneficiary} from "./mock/MockBeneficiary.sol";
import {MockLockup} from "./mock/MockLockup.sol";
import {IVestingVault} from "vesting/interfaces/IVestingVault.sol";
import {IERC1820RegistryUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/utils/introspection/IERC1820RegistryUpgradeable.sol";
import {ECOxLockupVaultFactory} from "../ECOxLockupVaultFactory.sol";
import {ECOxLockupVault} from "../ECOxLockupVault.sol";
import {IECOx} from "../interfaces/IECOx.sol";


contract ECOxLockupVaultTest is Test, GasSnapshot {
    ECOxLockupVaultFactory factory;
    ECOxLockupVault vault;
    MockECOx token;
    IERC1820RegistryUpgradeable ERC1820;
    MockLockup stakedToken;
    MockBeneficiary beneficiary;
    uint256 initialTimestamp;
    bytes32 LOCKUP_HASH = keccak256(abi.encodePacked("ECOxStaking"));

    function setUp() public {
        deployERC1820();
        ERC1820 = IERC1820RegistryUpgradeable(
            0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24
        );

        token = new MockECOx("Mock", "MOCK", 18);
        ECOxLockupVault implementation = new ECOxLockupVault();
        stakedToken = MockLockup(getECOxStaking());
        factory = new ECOxLockupVaultFactory(
            address(implementation),
            address(token),
            address(stakedToken)
        );
        beneficiary = new MockBeneficiary();
        initialTimestamp = block.timestamp;

        token.mint(address(this), 300);
        token.approve(address(factory), 300);
        snapStart("createVault");
        vault = ECOxLockupVault(
            factory.createVault(
                address(beneficiary),
                address(address(this)),
                makeArray(100, 100, 100),
                makeArray(
                    initialTimestamp + 1 days,
                    initialTimestamp + 2 days,
                    initialTimestamp + 3 days
                )
            )
        );
        snapEnd();
        stakedToken = MockLockup(vault.lockup());
    }

    function testInstantiation() public {
        assertEq(address(vault.token()), address(token));
        assertEq(address(vault.beneficiary()), address(beneficiary));
        assertEq(vault.vestingPeriods(), 3);

        assertUintArrayEq(vault.amounts(), makeArray(100, 100, 100));
        assertUintArrayEq(
            vault.timestamps(),
            makeArray(
                initialTimestamp + 1 days,
                initialTimestamp + 2 days,
                initialTimestamp + 3 days
            )
        );
        assertEq(vault.vestedChunks(), 0);
        assertEq(vault.vested(), 0);
        assertEq(vault.vestedOn(initialTimestamp + 1 days), 100);
        assertEq(vault.vestedOn(initialTimestamp + 2 days), 200);
        assertEq(vault.vestedOn(initialTimestamp + 3 days), 300);
    }

    function testLockupAllThenClaim() public {
        assertEq(vault.vested(), 0);
        assertEq(vault.unvested(), 300);
        vm.warp(initialTimestamp + 1 days);
        assertEq(vault.vested(), 100);
        assertEq(vault.unvested(), 200);
        vm.warp(initialTimestamp + 2 days);
        assertEq(vault.vested(), 200);
        assertEq(vault.unvested(), 100);
        vm.warp(initialTimestamp + 3 days);
        assertEq(vault.vested(), 300);
        assertEq(vault.unvested(), 0);

        assertClaimAmount(300);

        assertEq(vault.vested(), 0);
        assertEq(vault.unvested(), 0);
    }

    function testClaimPartial() public {
        assertEq(vault.vested(), 0);
        assertEq(vault.unvested(), 300);
        vm.warp(initialTimestamp + 1 days);
        assertEq(vault.vested(), 100);
        assertEq(vault.unvested(), 200);
        assertClaimAmount(100);
        assertEq(vault.vested(), 0);
        assertEq(vault.unvested(), 200);

        vm.warp(initialTimestamp + 2 days);
        assertEq(vault.vested(), 100);
        assertEq(vault.unvested(), 100);
        assertClaimAmount(100);
        assertEq(vault.vested(), 0);
        assertEq(vault.unvested(), 100);

        vm.warp(initialTimestamp + 3 days);
        assertEq(vault.vested(), 100);
        assertEq(vault.unvested(), 0);
        assertClaimAmount(100);
        assertEq(vault.vested(), 0);
        assertEq(vault.unvested(), 0);
    }

    function testUnstakePartial() public {
        assertEq(vault.vested(), 0);
        assertEq(vault.unvested(), 300);
        vm.warp(initialTimestamp + 1 days);
        assertEq(vault.vested(), 100);
        assertEq(vault.unvested(), 200);
        uint256 unstaked = beneficiary.unstake(vault, 100);
        assertEq(unstaked, 100);
        assertEq(vault.vested(), 100);
        assertEq(vault.unvested(), 200);
        assertClaimAmount(100);
        assertEq(vault.vested(), 0);
        assertEq(vault.unvested(), 200);

        vm.warp(initialTimestamp + 2 days);
        assertEq(vault.vested(), 100);
        assertEq(vault.unvested(), 100);
        unstaked = beneficiary.unstake(vault, 100);
        assertEq(unstaked, 100);
        assertEq(vault.vested(), 100);
        assertEq(vault.unvested(), 100);
        assertClaimAmount(100);
        assertEq(vault.vested(), 0);
        assertEq(vault.unvested(), 100);

        vm.warp(initialTimestamp + 3 days);
        assertEq(vault.vested(), 100);
        assertEq(vault.unvested(), 0);
        unstaked = beneficiary.unstake(vault, 100);
        assertEq(unstaked, 100);
        assertEq(vault.vested(), 100);
        assertEq(vault.unvested(), 0);
        assertClaimAmount(100);
        assertEq(vault.vested(), 0);
        assertEq(vault.unvested(), 0);
    }

    function testFailUnstakeMultipleTimes() public {
        assertEq(vault.vested(), 0);
        assertEq(vault.unvested(), 300);
        vm.warp(initialTimestamp + 1 days);
        assertEq(vault.vested(), 100);
        assertEq(vault.unvested(), 200);
        uint256 unstaked = beneficiary.unstake(vault, 100);
        assertEq(unstaked, 100);
        unstaked = beneficiary.unstake(vault, 100);
        assertEq(unstaked, 100);
        unstaked = beneficiary.unstake(vault, 100);
        assertEq(unstaked, 100);

        beneficiary.unstake(vault, 101);
    }

    function testAssertDelegation() public {
        assertTrue(
            stakedToken.isAmountDelegated(address(vault), address(beneficiary))
        );
        assertFalse(stakedToken.isAmountDelegated(address(vault), address(this)));
        assertFalse(stakedToken.isAmountDelegated(address(vault), address(factory)));
        vm.warp(initialTimestamp + 1 days);
        assertClaimAmount(100);
        assertTrue(
            stakedToken.isAmountDelegated(address(vault), address(beneficiary))
        );
        assertFalse(stakedToken.isAmountDelegated(address(vault), address(this)));
        assertFalse(stakedToken.isAmountDelegated(address(vault), address(factory)));
    }

    function testDelegateNotBeneficiary() public {
        vm.expectRevert(IVestingVault.Unauthorized.selector);
        vault.delegate(address(this));
    }

    function testDelegate() public {
        assertTrue(
            stakedToken.isAmountDelegated(address(vault), address(beneficiary))
        );
        beneficiary.delegate(vault, address(this));
        assertFalse(
            stakedToken.isAmountDelegated(address(vault), address(beneficiary))
        );
        
        assertTrue(stakedToken.isAmountDelegated(address(vault), address(this)));
    }

    function testECOxStaking() public {
        assertEq(token.balanceOf(address(vault)), 0);
        // instead of ECOx in the vault, it stores sECOx
        assertEq(stakedToken.balanceOf(address(vault)), 300);
        vm.warp(initialTimestamp + 1 days);
        assertClaimAmount(100);
        assertEq(token.balanceOf(address(vault)), 0);
        assertEq(stakedToken.balanceOf(address(vault)), 200);
    }

    function testClawback() public {
        assertEq(vault.vested(), 0);
        assertEq(vault.unvested(), 300);
        vm.warp(initialTimestamp + 1 days);
        assertEq(vault.vested(), 100);
        assertEq(vault.unvested(), 200);

        snapStart("clawback");
        vault.clawback();
        snapEnd();
        assertEq(vault.vested(), 100);
        assertEq(vault.unvested(), 0);
        assertEq(stakedToken.balanceOf(address(vault)), 100);
        assertClaimAmount(100);
    }

    function testClawbackClaimFirst() public {
        assertEq(vault.vested(), 0);
        assertEq(vault.unvested(), 300);
        vm.warp(initialTimestamp + 1 days);
        assertEq(vault.vested(), 100);
        assertEq(vault.unvested(), 200);

        snapStart("claim");
        beneficiary.claim(vault);
        snapEnd();
        vault.clawback();
        assertEq(vault.vested(), 0);
        assertEq(vault.unvested(), 0);
        assertEq(stakedToken.balanceOf(address(vault)), 0);
    }

    function testClawbackUnstaked() public {
        beneficiary.unstake(vault, 49);
        assertEq(token.balanceOf(address(vault)), 49);
        assertEq(stakedToken.balanceOf(address(vault)), 251);
        assertEq(token.balanceOf(address(this)), 0);

        vault.clawback();

        assertEq(token.balanceOf(address(vault)), 0);
        assertEq(stakedToken.balanceOf(address(vault)), 0);
        assertEq(token.balanceOf(address(this)), 300);
    }

    function testClawbackDelegated() public {
        beneficiary.delegate(vault, address(beneficiary));
        assertTrue(
            stakedToken.isAmountDelegated(address(vault), address(beneficiary))
        );
        assertEq(stakedToken.balanceOf(address(vault)), 300);
        assertEq(token.balanceOf(address(this)), 0);

        vault.clawback();

        assertEq(stakedToken.balanceOf(address(vault)), 0);
        assertEq(token.balanceOf(address(this)), 300);
    }

    function testClawbackUnstakedDelegated() public {
        beneficiary.unstake(vault, 49);
        beneficiary.delegate(vault, address(beneficiary));
        assertTrue(
            stakedToken.isAmountDelegated(address(vault), address(beneficiary))
        );
        assertEq(token.balanceOf(address(vault)), 49);
        assertEq(stakedToken.balanceOf(address(vault)), 251);
        assertEq(token.balanceOf(address(this)), 0);

        vault.clawback();

        assertEq(token.balanceOf(address(vault)), 0);
        assertEq(stakedToken.balanceOf(address(vault)), 0);
        assertEq(token.balanceOf(address(this)), 300);
    }

    // note: can parameterize count & amountPerUnlock,
    // but it is very slow
    // function testManyUnlocks(uint8 count, uint64 amountPerUnlock) public {
    function testManyUnlocks() public {
        uint16 count = 500;
        uint256 amountPerUnlock = 12341234;
        uint256[] memory amounts = new uint256[](count);
        uint256[] memory timestamps = new uint256[](count);
        token.mint(address(this), uint256(count) * amountPerUnlock);
        token.approve(address(factory), uint256(count) * amountPerUnlock);
        for (uint256 i = 0; i < count; i++) {
            amounts[i] = amountPerUnlock;
            timestamps[i] = initialTimestamp + ((i + 1) * 86400);
        }

        vault = ECOxLockupVault(
            factory.createVault(
                address(beneficiary),
                address(0),
                amounts,
                timestamps
            )
        );

        for (uint256 i = 0; i < count; i++) {
            vm.warp(initialTimestamp + ((i + 1) * 86400));
            assertClaimAmount(amountPerUnlock);
        }
    }

    function testUnstakeNonLockedup() public {
        uint256 unstaked = beneficiary.unstake(vault, 100);
        assertEq(unstaked, 100);
    }

    function testFailUnstakedNonBeneficiary() public {
        vm.warp(initialTimestamp + 1 days);
        vault.unstake(5);
    }

    function testFailWithdrawAfterVoting() public {
        vm.warp(initialTimestamp + 1 days);
        stakedToken.setVoted(true);
        assertClaimAmount(100);
    }

    function testStakeAlreadyStaked(uint256 amount) public {
        if (amount == 0) amount = 1;
        assertEq(vault.vested(), 0);
        vm.expectRevert(ECOxLockupVault.InvalidAmount.selector);
        beneficiary.stake(vault, amount);
    }

    function testStakeNotBeneficiary() public {
        vm.warp(initialTimestamp + 1 days);
        assertEq(vault.vested(), 100);
        vm.expectRevert(IVestingVault.Unauthorized.selector);
        vault.stake(100);
    }

    function testWarpAndClaim(uint256 timestamp) public {
        vm.warp(timestamp);
        if (timestamp >= initialTimestamp + 3 days) {
            assertClaimAmount(300);
        } else if (timestamp >= initialTimestamp + 2 days) {
            assertClaimAmount(200);
        } else if (timestamp >= initialTimestamp + 1 days) {
            assertClaimAmount(100);
        } else {
            assertEq(vault.vested(), 0);
        }
    }

    function testFailTooManyAmounts() public {
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 100;
        amounts[1] = 200;
        amounts[2] = 300;
        amounts[3] = 400;
        vault = ECOxLockupVault(
            factory.createVault(
                address(beneficiary),
                address(0),
                amounts,
                makeArray(
                    initialTimestamp + 1 days,
                    initialTimestamp + 2 days,
                    initialTimestamp + 3 days
                )
            )
        );
    }

    function testFailTooManyTimestamps() public {
        uint256[] memory timestamps = new uint256[](4);
        timestamps[0] = initialTimestamp + 1 days;
        timestamps[1] = initialTimestamp + 2 days;
        timestamps[2] = initialTimestamp + 3 days;
        timestamps[3] = initialTimestamp + 4 days;
        vault = ECOxLockupVault(
            factory.createVault(
                address(beneficiary),
                address(0),
                makeArray(100, 100, 100),
                timestamps
            )
        );
    }

    function testFailClaimUnauthorized(uint256 timestamp) public {
        vm.warp(timestamp);
        MockBeneficiary fakeBeneficiary = new MockBeneficiary();
        fakeBeneficiary.claim(vault);
    }

    function testFailClaimZero() public {
        assertClaimAmount(0);
    }

    function testPreventAdminClawBackByUnstaking() public {
        assertEq(stakedToken.balanceOf(address(vault)), 300);
        assertEq(token.balanceOf(address(vault)), 0);
        assertEq(vault.vested(), 0);
        assertEq(vault.unvested(), 300);

        beneficiary.unstake(vault, 10);
        assertEq(token.balanceOf(address(vault)), 10);
        assertEq(vault.unvested(), 300);

        vault.clawback();
        assertEq(token.balanceOf(address(vault)), 0);
        assertEq(stakedToken.balanceOf(address(vault)), 0);
    }

    function testPreventAdminClawBackByTransfer() public {
        assertEq(stakedToken.balanceOf(address(vault)), 300);
        assertEq(token.balanceOf(address(vault)), 0);
        assertEq(vault.vested(), 0);
        assertEq(vault.unvested(), 300);

        token.mint(address(vault), 1);
        assertEq(token.balanceOf(address(vault)), 1);
        assertEq(vault.unvested(), 301);

        vault.clawback();
        assertEq(token.balanceOf(address(vault)), 0);
        assertEq(stakedToken.balanceOf(address(vault)), 0);
    }

    function assertClaimAmount(uint256 amount) internal {
        assertEq(vault.vested(), amount);
        uint256 initialBalance = token.balanceOf(address(beneficiary));
        uint256 initialVaultBalance = stakedToken.balanceOf(address(vault)) +
            token.balanceOf(address(vault));
        beneficiary.claim(vault);
        assertEq(
            initialBalance + amount,
            token.balanceOf(address(beneficiary))
        );
        assertEq(
            initialVaultBalance - amount,
            stakedToken.balanceOf(address(vault))
        );
    }

    function makeArray(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint256[] memory) {
        uint256[] memory result = new uint256[](3);
        result[0] = a;
        result[1] = b;
        result[2] = c;
        return result;
    }

    function deployERC1820() internal {
        vm.etch(
            address(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24),
            bytes(
                hex"608060405234801561001057600080fd5b50600436106100a5576000357c010000000000000000000000000000000000000000000000000000000090048063a41e7d5111610078578063a41e7d51146101d4578063aabbb8ca1461020a578063b705676514610236578063f712f3e814610280576100a5565b806329965a1d146100aa5780633d584063146100e25780635df8122f1461012457806365ba36c114610152575b600080fd5b6100e0600480360360608110156100c057600080fd5b50600160a060020a038135811691602081013591604090910135166102b6565b005b610108600480360360208110156100f857600080fd5b5035600160a060020a0316610570565b60408051600160a060020a039092168252519081900360200190f35b6100e06004803603604081101561013a57600080fd5b50600160a060020a03813581169160200135166105bc565b6101c26004803603602081101561016857600080fd5b81019060208101813564010000000081111561018357600080fd5b82018360208201111561019557600080fd5b803590602001918460018302840111640100000000831117156101b757600080fd5b5090925090506106b3565b60408051918252519081900360200190f35b6100e0600480360360408110156101ea57600080fd5b508035600160a060020a03169060200135600160e060020a0319166106ee565b6101086004803603604081101561022057600080fd5b50600160a060020a038135169060200135610778565b61026c6004803603604081101561024c57600080fd5b508035600160a060020a03169060200135600160e060020a0319166107ef565b604080519115158252519081900360200190f35b61026c6004803603604081101561029657600080fd5b508035600160a060020a03169060200135600160e060020a0319166108aa565b6000600160a060020a038416156102cd57836102cf565b335b9050336102db82610570565b600160a060020a031614610339576040805160e560020a62461bcd02815260206004820152600f60248201527f4e6f7420746865206d616e616765720000000000000000000000000000000000604482015290519081900360640190fd5b6103428361092a565b15610397576040805160e560020a62461bcd02815260206004820152601a60248201527f4d757374206e6f7420626520616e204552433136352068617368000000000000604482015290519081900360640190fd5b600160a060020a038216158015906103b85750600160a060020a0382163314155b156104ff5760405160200180807f455243313832305f4143434550545f4d4147494300000000000000000000000081525060140190506040516020818303038152906040528051906020012082600160a060020a031663249cb3fa85846040518363ffffffff167c01000000000000000000000000000000000000000000000000000000000281526004018083815260200182600160a060020a0316600160a060020a031681526020019250505060206040518083038186803b15801561047e57600080fd5b505afa158015610492573d6000803e3d6000fd5b505050506040513d60208110156104a857600080fd5b5051146104ff576040805160e560020a62461bcd02815260206004820181905260248201527f446f6573206e6f7420696d706c656d656e742074686520696e74657266616365604482015290519081900360640190fd5b600160a060020a03818116600081815260208181526040808320888452909152808220805473ffffffffffffffffffffffffffffffffffffffff19169487169485179055518692917f93baa6efbd2244243bfee6ce4cfdd1d04fc4c0e9a786abd3a41313bd352db15391a450505050565b600160a060020a03818116600090815260016020526040812054909116151561059a5750806105b7565b50600160a060020a03808216600090815260016020526040902054165b919050565b336105c683610570565b600160a060020a031614610624576040805160e560020a62461bcd02815260206004820152600f60248201527f4e6f7420746865206d616e616765720000000000000000000000000000000000604482015290519081900360640190fd5b81600160a060020a031681600160a060020a0316146106435780610646565b60005b600160a060020a03838116600081815260016020526040808220805473ffffffffffffffffffffffffffffffffffffffff19169585169590951790945592519184169290917f605c2dbf762e5f7d60a546d42e7205dcb1b011ebc62a61736a57c9089d3a43509190a35050565b600082826040516020018083838082843780830192505050925050506040516020818303038152906040528051906020012090505b92915050565b6106f882826107ef565b610703576000610705565b815b600160a060020a03928316600081815260208181526040808320600160e060020a031996909616808452958252808320805473ffffffffffffffffffffffffffffffffffffffff19169590971694909417909555908152600284528181209281529190925220805460ff19166001179055565b600080600160a060020a038416156107905783610792565b335b905061079d8361092a565b156107c357826107ad82826108aa565b6107b85760006107ba565b815b925050506106e8565b600160a060020a0390811660009081526020818152604080832086845290915290205416905092915050565b6000808061081d857f01ffc9a70000000000000000000000000000000000000000000000000000000061094c565b909250905081158061082d575080155b1561083d576000925050506106e8565b61084f85600160e060020a031961094c565b909250905081158061086057508015155b15610870576000925050506106e8565b61087a858561094c565b909250905060018214801561088f5750806001145b1561089f576001925050506106e8565b506000949350505050565b600160a060020a0382166000908152600260209081526040808320600160e060020a03198516845290915281205460ff1615156108f2576108eb83836107ef565b90506106e8565b50600160a060020a03808316600081815260208181526040808320600160e060020a0319871684529091529020549091161492915050565b7bffffffffffffffffffffffffffffffffffffffffffffffffffffffff161590565b6040517f01ffc9a7000000000000000000000000000000000000000000000000000000008082526004820183905260009182919060208160248189617530fa90519096909550935050505056fea165627a7a72305820377f4a2d4301ede9949f163f319021a6e9c687c292a5e2b2c4734c126b524e6c0029"
            )
        );
    }

    function assertUintArrayEq(uint256[] memory a, uint256[] memory b)
        internal
    {
        require(a.length == b.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < a.length; i++) {
            assertEq(a[i], b[i]);
        }
    }

    function getECOxStaking() internal returns (address) {
        address policy = IECOx(address(token)).policy();
        return ERC1820.getInterfaceImplementer(policy, LOCKUP_HASH);
    }
}
