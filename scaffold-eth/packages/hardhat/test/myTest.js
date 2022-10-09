const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("My Dapp", function () {
  let myContract;

  // quick fix to let gas reporter fetch data from gas station & coinmarketcap
  before((done) => {
    setTimeout(done, 2000);
  });

  describe("TwoPartyContract", function () {
    it("Should deploy TwoPartyContract", async function () {
      const TwoPartyContract = await ethers.getContractFactory("TwoPartyContract");

      myContract = await TwoPartyContract.deploy();
    });

    describe("setPurpose()", function () {
      it("Should be able to set a new purpose", async function () {
        const newPurpose = "Test Purpose";

        await myContract.setPurpose(newPurpose);
        expect(await myContract.purpose()).to.equal(newPurpose);
      });

      it("Should emit a SetPurpose event ", async function () {
        const [owner] = await ethers.getSigners();

        const newPurpose = "Another Test Purpose";

        expect(await myContract.setPurpose(newPurpose))
          .to.emit(myContract, "SetPurpose")
          .withArgs(owner.address, newPurpose);
      });
    });
  });
});
