// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

contract Commitment {

    event Results(bytes32 indexed currentRoot, uint256 indexed calTotal);
    // event Res(uint256 indexed tempTotal);

    mapping(uint256 => uint256) public hashCounts;

    function validateCommitment(bytes32[] memory data_list, uint256[] memory sale_num, uint256[] memory sale_list) public {
        require(data_list.length > 0, "Data list must not be empty");
        require(sale_num.length > 0, "Sale number must not be empty");
        require(sale_list.length > 0, "Sale list must not be empty");

        uint256 epochSize = sale_list.length;    //Total number of sale
        uint256 total = 0;
        
        for (uint256 i = 0; i < sale_num.length; i++) {
            total += sale_num[i];
        }
        // emit Res(total);
        require(total == epochSize, "Total transaction number must match");
        
        bytes32 currentHash = bytes32(0);

        // Iterate through the sale list and calculate the hash chain
        for (uint256 i = 0; i < epochSize; i++) {
            currentHash = keccak256(abi.encodePacked(currentHash, data_list[sale_list[i]]));
            // hashCounts[sale_list[i]] += 1;
            sale_num[sale_list[i]] -= 1;
        }

        for (uint256 i = 0; i < sale_num.length; i++) {
            require(sale_num[i] == 0, "Sale number must match");
        }

        // Iterate through the array of hash values and calculate the hash chain
        uint256 treeSize = data_list.length;
        while (treeSize > 1) {
            uint256 j = 0;
            for (uint256 i = 0; i < treeSize - 2; i += 2) {
                data_list[j] = keccak256(abi.encodePacked(data_list[i],data_list[i+1]));
                j += 1;
            }
            if (treeSize % 2 == 1) {
                data_list[j] = keccak256(abi.encodePacked(data_list[treeSize-1],data_list[treeSize-1]));
                treeSize = treeSize / 2 + 1;
            } else {
                data_list[j] = keccak256(abi.encodePacked(data_list[treeSize-1],data_list[treeSize-2]));
                treeSize = treeSize / 2;
            }
        }

        emit Results(data_list[0], total);

        }
}