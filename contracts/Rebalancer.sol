// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {V3PositionManager} from "./interfaces/V3IPositionManger.sol";
import {ISwapRouter} from "./interfaces/V3IRouter.sol";
import {ILBRouter} from "./interfaces/V2IRouter.sol";
import {V3} from "./V3.sol";
import {TokenBalancerLibV3} from "./TokenBalancerLibV3.sol";

// import {V2} from "./V2.sol";

contract Rebalancer is AccessControl, ReentrancyGuard, V3 {
    // state variables
    using SafeERC20 for IERC20;

    address public immutable voter;

   

    // 2. Add events
    event RebalancedV3(
        uint256 liqudity,
        uint256 amount0,
        uint256 amount1,
        uint256 positionId
    );
    event RouterUpdated(address router, bool added);

    // 3. Use custom errors
    error InsufficientLiquidity();
    error InvalidSwapPath();
    mapping(address => bool) public routers;
    uint256 maxGasFee;
    uint16 public maxSlippage = 100; // 5%
    uint256 public positionId;

    address public adminAddress;
    bytes32 public constant REBALANCER_ROLE = keccak256("REBALANCER_ROLE");

    constructor(
        address _router,
        uint256 _maxGasFee,
        uint256 _positionId,
        address _rebalancer,
        address _voter


    ) {
        routers[_router] = true;
        maxGasFee = _maxGasFee;
        positionId = _positionId;
        voter = _voter;
    
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(REBALANCER_ROLE, _rebalancer);
    }

    function rebalancerV3(
        address router,
        address tokenA,
        address tokenB,
        int24 tickSpacing,
        int24 newTickLower,
        int24 newTickUpper,
        uint160 sqrtPriceLimitX96,
        uint256 amountOutMin,
        address _v3PositionManager,
        address pool,
        bool increaseLiquidity
    ) external nonReentrant onlyRole(REBALANCER_ROLE) {
        require(tx.gasprice <= maxGasFee, "Gas price too high");
        require(routers[router], "Router doesn't exist");

        V3PositionManager v3PositionManager = V3PositionManager(
            _v3PositionManager
        );

        // 1. Remove liquidity
        removeLiqudity(positionId, v3PositionManager,voter,pool);

        // 2. Get balances
        (uint256 balanceTokenA, uint256 balanceTokenB) = tokensBalance(
            tokenA,
            tokenB
        );
        if (balanceTokenA == 0 && balanceTokenB == 0) {
            revert("No tokens to swap");
        }

        // 3. Rebalance
        (int256 amountAToSwap, int256 amountBToSwap, ) = TokenBalancerLibV3
            .getRequiredSwapAmountFromSqrtPrice(
                IERC20(tokenA).balanceOf(address(this)),
                IERC20(tokenB).balanceOf(address(this)),
                pool
            );

        if (amountAToSwap > 0) {
            swapTokens(
                tokenA,
                tokenB,
                tickSpacing,
                uint256(amountAToSwap),
                amountOutMin,
                sqrtPriceLimitX96,
                router
            );
        } else if (amountBToSwap > 0) {
            swapTokens(
                tokenB,
                tokenA,
                tickSpacing,
                uint256(amountBToSwap),
                amountOutMin,
                sqrtPriceLimitX96,
                router
            );
        }

        // 4. Add Liquidity (first try)
        (balanceTokenA, balanceTokenB) = tokensBalance(tokenA, tokenB);
        (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        ) = addLiqudity(
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

        if (tokenId != 0) {
            positionId = tokenId;
        }

        // Optional: threshold to avoid tiny dust
        uint256 minThreshold = 1e17; // 0.1 token (for 18 decimals)
        uint256 minThresholdB = 1e5; // 0.1 USDC (6 decimals)
        uint128 extraLiquidity = liquidity;
        uint256 extraAmount0 = amount0;
        uint256 extraAmount1 = amount1;
        while (true) {
            // 5. Check leftovers and re-swap the dominant token
            (balanceTokenA, balanceTokenB) = tokensBalance(tokenA, tokenB);

            // Break if both balances are below threshold
            if (balanceTokenA < minThreshold && balanceTokenB < minThresholdB) {
                break;
            }

            // Re-run swap to clean leftovers
            (amountAToSwap, amountBToSwap, ) = TokenBalancerLibV3
                .getRequiredSwapAmountFromSqrtPrice(
                    balanceTokenA,
                    balanceTokenB,
                    pool
                );

            if (amountAToSwap > 0) {
                swapTokens(
                    tokenA,
                    tokenB,
                    tickSpacing,
                    uint256(amountAToSwap),
                    amountOutMin,
                    sqrtPriceLimitX96,
                    router
                );
            } else if (amountBToSwap > 0) {
                swapTokens(
                    tokenB,
                    tokenA,
                    tickSpacing,
                    uint256(amountBToSwap),
                    amountOutMin,
                    sqrtPriceLimitX96,
                    router
                );
            }

            // 6. Add leftover liquidity (second try, always increaseLiquidity = false)
            (balanceTokenA, balanceTokenB) = tokensBalance(tokenA, tokenB);
            (, liquidity, amount0, amount1) = addLiqudity(
                tokenA,
                tokenB,
                tickSpacing,
                newTickLower,
                newTickUpper,
                balanceTokenA,
                balanceTokenB,
                v3PositionManager,
                positionId,
                true // override to false
            );

            extraLiquidity += liquidity;
            extraAmount0 += amount0;
            extraAmount1 += amount1;
        }
        emit RebalancedV3(
            extraLiquidity,
            extraAmount0,
            extraAmount1,
            positionId
        );
    }

    // function rebalancerV2(
    //     IERC20 tokenX,
    //     IERC20 tokenY,
    //     uint16 binStep,
    //     uint256 amountXMin,
    //     uint256 amountYMin,
    //     uint256[] memory ids,
    //     uint256[] memory amounts,
    //     ILBRouter.Path memory path,
    //     ILBRouter.LiquidityParameters calldata liquidityParameters,
    //     address router
    // ) external nonReentrant onlyRole(REBALANCER_ROLE) {
    //     require(tx.gasprice <= maxGasFee, "Gas price too high");
    //     require(routers[router], "Router doesn't exist");
    //     removeLiqudity(
    //         tokenX,
    //         tokenY,
    //         binStep,
    //         amountXMin,
    //         amountYMin,
    //         ids,
    //         amounts,
    //         router
    //     );
    //     (uint256 balanceTokenA, uint256 balanceTokenB) = tokensBalanceV2(
    //         address(tokenX),
    //         address(tokenY)
    //     );
    //     if (balanceTokenA == 0 || balanceTokenB == 0) {
    //         revert("No tokens to swap");
    //     }

    //     if (balanceTokenA > balanceTokenB) {
    //         uint256 swapAmount = balanceTokenA -
    //             ((balanceTokenA + balanceTokenB) / 2);

    //         // swap tokenA to tokenB
    //         swapTokens(swapAmount, amountYMin, path, router);
    //     } else {
    //         uint256 swapAmount = balanceTokenB -
    //             ((balanceTokenA + balanceTokenB) / 2);

    //         // swap tokenB to tokenA
    //         swapTokens(swapAmount, amountXMin, path, router);
    //     }
    //     (balanceTokenA, balanceTokenB) = tokensBalance(
    //         address(tokenX),
    //         address(tokenY)
    //     );
    // }

    function setMaxGasFee(
        uint256 _gasFee
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_gasFee > 0, "max fee can't be zero");
        maxGasFee = _gasFee;
    }

    function setRouter(address _router) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_router != address(0), "Router address can't be zero");
        require(!routers[_router], "Router already exists");
        routers[_router] = true;
    }

    function removeRouter(
        address _route
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(routers[_route], "Router doesn't exist");
        routers[_route] = false;
    }

    function setMaxSlippage(
        uint16 _slippage
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_slippage <= 1000, "Max 10% slippage");
        maxSlippage = _slippage;
    }

    function withdrawTokens(
        address token,
        uint256 amount,
        address to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(token != address(0), "Token address can't be zero");
        require(to != address(0), "Recipient address can't be zero");
        require(amount > 0, "Amount can't be zero");
        IERC20(token).safeTransfer(to, amount);
    }

    function tranferPositionOwnership(
        address _v3PositionManager,
        address newOwner
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newOwner != address(0), "New owner can't be zero");
        V3PositionManager v3PositionManager = V3PositionManager(
            _v3PositionManager
        );
        v3PositionManager.safeTransferFrom(address(this), newOwner, positionId);
    }

    function setPositionId(
        uint256 _positionId
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_positionId > 0, "Position ID can't be zero");
        positionId = _positionId;
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
