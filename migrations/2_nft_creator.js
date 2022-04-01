const NFTCreator = artifacts.require("GenNFT");

module.exports = function (deployer) {
  deployer.deploy(
    NFTCreator,
    20,
    1,
    50,
    1648739423,
    1648739423,
    "https://gateway.pinata.cloud/ipfs/QmTNpSVs3MhWKYPUf47UsCK5yc96JwExZkVf3KyuRtQAKz",
    "https://gateway.pinata.cloud/ipfs/QmSVyoTFpi9jepZke4pMtuCm5dWY71fJka5qPJ2qkqwgvW/",
    ".json",
    false,
    true
    );
};
