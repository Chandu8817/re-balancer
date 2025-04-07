// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ILBRouter} from "./interfaces/V2IRouter.sol";

abstract contract V2 {
    using SafeERC20 for IERC20;

    function removeLiqudity(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint256 amountXMin,
        uint256 amountYMin,
        uint256[] memory ids,
        uint256[] memory amounts,
        address router
    ) internal {
        ILBRouter lbRouter = ILBRouter(router);
        lbRouter.removeLiquidity(
            tokenX,
            tokenY,
            binStep,
            amountXMin,
            amountYMin,
            ids,
            amounts,
            address(this),
            block.timestamp + 100
        );
    }

    function swapTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        ILBRouter.Path memory path,
        address router
    ) internal {
        approveTokensV2(
            [address(path.tokenPath[0]), address(path.tokenPath[1])],
            [amountIn, amountOutMin],
            router
        );
        ILBRouter lbRouter = ILBRouter(router);
        lbRouter.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            block.timestamp + 100
        );
    }

    function addLiqudity(
        ILBRouter.LiquidityParameters calldata liquidityParameters,
        address router
    ) internal {
        ILBRouter lbRouter = ILBRouter(router);
        lbRouter.addLiquidity(liquidityParameters);
    }

    function getLiquidity(
        address router
    ) internal view returns (uint128 liquidity) {}

    function approveTokensV2(
        address[2] memory tokens,
        uint256[2] memory amounts,
        address router
    ) internal {
        IERC20(tokens[0]).approve(router, amounts[0]);
        IERC20(tokens[1]).approve(router, amounts[1]);
    }

    function tokensBalanceV2(
        address tokenA,
        address tokenB
    ) internal view returns (uint256, uint256) {
        uint256 balanceTokenA = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceTokenB = IERC20(tokenB).balanceOf(address(this));
        return (balanceTokenA, balanceTokenB);
    }

    function _resetAllowance(IERC20 token, address spender) internal {
        if (token.allowance(address(this), spender) > 0) {
            token.approve(spender, 0);
        }
    }
}
