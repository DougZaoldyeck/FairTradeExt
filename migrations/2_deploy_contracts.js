const HashedTimelock = artifacts.require('HashedTimelock')
const FT = artifacts.require('FT')
const EllipticCurve = artifacts.require('EllipticCurve')
const TestHash = artifacts.require('TestHash')
const FairTradeExtBsl = artifacts.require('FairTradeExtBsl')
const Delgado = artifacts.require('Delgado')
const Commitment = artifacts.require('Commitment')
const FairTradeExtImproved = artifacts.require('FairTradeExtImproved')



module.exports = function (deployer) {
    deployer.deploy(HashedTimelock)
    deployer.deploy(FT)
    deployer.deploy(EllipticCurve)
    deployer.deploy(TestHash)
    deployer.deploy(FairTradeExtBsl)
    deployer.deploy(Delgado)
    deployer.deploy(Commitment)
    deployer.deploy(FairTradeExtImproved)
}