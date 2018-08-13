var SupplyChainEP = artifacts.require("SupplyChainEP");
var Strings = artifacts.require("strings");


module.exports = function(deployer) {
    deployer.deploy(Strings);
    deployer.link(Strings, SupplyChainEP);
    deployer.deploy(SupplyChainEP);
};