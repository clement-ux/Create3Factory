// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/// Adapted from https://github.com/pcaversaccio/createx
library Create2 {
    event ContractCreation(address indexed newContract, bytes32 indexed salt);

    error FailedContractCreation();

    function deploy(bytes32 salt, bytes memory initCode) public returns (address newContract) {
        assembly ("memory-safe") {
            newContract := create2(callvalue(), add(initCode, 0x20), mload(initCode), salt)
        }

        if (newContract == address(0) || newContract.code.length == 0) {
            revert FailedContractCreation();
        }

        emit ContractCreation({newContract: newContract, salt: salt});
    }
}
