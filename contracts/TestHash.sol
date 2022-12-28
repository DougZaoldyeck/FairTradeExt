pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;


import "./EllipticCurve.sol";

contract TestHash {
    function CalHash(bytes32 _x) external pure returns (bytes32 hashval) {
        hashval = sha256(abi.encodePacked(_x)) ;
        return hashval;
    }

    uint256 public constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 public constant GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
    uint256 public constant AA = 0;
    uint256 public constant BB = 7;
    uint256 public constant PP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
    uint256 public constant NN = 115792089237316195423570985008687907852837564279074904382605163141518161494337;    //order of secp256k1
    uint256 public constant sk = 4;
    uint256 public constant qx = 103388573995635080359749164254216598308788835304023601477803095234286494993683;    //public key pair (x,y)
    uint256 public constant qy = 37057141145242123013015316630864329550140216928701153669873286428255828810018;
    uint256 public constant res_x = 22433566660501949336591728236966687972342496606863864686753372370377308123127;
    //uint256 public constant sk1x = 112711660439710606056748659173929673102114977341539408544630613555209775888121;
    //uint256 public constant sk1y = 25583027980570883691656905877401976406448868254816295069919888960541586679410;

    event ResultLog(uint256 x1, uint256 x2);
    event SigLog(uint256 sig, uint256 r);
    event CalLog(uint256 x);

    function derivePubKey(address payable _sender, uint256 privKey) public payable returns(uint256 qx, uint256 qy) {
    (qx, qy) = EllipticCurve.ecMul(
      privKey,
      GX,
      GY,
      AA,
      PP
    );
    emit ResultLog(qx, qy);
    return(qx, qy);
    }

    function KeyGen(address payable _sender, uint256 sk2) 
    external 
    payable 
    returns (
        uint256 a, 
        uint256 b) 
    {
        uint256 sk2x;
        uint256 sk2y;
        uint256 sk1x = 112711660439710606056748659173929673102114977341539408544630613555209775888121;
        uint256 sk1y = 25583027980570883691656905877401976406448868254816295069919888960541586679410;
        //uint256 sk2 = 3;
        (sk2x, sk2y) = EllipticCurve.ecMul(sk2,GX,GY,AA,PP);
        if (sk1x != sk2x)
            return(0,0);
        if (sk1y != sk2y)
            return(0,0);
        emit ResultLog(sk2x, sk2y);
        return (sk2x, sk2y);
    }

    function SigVerify(address payable _sender, uint256 _r2, string memory _m2, uint256 _s2) 
    public 
    payable 
    returns (uint256 res_x1)
    {
        bytes32 e = keccak256(abi.encodePacked(_m2));
        uint256 z = uint256(e);
        if (z > NN)
            revert("choose another m");
        uint256 w = EllipticCurve.invMod(_s2,NN);
        w = w % NN;
        z = (z * w) % NN;
        w = (_r2 * w) % NN;
        uint256 x1;
        uint256 y1;
        (x1,y1) = EllipticCurve.ecMul(z,GX,GY,AA,PP); 
        (z,w) = EllipticCurve.ecMul(w,qx,qy,AA,PP); 
        (x1,y1) = EllipticCurve.ecAdd(x1,y1,z,w,AA,PP);
        emit CalLog(x1);
        //uint256 s2 = 109247258617027406760302683006541450594023277067167994168140084578855052108858;
        if (x1 != res_x)
            revert("Signature doesn't match");
        return(x1);
    }
    function SigGen(address payable _sender, uint256 _k, string memory _m2)
    public 
    payable 
    returns (
        uint256 _s,
        uint256 _r)
    {
        bytes32 e = keccak256(abi.encodePacked(_m2));
        uint256 z = uint256(e);
        uint256 w = EllipticCurve.invMod(_k,NN);
        uint256 xk;
        uint256 yk;
        uint256 r;
        uint256 s;
        (xk,yk) = EllipticCurve.ecMul(_k,GX,GY,AA,PP); 
        r = xk % NN;
        if (r == 0)
            revert("invalid k, choose again");
        s = r * sk;
        s = s + z;
        s = (s * w) % NN;
        if (s == 0)
            revert("fail to calculate s, change k");
        //uint256 s2 = 109247258617027406760302683006541450594023277067167994168140084578855052108858;
        emit SigLog(s,r);
        return (s,r);
    }
}