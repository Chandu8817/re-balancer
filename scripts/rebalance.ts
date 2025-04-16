import { ethers } from "hardhat";
import hre from "hardhat";
import JSBI from 'jsbi';
import rebalancerAbi from "../artifacts/contracts/Rebalancer.sol/Rebalancer.json";
import v3PositionAbi from "../mockAbis/v3postion.json";
import { string } from "hardhat/internal/core/params/argumentTypes";
import { fetchSonicTokenPrice } from "./price-fetcher-onchain";
async function main() {
  const provider = new ethers.JsonRpcProvider("https://rpc.soniclabs.com/");
  const wallet = new ethers.Wallet(process.env.PRIVATE_KEY!, provider);
  const owner = wallet.connect(provider);
  const rebalancer = new ethers.Contract(
    "0xf2198C9e80502eC6450c48E1CBC6828B2dA2E7ba",
    rebalancerAbi.abi,
    owner
  );
  const response = await fetchSonicTokenPrice()
  const {  tickUpper ,tickLower} = await calculateTicks(response.sqrtPriceX96); // 3000 = 0.3% fee tier
  console.log(tickLower, tickUpper);

  const tickSpacing = 50;

 
  const tokenA = "0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38";
  const tokenB = "0x29219dd400f2Bf60E5a23d13Be72B486D4038894";
  const router = "0x5543c6176FEb9B4b179078205d7C29EEa2e2d695";
  const positionManager = "0x12E66C8F215DdD5d48d150c8f46aD0c6fB0F4406";
  const increaseLiquidity = false;
  const v3PostionManager = new ethers.Contract(
    positionManager,
    v3PositionAbi.abi,
    owner
  );

  console.log(await rebalancer.positionId())
  // await rebalancer.setPositionId(678858);
    // await rebalancer.tranferPositionOwnership(
    //   positionManager,owner.address
    // )

  //   const erc20A = new ethers.Contract(
  //     tokenA,
  //     [
        
  //       "function balanceOf(address account) external view returns (uint256)",],owner
  //     )
  //   const erc20B = new ethers.Contract(
  //     tokenB,

  //     [
  //       "function balanceOf(address account) external view returns (uint256)",],owner
  //     )
  //   const balanceA = await erc20A.balanceOf("0xf2198C9e80502eC6450c48E1CBC6828B2dA2E7ba");
  //   const balanceB = await erc20B.balanceOf("0xf2198C9e80502eC6450c48E1CBC6828B2dA2E7ba");

  // await rebalancer.withdrawTokens(
  //     tokenA,balanceA,owner.address
  //   )

    // setTimeout(() => {
    //   console.log("Waiting for 10 seconds...");
    // }, 10000);

    // await rebalancer.withdrawTokens(
    //   tokenB,balanceB,owner.address
    // )

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
    tickSpacing,
    tickLower,
    tickUpper,0,0,
    positionManager,
"0x324963c267c354c7660ce8ca3f5f167e05649970",
    false
  );

  const recipt = await tx.wait();
  // console.log("Transaction recipt:", recipt);
await  decodeLogs(provider,tx.hash);
  // console.log("Transaction recipt:", recipt?.logs.events[0].data);
  
  // console.log("Transaction recipt:", recipt?.logs.events[0].topics[1]);
  // console.log("Transaction hash:", tx.hash);
 

  // setTimeout(() => {
  //   console.log("Waiting for 10 seconds...");
  // }, 10000);
  // await rebalancer.tranferPositionOwnership(
  //   positionManager,
  //   owner.address
  // );

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



// const txHash = "0xacf6477f441e07414c059148625a085974a38d981ca5642786c26a8e25af8b86";

// 1. Minimal ABI for just the event you need
const iface = new ethers.Interface([
  "event RebalancedV3(uint256 liqudity, uint256 amount0, uint256 amount1, uint256 positionId)"
]);

async function decodeLogs(provider:any,txHash :string) {
  const receipt = await provider.getTransactionReceipt(txHash);
  // console.log("Transaction receipt:", receipt);
  for (const log of receipt.logs) {
    try {
      const parsedLog:any = iface.parseLog(log);
      if (parsedLog.name === "RebalancedV3") {
        console.log("✅ RebalancedV3 Event Found!");
        console.log("Liquidity:", parsedLog.args.liqudity.toString());
        console.log("Amount0:", parsedLog.args.amount0.toString());
        console.log("Amount1:", parsedLog.args.amount1.toString());
        console.log("Position ID:", parsedLog.args.positionId.toString());
      }
    } catch (err) {
      // Not our event, skip it
    }
  }
}





export async function calculateTicks(sqrtPriceX96:JSBI) {


  const tickSpacing = 50;

  // 3. Calculate current price from sqrtPriceX96
  // Price = sqrtPriceX96^2 / 2^192
  const currentPrice = Number((Number(sqrtPriceX96) ** 2) / (2 ** 192));
  console.log(currentPrice)

  // 4. Calculate target prices (±2%)
  const upperPrice = currentPrice * 1.02; // +2%
  const lowerPrice = currentPrice * 0.98; // -2%

  // 5. Convert prices to ticks manually
  // tick = floor(log(sqrt(price)) / log(1.0001))
  const logBase = Math.log(1.0001);
  const upperTick = Math.floor(Math.log(Math.sqrt(upperPrice)) / logBase);
  const lowerTick = Math.floor(Math.log(Math.sqrt(lowerPrice)) / logBase);

  // 6. Round ticks to nearest valid tick spacing
  const tickUpper = (Math.floor(upperTick / tickSpacing) * tickSpacing*2);
  const tickLower = (Math.floor(lowerTick / tickSpacing) * tickSpacing)*2;

  return {
    tickUpper,
    tickLower
    
  };
}
