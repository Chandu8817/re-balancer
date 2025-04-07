// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {V3PositionManager} from "./interfaces/V3IPositionManger.sol";
import {ISwapRouter} from "./interfaces/V3IRouter.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
abstract contract V3 {
    function removeLiqudity(
        uint256 tokenId,
        V3PositionManager v3PositionManager
    ) internal {
        // remove liquidity from the pool
        // this function should be implemented to remove liquidity from the pool
        // and return the tokens to this contract
        // for example, using Uniswap V3's `decreaseLiquidity` function
        V3PositionManager.DecreaseLiquidityParams
            memory params = V3PositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: getLiquidity(v3PositionManager, tokenId),
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp + 1
            });

        v3PositionManager.decreaseLiquidity(params);

        // collect the tokens from the pool
        V3PositionManager.CollectParams memory collectParams = V3PositionManager
            .CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });
        (uint256 amount0, uint256 amount1) = v3PositionManager.collect(
            collectParams
        );
        require(amount0 > 0 || amount1 > 0, "No tokens collected");
    }

    function swapTokens(
        address tokenA,
        address tokenB,
        int24 tickSpacing,
        uint256 balIn,
        uint256 amountOutMin,
        uint160 sqrtPriceLimitX96,
        address router
    ) internal {
        // swap tokens using the router
        // this function should be implemented to swap tokens using the router
        // for example, using Uniswap V3's `swapExactTokensForTokens` function
        // or any other DEX's swap function
        // this is a placeholder function and should be implemented
        // according to the specific DEX's swap function
        // for example, using Uniswap V3's `swapExactTokensForTokens` function
        // or any other DEX's swap function
        approveTokens([tokenA, tokenB],[balIn,balIn], router);
      
        ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenA,
                tokenOut: tokenB,
                tickSpacing: tickSpacing,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: balIn ,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: sqrtPriceLimitX96
            });
        ISwapRouter swapRouter = ISwapRouter(router);
        swapRouter.exactInputSingle(swapParams);
    }

    function addLiqudity(
        address tokenA,
        address tokenB,
        int24 tickSpacing,
        int24 newTickLower,
        int24 newTickUpper,
        uint256 token0Balance,
        uint256 token1Balance,
        V3PositionManager v3PositionManager
    ) internal {
        V3PositionManager.MintParams memory params = V3PositionManager
            .MintParams({
                token0: tokenA,
                token1: tokenB,
                tickSpacing: tickSpacing,
                tickLower: newTickLower,
                tickUpper: newTickUpper,
                amount0Desired: token0Balance,
                amount1Desired: token1Balance,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp + 1
            });

        v3PositionManager.mint(params);
    }

    function getLiquidity(
        V3PositionManager v3PositionManager,
        uint256 positionId
    ) internal view returns (uint128 liquidity) {
        (, , , , , uint256 liq, , , , ) = v3PositionManager.positions(positionId);
         return SafeCast.toUint128(liq);
    }

     function approveTokens(
        address[2] memory tokens,
        uint256[2] memory amounts,
        address router
    ) internal {
       
        IERC20(tokens[0]).approve(router, amounts[0]);
        IERC20(tokens[1]).approve(router, amounts[1]);
    }

    function tokensBalance(
        address tokenA,
        address tokenB
    ) internal view returns (uint256, uint256) {
        uint256 balanceTokenA = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceTokenB = IERC20(tokenB).balanceOf(address(this));
        return (balanceTokenA, balanceTokenB);
    }
}
