// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.20;

import { AddressResolver } from "../../common/AddressResolver.sol";
import { BlockHeader, LibBlockHeader } from "../../libs/LibBlockHeader.sol";
import { ICrossChainSync } from "../../common/ICrossChainSync.sol";
import { LibBridgeData } from "./LibBridgeData.sol";
import { LibTrieProof } from "../../libs/LibTrieProof.sol";

/// @title LibBridgeStatus
/// @notice This library provides functions for getting and updating the status
/// of bridge messages.
/// The library handles various aspects of message statuses, including their
/// retrieval, update, and verification of failure status on the destination
/// chain.
library LibBridgeStatus {
    using LibBlockHeader for BlockHeader;

    event MessageStatusChanged(
        bytes32 indexed msgHash, LibBridgeData.Status status
    );

    error B_MSG_HASH_NULL();
    error B_WRONG_CHAIN_ID();

    /// @notice Updates the status of a bridge message.
    /// @dev If the new status is different from the current status in the
    /// mapping, the status is updated and an event is emitted.
    /// @param msgHash The hash of the message.
    /// @param status The new status of the message.
    function updateMessageStatus(
        LibBridgeData.State storage state,
        bytes32 msgHash,
        LibBridgeData.Status status
    )
        internal
    {
        if (state.messageStatus[msgHash] != status) {
            state.messageStatus[msgHash] = status;
            if (status == LibBridgeData.Status.FAILED) {
                // TODO: write a signal
            }
            emit MessageStatusChanged(msgHash, status);
        }
    }

    /// @notice Checks whether a bridge message has failed on its destination
    /// chain.
    /// @param resolver The address resolver.
    /// @param msgHash The hash of the message.
    /// @param destChainId The ID of the destination chain.
    /// @param proofs The proofs of the status of the message.
    /// @return True if the message has failed, false otherwise.
    function isMessageFailed(
        AddressResolver resolver,
        bytes32 msgHash,
        uint256 destChainId,
        bytes[] calldata proofs
    )
        internal
        view
        returns (bool)
    {
        if (proofs.length == 0) return false;
        if (msgHash == 0x0) revert B_MSG_HASH_NULL();
        if (destChainId == block.chainid) revert B_WRONG_CHAIN_ID();

        // TODO
        LibBridgeData.StatusProof memory sp =
            abi.decode(proofs[0], (LibBridgeData.StatusProof));

        bytes32 syncedHeaderHash = ICrossChainSync(
            resolver.resolve("taiko", false)
        ).getCrossChainBlockHash(uint64(sp.header.height));

        if (syncedHeaderHash == 0) return false;
        if (syncedHeaderHash != sp.header.hashBlockHeader()) return false;

        // TODO:
        // return LibTrieProof.verifyWithFullMerkleProof({
        //     stateRoot: sp.header.stateRoot,
        //     addr: resolver.resolve(destChainId, "bridge", false),
        //     slot: getMessageStatusSlot(msgHash),
        //     value: bytes32(uint256(LibBridgeData.Status.FAILED)),
        //     mkproof: sp.proof
        // });
    }
}
