const {expect} = require("chai");
const {ethers} = require("hardhat");

describe("HaldiramFood", async ()=>{
    let haldiramFood;
    let owner;
    let customer;

    beforeEach( async ()=>{
      [owner,customer] = await ethers.getSigners();

      haldiramFood = await ethers.deployContract("HaldiramFood",[]);
        console.log(await haldiramFood.getAddress());
    });
     
    it("should set the right owner", async ()=>{
       expect(await haldiramFood.owner()).to.equal(owner.address);
    });

    describe("addFood", async ()=>{
      it("allow owner to add food item", async ()=>{
       await haldiramFood.connect(owner).addFood(1,"biryani",10,ethers.parseEther("1"),Math.floor(Date.now() / 1000) + 3600);
       const food = await haldiramFood.foods(1);
       expect(food.name).to.equal("biryani");
       expect(food.quantity).to.equal(10);
       expect(food.price).to.equal(ethers.parseEther("1"));
       expect(food.isAdded).to.be.true;
    });
  });

  describe("buyFood", async ()=> {
    it("allow customer to buy food", async ()=> {
       await haldiramFood.connect(owner).addFood(1,"biryani",10,ethers.parseEther("0.1"),Math.floor(Date.now() / 1000) + 3600);
       const Price =  ethers.parseEther("0.1");
       await haldiramFood.connect(customer).buyFood(1,1, {value: Price});
       const food = await haldiramFood.foods(1);

      expect(food.quantity).to.equal(9);
    });
  });

  describe("updatePrice", async ()=> {
     it("should allow the owner to update price", async ()=> {
        const expirationDate = Math.floor(Date.now() / 1000) + 3600;
        await haldiramFood.connect(owner).addFood(1, "biryani", 10, ethers.parseEther("0.1"), expirationDate);
        await haldiramFood.connect(owner).updatePrice(1,ethers.parseEther("0.2"));
        const food = await haldiramFood.foods(1);

        expect(food.price).to.equal(ethers.parseEther("0.2"));
     });
  });

  describe("restockFood", async ()=> {
    it("should allow owner to restock the food", async ()=> {
       const expirationDate = Math.floor(Date.now() / 1000) + 3600;
        await haldiramFood.connect(owner).addFood(1,"biryani", 10, ethers.parseEther("0.1"), expirationDate);
        await haldiramFood.connect(owner).restockFood(1,5);
        const food = await haldiramFood.foods(1);

        expect(food.quantity).to.equal(15);
    });

   describe("Transfer Ownership", async ()=> {
    it("should transfer ownership", async function () {
      await haldiramFood.transferOwnership(customer.address);
      expect(await haldiramFood.owner()).to.equal(customer.address);
        });
     });

  });
    
});