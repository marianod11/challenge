// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {PolicyNFT} from "./PolicyNFT.sol";
import {IPool} from "./interfaces/IPool.sol";
import {IPoolAddressesProvider} from "./interfaces/IPoolAddressesProvider.sol";
import {IUiPoolDataProviderV3} from "./interfaces/IUiPoolDataProviderV3.sol";

contract Challenge is Ownable {
    using SafeMath for uint256;

    IERC20 public usdcToken;

    uint256 public insuranceFee;
    uint256 public claimFee = 200;

    address public tresury;
    address public governor;

    PolicyNFT public policyNFTContract;

    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;
    IPool public immutable POOL;
    IUiPoolDataProviderV3 public immutable POOLDATAUSER;

    struct NFTMetaData {
        uint256 totalCollateral;
        uint256 totalBorrowed;
        uint256 borrowingLimit;
        uint256 health;
        uint256 totalInsured;
        address owner;
    }

    mapping(uint256 => NFTMetaData) public nftData;
    mapping(address => uint) public idOwner;
    mapping(address => bool) private isSecured;

    event Attest(address indexed to, uint256 indexed tokenId);
    event Revoke(address indexed to, uint256 indexed tokenId);

    /**
     * @dev Constructor of the Challenge contract
     * @param _usdcToken Address of the USDC token contract
     * @param _addressProvider Address of the market's address provider
     * @param _IUiPoolDataProviderV3 Address of the user pool data contract
     * @param _treasury Treasury address
     * @param _policyNFTContract Address of the non-fungible policy token contract
     * @param _insuranceFee Initial insurance fee
     */
    constructor(
        address _usdcToken,
        address _addressProvider,
        address _IUiPoolDataProviderV3,
        address _tresury,
        address _policyNFTContract,
        uint256 _insuranceFee 
    ) {
        usdcToken = IERC20(_usdcToken);
        ADDRESSES_PROVIDER = IPoolAddressesProvider(_addressProvider);
        POOL = IPool(ADDRESSES_PROVIDER.getPool());
        POOLDATAUSER = IUiPoolDataProviderV3(_IUiPoolDataProviderV3);
        tresury = _tresury;
        policyNFTContract = PolicyNFT(_policyNFTContract);
        insuranceFee = _insuranceFee;
       
    }

    /**
     * @dev Returns information about all user positions.
     * @param _user The user's address.
     * @return UserReserveData.
     */
    function allUserPositions(
        address _user
    ) external view returns (IUiPoolDataProviderV3.UserReserveData[] memory) {
        (
            IUiPoolDataProviderV3.UserReserveData[] memory userData,

        ) = POOLDATAUSER.getUserReservesData(ADDRESSES_PROVIDER, _user);
        return userData;
    }

    /**
     * @dev Retrieves user reserve state data.
     * @param _user The user's address.
     * @return totalCollateralBase Total collateral deposited by the user.
     * @return totalDebtBase Total debt of the user.
     * @return availableBorrowsBase Available borrowing limit for the user.
     * @return currentLiquidationThreshold Current liquidation threshold of the user.
     * @return ltv Loan-to-Value (LTV) ratio of the user.
     * @return healthFactor User's financial health factor.
     */
    function _getUserData(
        address _user
    )
        internal
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        return POOL.getUserAccountData(_user);
    }

    /**
     * @dev Gets the Health Factor of a user.
     * @param _user The user's address.
     * @return The user's Health Factor.
     */
    function _getHealthFactor(address _user) internal view returns (uint256) {
        (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            ,
            uint256 currentLiquidationThreshold,
            ,

        ) = _getUserData(_user);

        uint256 HF = (totalCollateralBase.mul(currentLiquidationThreshold)).div(
            totalDebtBase
        );

        return HF.div(1e18);
    }

    /**
     * @dev Allows a user to purchase an insurance policy.
     * @param _user The user's address.
     */
    function buyInsurance(address _user) external {
        (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            ,
            ,

        ) = _getUserData(_user);

        require(totalDebtBase > 0, "You haven't borrowed");

        uint healthFactor = _getHealthFactor(_user);

        require(!isSecured[_user], "You are already insured");
        require(healthFactor > 1, "Position to liquidate");

        uint256 totalInsured = (totalCollateralBase.div(100)).div(2);

        uint256 pricePolicy = (totalCollateralBase.div(100)).div(4);

        usdcToken.transferFrom(_user, address(this), pricePolicy);
        usdcToken.transferFrom(_user, tresury, insuranceFee);

        uint256 tokenId = policyNFTContract.safeMint(_user);

        idOwner[_user] = tokenId;
        isSecured[_user] = true;

        nftData[tokenId] = NFTMetaData({
            totalCollateral: totalCollateralBase,
            totalBorrowed: totalDebtBase,
            borrowingLimit: availableBorrowsBase,
            health: healthFactor,
            totalInsured: totalInsured,
            owner: _user
        });
    }

    /**
     * @dev Allows a user to claim insurance policy payout if their position is liquidated.
     * @param _user The user's address.
     */
    function claimInsurance(address _user) external {
        uint healthFactor = _getHealthFactor(_user);
        require(healthFactor < 1, "Position not  liquidate");

        (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            ,
            ,

        ) = _getUserData(_user);

        uint idToken = idOwner[_user];
        NFTMetaData memory dataNft = nftData[idToken];

        require(
            totalCollateralBase != dataNft.totalCollateral,
            "User not liquidate"
        );

        policyNFTContract.burn(idToken, _user);
        uint256 total = dataNft.totalInsured;
        uint256 percentage2 = (total.mul(claimFee)).div(10000);
        uint256 percentage98 = total - percentage2;

        usdcToken.approve(address(this), total);
        usdcToken.transferFrom(address(this), _user, percentage98);

        usdcToken.transferFrom(address(this), tresury, percentage2);
        isSecured[_user] = false;

        delete nftData[idToken];
        delete idOwner[_user];
    }

    /**
     * @dev Retrieves data for an insurance policy associated with a user.
     * @param _user The user's address to query policy data.
     * @return NFTMetaData.
     */
    function getDataNft(
        address _user
    ) external view returns (NFTMetaData memory) {
        uint idToken = idOwner[_user];
        NFTMetaData memory dataNft = nftData[idToken];

        return dataNft;
    }

    /**
     * @dev Permite al propietario del contrato cambiar la tarifa de seguro.
     * @param _newFee La nueva tarifa de seguro a establecer.
     */

    function setInsuranceFee(uint256 _newFee) external onlyOwner {
        insuranceFee = _newFee;
    }
}
