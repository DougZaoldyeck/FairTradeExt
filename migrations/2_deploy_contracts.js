const HashedTimelock = artifacts.require('HashedTimelock')
const FT = artifacts.require('FT')
const EllipticCurve = artifacts.require('EllipticCurve')
const TestHash = artifacts.require('TestHash')
const ExistingWork = artifacts.require('ExistingWork')
const FairTradeExtBsl = artifacts.require('FairTradeExtBsl')
const NiFT = artifacts.require('NiFT')
const Delgado = artifacts.require('Delgado')
const Commitment = artifacts.require('Commitment')
const FairTradeExtImproved = artifacts.require('FairTradeExtImproved')



module.exports = function (deployer) {
    deployer.deploy(HashedTimelock)
    deployer.deploy(FT)
    deployer.deploy(EllipticCurve)
    deployer.deploy(TestHash)
    deployer.deploy(ExistingWork)
    deployer.deploy(FairTradeExtBsl)
    deployer.deploy(NiFT)
    deployer.deploy(Delgado)
    deployer.deploy(Commitment)
    deployer.deploy(FairTradeExtImproved)
}