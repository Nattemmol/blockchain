import { expect } from "chai";
import { ethers } from "hardhat";

describe("AutoChainRegistry", function () {
  let contract: any;
  let admin: any;
  let owner1: any;
  let owner2: any;

  beforeEach(async () => {
    [admin, owner1, owner2] = await ethers.getSigners();

    const AutoChain = await ethers.getContractFactory("AutoChainRegistry");
    contract = await AutoChain.deploy();
    await contract.waitForDeployment();
  });

  describe("Vehicle Registration", () => {
    it("Admin can register a vehicle", async () => {
      await contract.registerVehicle(
        "VIN123",
        "ipfs://vehicle-metadata",
        owner1.address
      );

      const vehicle = await contract.getVehicle(1);
      expect(vehicle.vin).to.equal("VIN123");
      expect(vehicle.currentOwner).to.equal(owner1.address);
    });

    it("Non-admin cannot register vehicle", async () => {
      await expect(
        contract
          .connect(owner1)
          .registerVehicle("VIN999", "uri", owner1.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Duplicate VIN should fail", async () => {
      await contract.registerVehicle("VIN123", "uri", owner1.address);

      await expect(
        contract.registerVehicle("VIN123", "uri2", owner2.address)
      ).to.be.revertedWith("Vehicle already registered");
    });
  });

  describe("Ownership Transfer", () => {
    beforeEach(async () => {
      await contract.registerVehicle(
        "VIN456",
        "ipfs://meta",
        owner1.address
      );
    });

    it("Owner can transfer ownership", async () => {
      await contract
        .connect(owner1)
        .transferVehicle(1, owner2.address);

      const vehicle = await contract.getVehicle(1);
      expect(vehicle.currentOwner).to.equal(owner2.address);
    });

    it("Non-owner cannot transfer", async () => {
      await expect(
        contract.connect(owner2).transferVehicle(1, owner2.address)
      ).to.be.revertedWith("Not vehicle owner");
    });

    it("Direct ERC721 transfer should fail", async () => {
      await expect(
        contract
          .connect(owner1)
          ["safeTransferFrom(address,address,uint256)"](
            owner1.address,
            owner2.address,
            1
          )
      ).to.be.revertedWith("Direct transfer disabled");
    });
  });

  describe("Ownership History", () => {
    it("Tracks ownership changes correctly", async () => {
      await contract.registerVehicle("VIN789", "uri", owner1.address);
      await contract
        .connect(owner1)
        .transferVehicle(1, owner2.address);

      const history = await contract.getOwnershipHistory(1);
      expect(history.length).to.equal(2);
      expect(history[0].owner).to.equal(owner1.address);
      expect(history[1].owner).to.equal(owner2.address);
    });
  });

  describe("Vehicle Status", () => {
    beforeEach(async () => {
      await contract.registerVehicle("VIN000", "uri", owner1.address);
    });

    it("Admin can update vehicle status", async () => {
      await contract.updateVehicleStatus(1, 1); // Stolen

      const vehicle = await contract.getVehicle(1);
      expect(vehicle.status).to.equal(1);
    });

    it("Non-admin cannot update status", async () => {
      await expect(
        contract.connect(owner1).updateVehicleStatus(1, 2)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });
});
