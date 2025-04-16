import { ethers } from "ethers";
import BN from "bn.js";
import JSBI from "jsbi";
const SONIC_TOKEN_ADDRESS = "0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38";
const USDC_TOKEN_ADDRESS = "0x29219dd400f2Bf60E5a23d13Be72B486D4038894"; // Assuming USDC as the pair token
const UNISWAP_V3_POOL_ADDRESS = "0x324963c267C354c7660Ce8CA3F5f167E05649970"; // Replace with the actual pool address
const IUniswapV3PoolABI = [
  "function slot0() view returns (uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint8 feeProtocol, bool unlocked)",
  "function token0() view returns (address)",
  "function token1() view returns (address)",
];
const ERC20_ABI = [
  "function decimals() view returns (uint8)",
]
const provider = new ethers.JsonRpcProvider(
  "https://rpc.ankr.com/sonic_mainnet"
);


const Q96 = new BN(2).pow(new BN(96));

export async function fetchSonicTokenPrice(): Promise<{ price: number; sqrtPriceX96: JSBI }> {
  const pool = new ethers.Contract(UNISWAP_V3_POOL_ADDRESS, IUniswapV3PoolABI, provider);

  const [sqrtPriceX96, token0, token1] = await Promise.all([
    pool.slot0().then(s => s.sqrtPriceX96),
    pool.token0(),
    pool.token1()
  ]);

  const [token0Decimals, token1Decimals] = await Promise.all([
    new ethers.Contract(token0, ERC20_ABI, provider).decimals(),
    new ethers.Contract(token1, ERC20_ABI, provider).decimals()
  ]);

  // Convert sqrtPriceX96 to price ratio with precision preserved
  const sqrtPrice =new BN(sqrtPriceX96);
  const numerator = sqrtPrice.mul(sqrtPrice).mul(new BN(10).pow(new BN(token0Decimals)));
  const denominator = Q96.mul(Q96).mul(new BN(10).pow(new BN(token1Decimals)));
  const price = Number(numerator.mul(new BN(1e6)).div(denominator).toString()) / 1e6; // Keep 6 decimals

  return { price, sqrtPriceX96 };
}
