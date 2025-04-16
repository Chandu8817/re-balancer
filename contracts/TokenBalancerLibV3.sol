// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

library TokenBalancerLibV3 {
    uint8 constant decimalsA = 18; // Token A
    uint8 constant decimalsB = 6; // Token B (e.g. USDC)

    // Function to compute the required swap amounts for Token A and Token B
    function getRequiredSwapAmountFromSqrtPrice(
        uint256 balanceA,
        uint256 balanceB,
        address pool
    )
        internal
        view
        returns (int256 amountAToSwap, int256 amountBToSwap, uint256 priceAinB)
    {
        IUniswapV3Pool uniswapPool = IUniswapV3Pool(pool);
        (uint160 sqrtPriceX96, , , , , , ) = uniswapPool.slot0();
        // Compute priceAinB in 1e18 scale: (sqrtPriceX96^2 * 1e18) / 2^192
        priceAinB = (uint256(sqrtPriceX96) * sqrtPriceX96 * 1e18) / (2 ** 192);

        // Normalize balances to 1e18 scale
        uint256 normA = (balanceA * 1e18) / (10 ** decimalsA);
        uint256 normB = (balanceB * 1e18) / (10 ** decimalsB);

        // Value of Token A in B units
        uint256 valueAinB = (normA * priceAinB) / 1e18;
        uint256 valueBinB = normB;

        uint256 totalValue = valueAinB + valueBinB;
        uint256 targetValue = totalValue / 2;

        int256 diffA = int256(valueAinB) - int256(targetValue);
        int256 diffB = int256(valueBinB) - int256(targetValue);

        if (diffA > 0) {
            // Token A is overbalanced → swap A for B
            uint256 valueToSwap = uint256(diffA);
            uint256 normAmount = (valueToSwap * 1e18) / priceAinB;
            amountAToSwap = int256((normAmount * (10 ** decimalsA)) / 1e18);
            amountBToSwap = 0;
        } else if (diffB > 0) {
            // Token B is overbalanced → swap B for A
            uint256 valueToSwap = uint256(diffB);
            amountBToSwap = int256((valueToSwap * (10 ** decimalsB)) / 1e18);
            amountAToSwap = 0;
        } else {
            amountAToSwap = 0;
            amountBToSwap = 0;
        }
    }
}
