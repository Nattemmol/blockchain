import { expect } from "chai";
import { ethers } from "hardhat";

describe("FreelanceEscrow", () => {
  let escrow:any, client:any, freelancer:any, arbitrator:any;

  beforeEach(async () => {
    [client, freelancer, arbitrator] = await ethers.getSigners();
    const Escrow = await ethers.getContractFactory("FreelanceEscrow");
    escrow = await Escrow.deploy(arbitrator.address);
  });

  it("should create and accept job", async () => {
    await escrow.connect(client).createJob(
      freelancer.address,
      ["M1"],
      [ethers.parseEther("1")],
      { value: ethers.parseEther("1") }
    );

    await escrow.connect(freelancer).acceptJob(1);
    expect((await escrow.jobs(1)).status).to.equal(1);
  });

  it("should submit and auto-approve milestone", async () => {
    await escrow.connect(client).createJob(
      freelancer.address,
      ["M1"],
      [ethers.parseEther("1")],
      { value: ethers.parseEther("1") }
    );

    await escrow.connect(freelancer).acceptJob(1);
    await escrow.connect(freelancer).submitMilestone(1);

    await ethers.provider.send("evm_increaseTime", [3 * 24 * 60 * 60]);
    await escrow.autoApprove(1);

    expect((await escrow.jobs(1)).status).to.equal(3); // Completed
  });

  it("should resolve dispute", async () => {
    await escrow.connect(client).createJob(
      freelancer.address,
      ["M1"],
      [ethers.parseEther("1")],
      { value: ethers.parseEther("1") }
    );

    await escrow.raiseDispute(1);
    await escrow.connect(arbitrator).resolveDispute(
      1,
      ethers.parseEther("0.4")
    );

    expect((await escrow.jobs(1)).status).to.equal(3);
  });
});
