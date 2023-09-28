// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IPool} from "./interfaces/IPool.sol";
import {IPoolAddressesProvider} from "./interfaces/IPoolAddressesProvider.sol";
import {IUiPoolDataProviderV3} from "./interfaces/IUiPoolDataProviderV3.sol";
import {IERC20} from "./interfaces/IERC20.sol";

contract MarketInteractions {
    address payable owner;

    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;
    IPool public immutable POOL;
    IUiPoolDataProviderV3 public immutable POOLDATAUSER;

    address private immutable wethAddress =
        0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    IERC20 private weth;

    constructor(address _addressProvider, address _poolProvider) {
        ADDRESSES_PROVIDER = IPoolAddressesProvider(_addressProvider);
        POOL = IPool(ADDRESSES_PROVIDER.getPool());
        POOLDATAUSER = IUiPoolDataProviderV3(_poolProvider);
        owner = payable(msg.sender);
        weth = IERC20(wethAddress);
    }

    function supplyLiquidity(uint256 _amount, address _user) external {
        IERC20 wethToken = IERC20(wethAddress);
        wethToken.transferFrom(_user, address(this), _amount);
        wethToken.approve(address(POOL), _amount);

        POOL.supply(wethAddress, _amount, _user, 0);
    }

    function borrowWETH(
        uint256 amount,
        address _token,
        address _user
    ) external {
        IERC20 aWethToken = IERC20(0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8);

        aWethToken.approve(address(POOL), amount);
        POOL.borrow(_token, amount, 1, 0, _user);
    }

    receive() external payable {}
}
