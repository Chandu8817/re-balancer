// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {V3PositionManager} from "./interfaces/V3IPositionManger.sol";
import {ISwapRouter} from "./interfaces/V3IRouter.sol";
import {ILBRouter} from "./interfaces/V2IRouter.sol";
import {V3} from "./V3.sol";
import {V2} from "./V2.sol";

contract Rebalancer is Ownable, ReentrancyGuard, V3, V2 {
    // state variables
    using SafeERC20 for IERC20;

    // 2. Add events
    event RebalancedV3(uint256 timestamp);
    event RouterUpdated(address router, bool added);

    // 3. Use custom errors
    error InsufficientLiquidity();
    error InvalidSwapPath();
    mapping(address => bool) public routers;
    uint256 maxGasFee;
    uint256 public maxSlippage = 500; // 5%
   
    constructor(address _router, uint256 _maxGasFee) {
        routers[_router] = true;
        maxGasFee = _maxGasFee;
    }

    function rebalancerV3(
        address router,
        address tokenA,
        address tokenB,
        uint256 positionId,
        int24 tickSpacing,
        int24 newTickLower,
        int24 newTickUpper,
        uint160 sqrtPriceLimitX96,
        address _v3PositionManager,
        bool increaseLiquidity
    ) external nonReentrant onlyOwner {
        require(tx.gasprice <= maxGasFee, "Gas price too high");
        require(routers[router], "Router doesn't exist");
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

        if (balanceTokenA > balanceTokenB) {
            uint256 imbalance = (balanceTokenA - balanceTokenB) / 2;
            // swap tokenA to tokenB
            swapTokens(
                tokenA,
                tokenB,
                tickSpacing,
                imbalance,
                0,
                sqrtPriceLimitX96,
                router
            );
        } else {
            uint256 imbalance = (balanceTokenB - balanceTokenA) / 2;

            // swap tokenB to tokenA
            swapTokens(
                tokenB,
                tokenA,
                tickSpacing,
                imbalance,
                0,
                sqrtPriceLimitX96,
                router
            );
        }

        (balanceTokenA, balanceTokenB) = tokensBalance(tokenA, tokenB);

        addLiqudity(
            tokenA,
            tokenB,
            tickSpacing,
            newTickLower,
            newTickUpper,
            balanceTokenA,
            balanceTokenB,
            v3PositionManager,
            positionId,
            increaseLiquidity
        );
    }

    function rebalancerV2(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint256 amountXMin,
        uint256 amountYMin,
        uint256[] memory ids,
        uint256[] memory amounts,
        ILBRouter.Path memory path,
        ILBRouter.LiquidityParameters calldata liquidityParameters,
        address router
    ) external nonReentrant onlyOwner {
        require(tx.gasprice <= maxGasFee, "Gas price too high");
        require(routers[router], "Router doesn't exist");
        removeLiqudity(
            tokenX,
            tokenY,
            binStep,
            amountXMin,
            amountYMin,
            ids,
            amounts,
            router
        );
        (uint256 balanceTokenA, uint256 balanceTokenB) = tokensBalanceV2(
            address(tokenX),
            address(tokenY)
        );
        if (balanceTokenA == 0 || balanceTokenB == 0) {
            revert("No tokens to swap");
        }

        if (balanceTokenA > balanceTokenB) {
            uint256 swapAmount = balanceTokenA -
                ((balanceTokenA + balanceTokenB) / 2);

            // swap tokenA to tokenB
            swapTokens(swapAmount, amountYMin, path, router);
        } else {
            uint256 swapAmount = balanceTokenB -
                ((balanceTokenA + balanceTokenB) / 2);

            // swap tokenB to tokenA
            swapTokens(swapAmount, amountXMin, path, router);
        }
        (balanceTokenA, balanceTokenB) = tokensBalance(
            address(tokenX),
            address(tokenY)
        );

        addLiqudity(liquidityParameters, router);
    }

    function setMaxGasFee(uint256 _gasFee) external onlyOwner {
        require(_gasFee > 0, "max fee can't be zero");
        maxGasFee = _gasFee;
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

    function setMaxSlippage(uint256 _slippage) external onlyOwner {
        require(_slippage <= 1000, "Max 10% slippage");
        maxSlippage = _slippage;
    }

    function withdrawTokens(
        address token,
        uint256 amount,
        address to
    ) external onlyOwner {
        require(token != address(0), "Token address can't be zero");
        require(to != address(0), "Recipient address can't be zero");
        require(amount > 0, "Amount can't be zero");
        IERC20(token).safeTransfer(to, amount);
    }

    function tranferPositionOwnership(
        address _v3PositionManager,
        uint256 positionId,
        address newOwner
    ) external onlyOwner {
        require(newOwner != address(0), "New owner can't be zero");
        V3PositionManager v3PositionManager = V3PositionManager(
            _v3PositionManager
        );
        v3PositionManager.safeTransferFrom(address(this), newOwner, positionId);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
