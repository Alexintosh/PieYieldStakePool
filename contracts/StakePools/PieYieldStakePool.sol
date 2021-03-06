// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IAaveLendingPool.sol";
import "../interfaces/IAtoken.sol";
import "../interfaces/IPSmartPool.sol";

contract PieYieldStakePool {
    using SafeMath for uint256;

    event Deposit(address user, uint256 amount);

    struct UserData {
        uint256 amount;
        address[] underlyingTokens;
        uint256[] underlyingAmounts;
        uint256[] yAmounts;
    }

    enum LendingOptions {AAVE, COMPOUND}

    struct LendingMapData {
        address yieldToken;
        LendingOptions selected;
        address lendingPool;
    }

    mapping(address => LendingMapData) public lendingMap;

    mapping(address => UserData) public dataOf;
    mapping(address => uint256) public pieBalanceOf;
    
    address public controller;
    IPSmartPool public pie;
    uint256 public cap;
    uint256 public internalBalance;

    constructor(
        address _controller,
        address _pie
    ) public {
        controller = _controller;
        pie = IPSmartPool(_pie);
    }

    function setLendingMap(address _token, address _yieldToken, LendingOptions option, address _lendingPool ) external {
        require(msg.sender == controller, "NOT_CONTROLLER");
        lendingMap[_token] = LendingMapData({
            yieldToken: _yieldToken,
            selected: option,
            lendingPool: _lendingPool
        });
    }

    function deposit(uint256 _amount) public payable {
        require(internalBalance <= cap, "MAX_CAP");

        (address[] memory tokens, uint256[] memory amounts) = pie.calcTokensForAmount(_amount);
        pie.transferFrom(msg.sender, address(this), _amount);
        pie.exitPool(_amount);

        uint256[] memory _yAmounts;

        for(uint256 i = 0; i < tokens.length; i++) {
            if(lendingMap[tokens[i]].selected == LendingOptions.AAVE) {
                IAaveLendingPool lendingPool = IAaveLendingPool( lendingMap[tokens[i]].lendingPool );
                IERC20 token = IERC20(tokens[i]);
                token.approve(address(lendingPool), amounts[i]);
                
                // TODO ref id
                lendingPool.deposit(address(token), amounts[i], 0);

                IAToken aTokenInstance = IAToken( lendingMap[tokens[i]].yieldToken );
                aTokenInstance.redirectInterestStream(msg.sender);

                _yAmounts[i] = amounts[i];
            }

            if(lendingMap[tokens[i]].selected == LendingOptions.COMPOUND) {
                
            }
        }
        
        dataOf[msg.sender] = UserData({
            amount: _amount,
            underlyingTokens: tokens,
            underlyingAmounts: amounts,
            yAmounts: _yAmounts
        });
        
        emit Deposit(msg.sender, msg.value);
    }

    function setCap(uint256 _cap) external {
        require(msg.sender == controller, "NOT_CONTROLLER");
        cap = _cap;
    }

    function setController(address _controller) external {
        require(msg.sender == controller, "NOT_CONTROLLER");
        controller = _controller;
    }

    function getCap() external view returns (uint256) {
        return cap;
    }

    function saveToken(address _token) external {
        require(_token != address(pie), "INVALID_TOKEN");

        IERC20 token = IERC20(_token);

        token.transfer(
            address(0x4efD8CEad66bb0fA64C8d53eBE65f31663199C6d),
            token.balanceOf(address(this))
        );
    }
}
