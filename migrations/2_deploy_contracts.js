const HashedTimelock = artifacts.require('HashedTimelock')
//const fairtrade = artifacts.require('fairtrade')
const EllipticCurve = artifacts.require('EllipticCurve')
const TestHash = artifacts.require('TestHash')

module.exports = function (deployer) {
    deployer.deploy(HashedTimelock)
    //deployer.deploy(fairtrade)
    deployer.deploy(EllipticCurve)
    deployer.deploy(TestHash)
}