pragma solidity ^0.7.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAToken is IERC20 {
    function redeem(uint256 _amount) external;
    function redirectInterestStream(address _to) external;
}