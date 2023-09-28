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

    function borrowWETH(uint256 amount, address _dai, address _user) external {
        POOL.borrow(_dai, amount, 2, 0, _user);
    }

    receive() external payable {}
}
