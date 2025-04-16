
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IVoter {

    /// @notice claim concentrated liquidity gauge rewards for specific NFP token ids
    /// @param _gauges array of gauges
    /// @param _tokens two dimensional array for the tokens to claim
    /// @param _nfpTokenIds two dimensional array for the NFPs
    function claimClGaugeRewards(
        address[] calldata _gauges,
        address[][] calldata _tokens,
        uint256[][] calldata _nfpTokenIds
    ) external;
    /// @notice returns the address of the pool's gauge, if any
    /// @param _pool pool address
    /// @return _gauge gauge address
    function gaugeForPool(address _pool) external view returns (address _gauge);
     /// @notice xShadow contract address
    function xShadow() external view returns (address);

}