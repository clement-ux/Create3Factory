// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Auth} from "solmate/auth/Auth.sol";
import {CREATE3} from "solmate/utils/CREATE3.sol";
import {Authority} from "solmate/auth/Auth.sol";

/// @title Create3Factory with Authority
/// @author https://github.com/clement-ux
/// @notice This contract is a Create3Factory with Authority
///         It aims to be the central point of deployment for all contracts for a DAO.
///         DAO can authorize someone else to deploy contracts on their behalf for example to a EOA-deployer, in order to acvhive cross-chain replication.
/// @dev This contract need to be deployed with create2, in order to be achive cross-chain replication easly.
contract Create3Factory is Auth {
    address public constant DAO_MULTISIG = address(0xBABE); // This address is just an example, it should be replaced by the DAO multisig address

    constructor() Auth(DAO_MULTISIG, Authority(address(0))) {}

    function deploy(bytes32 salt, bytes memory creationCode) external payable requiresAuth returns (address deployed) {
        return CREATE3.deploy(salt, creationCode, msg.value);
    }

    function getDeployed(bytes32 salt) external view returns (address deployed) {
        return CREATE3.getDeployed(salt);
    }
}

