// SPDX-License-Identifier: MIT

pragma solidity ^0.5.0;

import "./EllipticCurve.sol";

/**
 * @title Hashed Timelock Contracts (HTLCs) on Ethereum ETH.
 *
 * This contract provides a way to create and keep HTLCs for ETH.
 *
 * See HashedTimelockERC20.sol for a contract that provides the same functions
 * for ERC20 tokens.
 *
 * Protocol:
 *
 *  1) newContract(receiver, sk1, sk1y, timelock) - a sender calls this to create
 *      a new HTLC and gets back a 32 byte contract id
 *  2) withdraw(contractId, sk2) - once the receiver knows sk2 
 *      they can claim the ETH with this function
 *  3) refund() - after timelock has expired and if the receiver did not
 *      withdraw funds the sender / creator of the HTLC can get their ETH
 *      back with this function.
 */

 //This is testof ours.
contract JustAnotherTest {

    event LogHTLCNew(
        bytes32 indexed contractId,
        address indexed sender,
        address indexed receiver,
        bytes32 datahash,
        uint amount,
        uint256 sk1x,
        uint256 sk1y,
        uint timelock
    );
    event LogHTLCWithdraw(bytes32 indexed contractId);
    event LogHTLCRefund(bytes32 indexed contractId);
    event Results(bytes32 indexed currentRoot, uint256 indexed calTotal);

    struct LockContract {
        address payable sender;
        address payable receiver;
        bytes32 datahash;
        uint amount;
        uint256 sk1x;
        uint256 sk1y; //the pre-set results calculated by the buyer(sender) for future checking
        uint timelock; // UNIX timestamp seconds - locked UNTIL this time
        bool withdrawn;
        bool refunded;
    }


    uint256 public constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 public constant GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
    uint256 public constant AA = 0;
    uint256 public constant PP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
    bytes32 public storedHash; //keep the current hash chain value
    //uint256 public constant sk1x = 112711660439710606056748659173929673102114977341539408544630613555209775888121;
    //uint256 public constant sk1y = 25583027980570883691656905877401976406448868254816295069919888960541586679410;

    modifier fundsSent() {
        require(msg.value > 0, "msg.value must be > 0");
        _;
    }
    modifier futureTimelock(uint _time) {
        // only requirement is the timelock time is after the last blocktime (now).
        // probably want something a bit further in the future then this.
        // but this is still a useful sanity check:
        require(_time > now, "timelock time must be in the future");
        _;
    }
    modifier contractExists(bytes32 _contractId) {
        require(haveContract(_contractId), "contractId does not exist");
        _;
    }
    modifier sklockMatches(bytes32 _contractId, uint256 sk2) {
        uint256 sk2x;
        uint256 sk2y;
        (sk2x, sk2y) = EllipticCurve.ecMul(sk2,GX,GY,AA,PP);                  //sk2*G(X,Y) 
        require(contracts[_contractId].sk1x == sk2x, "sk2 does not match");
        require(contracts[_contractId].sk1y == sk2y, "sk2 does not match");
        _;
    }
    modifier withdrawable(bytes32 _contractId) {
        require(contracts[_contractId].receiver == msg.sender, "withdrawable: not receiver");
        require(contracts[_contractId].withdrawn == false, "withdrawable: already withdrawn");
        require(contracts[_contractId].timelock > now, "withdrawable: timelock time must be in the future");
        _;
    }
    modifier refundable(bytes32 _contractId) {
        require(contracts[_contractId].sender == msg.sender, "refundable: not sender");
        require(contracts[_contractId].refunded == false, "refundable: already refunded");
        require(contracts[_contractId].withdrawn == false, "refundable: already withdrawn");
        require(contracts[_contractId].timelock <= now, "refundable: timelock not yet passed");
        _;
    }

    mapping (bytes32 => LockContract) contracts;

    /**
     * @dev Sender sets up a new hash time lock contract depositing the ETH and
     * providing the reciever lock terms.
     *
     * @param _receiver Receiver of the ETH.
     * @param _sk1x, _sk1y The calculated results based on sk1 which was given during the negotiation phase.
     * @param _timelock UNIX epoch seconds time that the lock expires at.
     *                  Refunds can be made after this time.
     * @return contractId Id of the new HTLC. This is needed for subsequent
     *                    calls.
     */
    function newContract(address payable _receiver, bytes32 _datahash, uint256 _sk1x, uint256 _sk1y, uint _timelock)
        external
        payable
        fundsSent
        futureTimelock(_timelock)
        returns (bytes32 contractId)
    {
        contractId = keccak256(
            abi.encodePacked(
                msg.sender,
                _receiver,
                _datahash,
                msg.value,
                _sk1x,
                _sk1y,
                _timelock
            )
        );

        // Reject if a contract already exists with the same parameters. The
        // sender must change one of these parameters to create a new distinct
        // contract.
        if (haveContract(contractId))
            revert("Contract already exists");

        contracts[contractId] = LockContract(
            msg.sender,
            _receiver,
            _datahash,
            msg.value,
            _sk1x,
            _sk1y,
            _timelock,
            false,
            false
        );

        emit LogHTLCNew(
            contractId,
            msg.sender,
            _receiver,
            _datahash,
            msg.value,
            _sk1x,
            _sk1y,
            _timelock
        );
    }

    function hashChain(bytes32 newHash) public {
        if(storedHash == 0) {
            storedHash = newHash;
        } else {
            storedHash = keccak256(abi.encodePacked(storedHash, newHash));  
        }
    }

    /**
     * @dev Called by the receiver once they know sk2.
     * This will transfer the locked funds to their address.
     *
     * @param _contractId Id of the HTLC.
     * @param _sk2 G(X,Y)**_sk2 should equal to (sk1x,sk1y).
     * @return bool true on success
     */
    function withdraw(bytes32 _contractId, uint256 _sk2)
        external
        contractExists(_contractId)
        sklockMatches(_contractId, _sk2)
        withdrawable(_contractId)
        returns (bool)
    {
        LockContract storage c = contracts[_contractId];
        //c.sk2 = _preimage;
        c.withdrawn = true;
        c.receiver.transfer(c.amount);
        hashChain(c.datahash);
        emit LogHTLCWithdraw(_contractId);
        return true;
    }

    /**
     * @dev Called by the sender if there was no withdraw AND the time lock has
     * expired. This will refund the contract amount.
     *
     * @param _contractId Id of HTLC to refund from.
     * @return bool true on success
     */
    function refund(bytes32 _contractId)
        external
        contractExists(_contractId)
        refundable(_contractId)
        returns (bool)
    {
        LockContract storage c = contracts[_contractId];
        c.refunded = true;
        c.sender.transfer(c.amount);
        emit LogHTLCRefund(_contractId);
        return true;
    }

    /**
     * @dev Get contract details.
     * @param _contractId HTLC contract id
     * return All parameters in struct LockContract for _contractId HTLC
     */
    function getContract(bytes32 _contractId) 
    public 
    view 
    returns (
        address sender,
        address receiver,
        bytes32 datahash,
        uint amount,
        uint256 sk1x,
        uint256 sk1y,
        uint timelock,
        bool withdrawn,
        bool refunded)
    {
        if (haveContract(_contractId) == false)
            return (address(0), address(0), bytes32(0), 0, 0, 0, 0, false, false);
        LockContract storage c = contracts[_contractId];
        return (
            c.sender,
            c.receiver,
            c.datahash,
            c.amount,
            c.sk1x,
            c.sk1y,
            c.timelock,
            c.withdrawn,
            c.refunded
        );
    }

    /**
     * @dev Is there a contract with id _contractId.
     * @param _contractId Id into contracts mapping.
     */
    function haveContract(bytes32 _contractId)
        internal
        view
        returns (bool exists)
    {
        exists = (contracts[_contractId].sender != address(0));
    }

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
                data_list[j] = data_list[treeSize-1];
                treeSize = treeSize / 2 + 1;
            } else {
                treeSize = treeSize / 2;
            }
        }

        emit Results(data_list[0], total);

        }

}