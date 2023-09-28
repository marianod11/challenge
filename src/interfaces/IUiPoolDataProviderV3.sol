// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./IPoolAddressesProvider.sol";

interface IUiPoolDataProviderV3 {
    struct UserReserveData {
        address underlyingAsset;
        uint256 scaledATokenBalance;
        bool usageAsCollateralEnabledOnUser;
        uint256 stableBorrowRate;
        uint256 scaledVariableDebt;
        uint256 principalStableDebt;
        uint256 stableBorrowLastUpdateTimestamp;
    }

    function getUserReservesData(
        IPoolAddressesProvider provider,
        address user
    ) external view returns (UserReserveData[] memory, uint8);
}
