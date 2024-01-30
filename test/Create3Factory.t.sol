// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../src/Create3Factory.sol";

import {RolesAuthority} from "solmate/auth/authorities/RolesAuthority.sol";

import {Foo} from "./helpers/Foo.sol";
import {Counter} from "./helpers/Counter.sol";
import {Create2} from "./helpers/Create2.sol";

contract Create3FactoryTest is Test {
    address public constant DAO_MULTISIG = address(0xBABE);
    address public immutable AUTHORITY = makeAddr("authority");

    Create3Factory public create3Factory;
    RolesAuthority public roles;

    address public dummy = makeAddr("dummy");
    uint256 public chain2;
    uint256 public chain1;

    function setUp() public {
        // Create ForkIds //
        // Create blockchain with anvil with `anvil -p 8545 --chain-id 1` and `anvil -p 8546 --chain-id 2`
        chain1 = vm.createFork("http://localhost:8545");
        chain2 = vm.createFork("http://localhost:8546");

        vm.startPrank(DAO_MULTISIG);

        // Deploy Create3Factory on chain1
        vm.selectFork(chain1);
        create3Factory = Create3Factory(Create2.deploy(keccak256("Create3Factory"), type(Create3Factory).creationCode));

        // Deploy Create3Factory on chain2
        vm.selectFork(chain2);
        assertEq(
            Create2.deploy(keccak256("Create3Factory"), type(Create3Factory).creationCode),
            address(create3Factory),
            "Create3Factory should be deployed at the same address on both chains"
        );

        // Assert Create3Factory is well deployed on both chains
        assertNotEq(address(create3Factory), address(0), "Create3Factory should have a valid address");
        assertNotEq(address(create3Factory).code.length, 0, "Create3Factory should have a valid code");

        // Add authority on create3Factory on chain 2
        vm.selectFork(chain2);
        roles = new RolesAuthority(DAO_MULTISIG, Authority(address(0))); // Deploy Roles Authority
        create3Factory.setAuthority(Authority(roles)); // Set Authority on Create3Factory
        roles.setRoleCapability(uint8(1), address(create3Factory), Create3Factory.deploy.selector, true); // Create role
        roles.setUserRole(dummy, uint8(1), true); // Add dummy to role
        vm.stopPrank();
    }

    /// @notice Test deploying contract on 2 differents chain, with two different constructor arguments with 2 different users
    /// The result should be the same contract deployed at the same address on both chains and with different constructor arguments.
    function test_DeployWithFactory_CrossChain_With2DifferentUser_With2DifferentConstructorArgs() public {
        bytes32 salt = keccak256("Counter");

        //vm.selectFork(chain1);
        address predicted = create3Factory.getDeployed(salt);

        vm.prank(DAO_MULTISIG);
        vm.selectFork(chain1);
        address counterChain1 =
            create3Factory.deploy(salt, abi.encodePacked(type(Counter).creationCode, abi.encode(123)));
        uint256 countChain1 = Counter(counterChain1).count();

        vm.prank(dummy);
        vm.selectFork(chain2);
        address counterChain2 =
            create3Factory.deploy(salt, abi.encodePacked(type(Counter).creationCode, abi.encode(456)));
        uint256 countChain2 = Counter(counterChain1).count();

        // Assertions
        assertEq(predicted, counterChain1, "Counter should be deployed at the predicted address");
        assertNotEq(counterChain1, address(0), "Create3Factory should have a valid address");
        assertNotEq(counterChain1.code.length, 0, "Create3Factory should have a valid code");
        assertEq(counterChain2, counterChain1, "Counter should be deployed at the same address on both chains");
        assertNotEq(countChain1, countChain2, "Counter should be deployed with different count on both chains");
    }

    /// @notice Test deploying contract on 2 differents chain, with two different constructor arguments with the same user
    /// and when a contract are not deployed in the same order on both chains.
    function test_DeployWithFactory_WhenAContractIsDeployedBefore() public {
        bytes32 salt1 = keccak256("Counter");
        bytes32 salt2 = keccak256("Dummy");

        address predicted = create3Factory.getDeployed(salt1);

        vm.startPrank(DAO_MULTISIG);
        vm.selectFork(chain1);
        address counterChain1 =
            create3Factory.deploy(salt1, abi.encodePacked(type(Counter).creationCode, abi.encode(123)));
        uint256 countChain1 = Counter(counterChain1).count();
        address foo1 = create3Factory.deploy(salt2, abi.encodePacked(type(Foo).creationCode));
        vm.stopPrank();

        vm.startPrank(dummy);
        vm.selectFork(chain2);
        address foo2 = create3Factory.deploy(salt2, abi.encodePacked(type(Foo).creationCode));
        address counterChain2 =
            create3Factory.deploy(salt1, abi.encodePacked(type(Counter).creationCode, abi.encode(456)));
        uint256 countChain2 = Counter(counterChain1).count();
        vm.stopPrank();

        // Assertions
        assertEq(predicted, counterChain1, "Counter should be deployed at the predicted address");
        assertNotEq(counterChain1, address(0), "Create3Factory should have a valid address");
        assertNotEq(counterChain1.code.length, 0, "Create3Factory should have a valid code");
        assertEq(counterChain2, counterChain1, "Counter should be deployed at the same address on both chains");
        assertNotEq(countChain1, countChain2, "Counter should be deployed with different count on both chains");
        assertEq(foo1, foo2, "Foo should be deployed at the same address on both chains");
        assertNotEq(foo1, address(0), "Create3Factory should have a valid address");
        assertNotEq(foo1.code.length, 0, "Create3Factory should have a valid code");
    }
}
