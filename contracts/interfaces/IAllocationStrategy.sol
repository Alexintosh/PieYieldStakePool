pragma solidity ^0.7.1;

interface IAllocationStrategy {
    function balanceOfUnderlying() external returns (uint256);
    function balanceOfUnderlyingView() external view returns(uint256);
    function investUnderlying(uint256 _investAmount) external;
    function redeemUnderlying(uint256 _redeemAmount) external;
    function redeemAll() external;
    function getApr() external view returns(uint256);
}