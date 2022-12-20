pragma solidity ^0.5.0;

contract TestHash {
    function func(bytes32 _x) external pure returns (bytes32 hashval) {
        hashval = sha256(abi.encodePacked(_x)) ;
        return hashval;
    }
}