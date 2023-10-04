// SPDX-License-Identifier: MIT

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

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
contract Delgado {

    event LogHTLCNew(
        bytes32 indexed contractId,
        address indexed sender,
        address indexed receiver,
        uint amount,
        uint256 k0,
        uint timelock
    );
    event LogHTLCWithdraw(bytes32 indexed contractId);
    event LogHTLCRefund(bytes32 indexed contractId);

    struct LockContract {
        address payable sender;
        address payable receiver;
        uint amount;
        uint256 k0; //the randomness k0 used by the seller(receiver) for the first signature sig_prev
        //string m2; //the message m2 negotiated between two parties, which will be signed by the seller(receiver) 
        uint timelock; // UNIX timestamp seconds - locked UNTIL this time
        bool withdrawn;
        bool refunded;
    }
    
    struct WithDrawParam {
        bytes32 _contractId;
        uint256 _r2;
        uint256 _s2;
        uint256 _k;
        string _m2;
    }
    
    //WithDrawParam[] public WDPs;
    
    //Some parameters from Elliptic Curve (secp256k1)
    uint256 public constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 public constant GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
    uint256 public constant AA = 0;
    uint256 public constant PP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
    uint256 public constant NN = 115792089237316195423570985008687907852837564279074904382605163141518161494337;    //order of secp256k1
    uint256 public constant qx = 103388573995635080359749164254216598308788835304023601477803095234286494993683;    //public key pair (x,y)
    uint256 public constant qy = 37057141145242123013015316630864329550140216928701153669873286428255828810018;
    uint256 public constant res_x = 22433566660501949336591728236966687972342496606863864686753372370377308123127;  //hardcoded for test purposes only
    //uint256 public constant r2 = 21505829891763648114329055987619236494102133314575206970830385799158076338148;
    //uint256 public constant s2 = 62560875960789245167310124323518749634184838256435621860459318052048061205369;

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
    /***
    modifier s2lockMatches(bytes32 _contractId, uint256 _r2, uint256 _s2, string memory _m2) {
        //signature s2 verification
        bytes32 e = keccak256(abi.encodePacked(_m2));
        uint256 z = uint256(e);
        uint256 w = EllipticCurve.invMod(_s2,NN);
        w = w % NN;
        z = (z * w) % NN;
        w = (_r2 * w) % NN;
        uint256 x1;
        uint256 y1;
        (x1,y1) = EllipticCurve.ecMul(z,GX,GY,AA,PP); 
        (z,w) = EllipticCurve.ecMul(w,qx,qy,AA,PP); 
        (x1,y1) = EllipticCurve.ecAdd(x1,y1,z,w,AA,PP);
        require(contracts[_contractId].k0 == _r2, "randomness does not match");
        require(contracts[_contractId].r1 == x1, "signature does not match");
        _;
    }
    ***/
    
    modifier s2lockMatches(WithDrawParam memory insert) {
        //signature s2 verification
        bytes32 e = keccak256(abi.encodePacked(insert._m2));
        uint256 z = uint256(e);
        uint256 w = EllipticCurve.invMod(insert._s2,NN);
        w = w % NN;
        z = (z * w) % NN;
        w = (insert._r2 * w) % NN;
        uint256 x1;
        uint256 y1;
        (x1,y1) = EllipticCurve.ecMul(z,GX,GY,AA,PP); 
        (z,w) = EllipticCurve.ecMul(w,qx,qy,AA,PP); 
        (x1,y1) = EllipticCurve.ecAdd(x1,y1,z,w,AA,PP);
        require(contracts[insert._contractId].k0 == insert._k, "randomness does not match");
        require(res_x == x1, "signature does not match");
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
     * @param _k0 The randomness used for sig_prev. 
     * @param _timelock UNIX epoch seconds time that the lock expires at.
     *                  Refunds can be made after this time.
     * @return contractId Id of the new HTLC. This is needed for subsequent
     *                    calls.
     */
    function newContract(address payable _receiver, uint256 _k0, uint _timelock)
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
                msg.value,
                _k0,
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
            msg.value,
            _k0,
            _timelock,
            false,
            false
        );

        emit LogHTLCNew(
            contractId,
            msg.sender,
            _receiver,
            msg.value,
            _k0,
            _timelock
        );
    }




    /**
     * @dev Called by the receiver once they know sk2.
     * This will transfer the locked funds to their address.
     *
     * param _contractId Id of the HTLC.
     * param _r2 randomness for signing m2.
     * param _s2 signature of m2.
     * @return bool true on success
     */
    function withdraw(WithDrawParam memory insert)
        public
        contractExists(insert._contractId)
        s2lockMatches(insert)
        withdrawable(insert._contractId)
        returns (bool)
    {
        LockContract storage c = contracts[insert._contractId];
        //c.sk2 = _preimage;
        c.withdrawn = true;
        c.receiver.transfer(c.amount);
        emit LogHTLCWithdraw(insert._contractId);
        return true;
    }
    
    /**
     * this is called as a pre-resolve function for inserting a struct
     * bytes32 _contractId;
        uint256 _r2;
        uint256 _s2;
        string _m2;
     * 
     */
      function getStruct(bytes32 s, uint256 a, uint256 b, uint256 c, string memory d) public returns(bool){
      WithDrawParam memory input;
      input._contractId = s;
      input._r2 = a;
      input._s2 = b;
      input._k = c;
      input._m2 = d;
      if (withdraw(input) == true)
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
        uint amount,
        uint256 k0,
        uint timelock,
        bool withdrawn,
        bool refunded)
    {
        if (haveContract(_contractId) == false)
            return (address(0), address(0), 0, 0, 0, false, false);
        LockContract storage c = contracts[_contractId];
        return (
            c.sender,
            c.receiver,
            c.amount,
            c.k0,
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

}