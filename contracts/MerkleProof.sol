// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

contract MerkleProof {

    event SaveMerkleRoot(bytes32 indexed MerkleRoot);

    function hash(
        bytes32[] memory leaves,
        uint treeSize
    ) public pure returns (bytes32) {
        while (treeSize > 1) {
            uint j = 0;
            for (uint i = 0; i < treeSize; i += 2) {
                leaves[j] = keccak256(abi.encodePacked(leaves[i],leaves[i+1]));
                j += 1;
            }
            treeSize = treeSize / 2;
        }
        //bytes32 val1 = 0xeccf192987704a2cfe51a587aa20b3c88396e498847504b4903c49767914b8d9;
        //bytes32 val2 = 0xbc49c6c0d844e7c2d3b7cf2e807335db306f0338517a1e83cb119184ea7e32a1
        //root shoulb be = 0x2b852d7a9a24064ab0f30ba58899be43f02a25ea55924d5e5b519067f09dd8a2;

        return leaves[0];
    }

    function verify (
        bytes32[] calldata leaves,
        uint treeSize,
        bytes32 root
    ) external payable returns (bool) {
        bytes32[512] memory leaf; //need to change this to half of the treeSize each time... very stupid implementation
        while (treeSize > 1) {
            uint j = 0;
            for (uint i = 0; i < treeSize; i += 2) {
                leaf[j] = keccak256(abi.encodePacked(leaves[i],leaves[i+1]));
                j += 1;
            }
            treeSize = treeSize / 2;
        }

        if (leaf[0] == root) {
            emit SaveMerkleRoot(root);
            return true;
        }
        return false;
    }
}