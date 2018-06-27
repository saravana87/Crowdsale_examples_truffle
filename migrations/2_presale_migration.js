var Safemath = artifacts.require("./SafeMathLib.sol");
var Migrations = artifacts.require("./PresaleFundCollector.sol");


module.exports = function(deployer) {
  deployer.deploy(Safemath);  
  deployer.link(Safemath,Migrations);
  deployer.deploy(Migrations,'0xbbb58c6a3fa239ddc413696e89eea7490888e85d',1530403200,1);

  
};
