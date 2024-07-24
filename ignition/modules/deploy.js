const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");



module.exports = buildModule("Module", (m) => {

  const contract = m.contract("HaldiramFood", [], {

  });

  return { contract };
});
