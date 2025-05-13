const { expect } = require("chai");

describe("FlashArbitrage", function () {
    it("Should deploy FlashArbitrage contract", async function () {
        const [owner] = await ethers.getSigners();
        const FlashArbitrage = await ethers.getContractFactory("FlashArbitrage");
        const flashArb = await FlashArbitrage.deploy("<address_provider>");
        expect(await flashArb.owner()).to.equal(owner.address);
    });
});
