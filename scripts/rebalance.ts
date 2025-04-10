import { ethers } from "hardhat";
import hre from "hardhat";
import rebalancerAbi from "../artifacts/contracts/Rebalancer.sol/Rebalancer.json";
import v3PositionAbi from "../mockAbis/v3postion.json";
async function main() {
  const provider = new ethers.JsonRpcProvider("https://rpc.soniclabs.com/");
  const wallet = new ethers.Wallet(process.env.PRIVATE_KEY!, provider);
  const owner = wallet.connect(provider);
  const rebalancer = new ethers.Contract(
    "0x01a35C4d4054410533f95C08EEE87983D5bd2E86",
    rebalancerAbi.abi,
    owner
  );

  const tokenID = 606313;
  const tickSpacing = 50;
  const tickLower = -284950;
  const tickUpper = -284900;
  const sqrtPriceX96 = 0;
  const tokenA = "0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38";
  const tokenB = "0x29219dd400f2Bf60E5a23d13Be72B486D4038894";
  const router = "0x5543c6176FEb9B4b179078205d7C29EEa2e2d695";
  const positionManager = "0x12E66C8F215DdD5d48d150c8f46aD0c6fB0F4406";
  const v3PostionManager = new ethers.Contract(
    positionManager,
    v3PositionAbi.abi,
    owner
  );
  //   await rebalancer.tranferPositionOwnership(
  //     positionManager,tokenID,owner.address
  //   )

  // await rebalancer.withdrawTokens(
  //     tokenA,ethers.parseUnits("0.094761710649576298",18),owner.address
  //   )

  //   setTimeout(() => {
  //     console.log("Waiting for 10 seconds...");
  //   }, 10000);

  //   await rebalancer.withdrawTokens(
  //     tokenB,ethers.parseUnits("0.137118",6),owner.address
  //   )

  //  const tx1 =  await v3PostionManager.safeTransferFrom(
  //     owner.address,
  //     "0x01a35C4d4054410533f95C08EEE87983D5bd2E86",
  //     tokenID,

  //   );
  //   tx1.wait();
  //   console.log("Transaction hash:", tx1.hash);
  // setTimeout(() => {
  //   console.log("Waiting for 10 seconds...");
  // }, 10000);
  const tx = await rebalancer.rebalancerV3(
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
  console.log("Transaction hash:", tx.hash);
  setTimeout(() => {
    console.log("Waiting for 10 seconds...");
  }, 10000);
  await rebalancer.tranferPositionOwnership(
    positionManager,
    tokenID,
    owner.address
  );

  // const binStep = 1;
  // const amountXMin = 0;
  // const amountYMin = 0;
  // const ids = [0];
  // const amounts = [ethers.parseUnits("0.094761710649576298", 18)];
  // const v2Router = "";

  // const path = {
  //   pairBinSteps: [binStep],
  //   versions: [0],
  //   tokenPaths: [tokenA, tokenB],
  // };
  // const amountX = ethers.parseUnits("0.094761710649576298", 18);
  // const amountY = ethers.parseUnits("0.137118", 6);
  // const liquidityParameters = {
  //   tokenX: tokenA,
  //   tokenY: tokenB,
  //   amountX: amountX,
  //   amountY: amountY,
  //   amountXMin: amountXMin,
  //   amountYMin: amountYMin,
  //   activeIdDesired: 1,
  //   idSlippage: 0,
  //   deltaIds: [0],
  //   distributionX: [0],
  //   distributionY: [0],
  //   to: owner.address,
  //   refundTo: owner.address,
  //   deadline: ethers.toBigInt(Number(Date.now()) + 1000),
  // };

  // //// test v2
  // const tx = await rebalancer.rebalancerV2(
  //   tokenA,
  //   tokenB,
  //   binStep,
  //   amountXMin,
  //   amountYMin,
  //   ids,
  //   amounts,
  //   path,
  //   liquidityParameters,
  //   v2Router
  // );
  // console.log("Transaction hash:", tx.hash);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
