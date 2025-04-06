// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {V3PositionManager} from "./interfaces/V3IPositionManger.sol";
import {ISwapRouter} from "./interfaces/V3IRouter.sol";

contract Rebalancer is Ownable {
    // state variables
    mapping(address => bool) public routers;
    uint256 maxGasFee;

    constructor(address _router, uint256 _maxGasFee) Ownable(msg.sender) {
        routers[_router] = true;
        maxGasFee = _maxGasFee;
    }

    function rebalanceV3(
        address router,
        address tokenA,
        address tokenB,
        uint256 positionId,
        int24 tickSpacing,
        int24 newTickLower,
        int24 newTickUpper,
        address _v3PositionManager
    ) external onlyOwner {
        require(tx.gasprice <= maxGasFee, "Gas price too high");
        // remove liquidity from the pool

        V3PositionManager v3PositionManager = V3PositionManager(
            _v3PositionManager
        );

        removeLiqudity(positionId, v3PositionManager);

        (uint256 balanceTokenA, uint256 balanceTokenB) = tokensBalance(
            tokenA,
            tokenB
        );
        if (balanceTokenA == 0 || balanceTokenB == 0) {
            revert("No tokens to swap");
        }

        // if (balanceTokenA > balanceTokenB) {
        //     // swap tokenA to tokenB
        //     swapTokens(tokenA, tokenB, router);
        // } else {
        //     // swap tokenB to tokenA
        //     swapTokens(tokenB, tokenA, router);
        // }

        addLiqudity(
            tokenA,
            tokenB,
            tickSpacing,
            newTickLower,
            newTickUpper,
            balanceTokenA,
            balanceTokenB,
            v3PositionManager
        );
    }

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
        uint256 balIn, uint256 amountOutMin, uint160 sqrtPriceLimitX96,
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
        approveTokens([tokenA, tokenB], router);

       ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenA,
            tokenOut: tokenB,
            tickSpacing: tickSpacing,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: balIn / 2,
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

    function tokensBalance(
        address tokenA,
        address tokenB
    ) internal view returns (uint256, uint256) {
        uint256 balanceTokenA = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceTokenB = IERC20(tokenB).balanceOf(address(this));
        return (balanceTokenA, balanceTokenB);
    }

    function setMaxGasFee(uint256 _gasFee) external onlyOwner {
        require(_gasFee > 0, "max fee can't be zero");
        maxGasFee = _gasFee;
    }

    function getLiquidity(
        V3PositionManager v3PositionManager,
        uint256 positionId
    ) internal view returns (uint128 liquidity) {
        (, , , , , liquidity, , , , ) = v3PositionManager.positions(positionId);
    }

    function approveTokens(
        address[2] memory tokens,
        address router
    ) internal onlyOwner {
        (uint256 balanceTokenA, uint256 balanceTokenB) = tokensBalance(
            tokens[0],
            tokens[1]
        );

        IERC20(tokens[0]).approve(router, balanceTokenA);
        IERC20(tokens[1]).approve(router, balanceTokenB);
    }

    function setRouter(address _router) external onlyOwner {
        require(_router != address(0), "Router address can't be zero");
        require(!routers[_router], "Router already exists");
        routers[_router] = true;
    }

    function removeRouter(address _route) external onlyOwner {
        require(routers[_route], "Router doesn't exist");
        routers[_route] = false;
    }
}
