var Safemath = artifacts.require("./SafeMathLib.sol");
var Migrate_token = artifacts.require("./BurnableCrowdsaleToken.sol");


module.exports = function(deployer) {
  
  var name = "Token Name";
  var symbol = "2HOARD"
  var initial_supply = 3000000000;
  var decimals = 18;
  var mintable = true;
  deployer.deploy(Safemath);  
  deployer.link(Safemath,Migrate_token);
  deployer.deploy(Migrate_token,name, symbol, initial_supply, decimals, mintable);

  
};
