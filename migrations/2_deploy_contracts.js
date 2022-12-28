const HashedTimelock = artifacts.require('HashedTimelock')
//const fairtrade = artifacts.require('fairtrade')
const EllipticCurve = artifacts.require('EllipticCurve')
const TestHash = artifacts.require('TestHash')
const ExistingWork = artifacts.require('ExistingWork')
const FairTradeExt = artifacts.require('FairTradeExt')

module.exports = function (deployer) {
    deployer.deploy(HashedTimelock)
    //deployer.deploy(fairtrade)
    deployer.deploy(EllipticCurve)
    deployer.deploy(TestHash)
    deployer.deploy(ExistingWork)
    deployer.deploy(FairTradeExt)
}