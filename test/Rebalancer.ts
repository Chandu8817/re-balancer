import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre, { ethers } from "hardhat";
import V3Abi from "../mockAbis/v3postion.json";
import ERC20Abi from "../mockAbis/erc20.json";
const tokenA = "0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38";
const tokenB = "0x29219dd400f2Bf60E5a23d13Be72B486D4038894";

describe("Rebalancer", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOneYearLockFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await hre.ethers.getSigners();
    // const impersonate = await hre.ethers.getImpersonatedSigner(
    //   "0x7d04A956bf0c3dfA1F8B1342382AB7a04e252668"
    // );

    // const tokenAContract = new hre.ethers.Contract(
    //   tokenA,
    //   ERC20Abi,
    //   impersonate
    // );
    // const tokenBContract = new hre.ethers.Contract(
    //   tokenB,
    //   ERC20Abi,
    //   impersonate
    // );
 

    const router = "0x5543c6176FEb9B4b179078205d7C29EEa2e2d695";
    const positionManager = "0x12E66C8F215DdD5d48d150c8f46aD0c6fB0F4406";
    const maxFee = ethers.parseEther("0.5");

    const Rebalancer = await hre.ethers.getContractFactory("Rebalancer");
    const rebalancer =  Rebalancer.attach("0x1b0021E803660F38F8deF7E86578dCAd474bc1FA") // await Rebalancer.deploy(router, maxFee);
    const v3PostionManager = new hre.ethers.Contract(
      positionManager,
      V3Abi.abi,
      owner
    );

    return {
      rebalancer,
      owner,
      otherAccount,
      positionManager,
      router,
      v3PostionManager,
      // impersonate,
      // tokenAContract,
      // tokenBContract,
    };
  }

  // describe("Deployment", function () {
  //   it("Should confirm the deployment", async function () {
  //     const { rebalancer, router, positionManager, v3PostionManager } =
  //       await loadFixture(deployOneYearLockFixture);
  //     console.log(await v3PostionManager.WETH9());

  //     expect(await rebalancer.routers(router)).to.equal(true);

  //   });
  // });

  describe("Rebalance", function () {
    it("Should rebalance the position", async function () {
      const {
        rebalancer,
        owner,
        otherAccount,
        router,
        positionManager,
        v3PostionManager,
        // tokenAContract,
        // tokenBContract,
        // impersonate,
      } = await loadFixture(deployOneYearLockFixture);
      const tokenID = 604297;
      const tickSpacing = 50;
      const tickLower = -284950;
      const tickUpper = -284900;
      const sqrtPriceX96 = 0;
 
    //     await tokenAContract.transfer(
    //   owner.address,
    //   ethers.parseUnits("10",18)
    // );
    // await tokenBContract.transfer(
    //   owner.address,
    //   ethers.parseUnits("10",6)
    // );

    // console.log(await tokenAContract.balanceOf(owner.address));
    // console.log(await tokenBContract.balanceOf(owner.address));
      // // mint new position
      // const mintTx = await v3PostionManager.mint({
      //   token0: tokenA,
      //   token1: tokenB,
      //   tickSpacing: 50,
      //   tickLower: tickLower,
      //   tickUpper: tickUpper,
      //   amount0Desired:  ethers.parseUnits("10",18),
      //   amount1Desired:  ethers.parseUnits("10",6),
      //   amount0Min: 0,
      //   amount1Min: 0,
      //   recipient: owner.address,
      //   deadline: (await time.latest()) + 1000,

      // });
      // const mintReceipt = await mintTx.wait();
      // console.log(mintReceipt)

      //@ts-ignore
      await rebalancer.rebalancerV3(
        router,
        tokenA,
        tokenB,
        tokenID,
        tickSpacing,
        tickLower,
        tickUpper,
        sqrtPriceX96,
        positionManager
      );
    });
  });
});
