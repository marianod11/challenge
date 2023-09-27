// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./PolicyNFT.sol";
import {IPool} from "./interfaces/IPool.sol";
import {IPoolAddressesProvider} from "./interfaces/IPoolAddressesProvider.sol";
import {IUiPoolDataProviderV3} from "./interfaces/IUiPoolDataProviderV3.sol";

contract Challenge is Ownable {
    using SafeMath for uint256;

    IERC20 public usdcToken;

    uint256 public insuranceFee;
    uint256 public percentageFee = 200;
    uint256 public pricePolicy;

    address public oracle;
    address public tresury;

    PolicyNFT public policyNFTContract;

    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;
    IPool public immutable POOL;
    IUiPoolDataProviderV3 public immutable POOLDATAUSER;

    struct NFTMetaData {
        uint256 totalLent;
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

    constructor(
        address _usdcToken,
        //   address _oracle,
        address _addressProvider,
        address _IUiPoolDataProviderV3,
        address _tresury,
        address _policyNFTContract,
        uint256 _insuranceFee,
        uint256 _pricePolicy
    ) {
        usdcToken = IERC20(_usdcToken);
        //   oracle = _oracle;
        ADDRESSES_PROVIDER = IPoolAddressesProvider(_addressProvider);
        POOL = IPool(ADDRESSES_PROVIDER.getPool());
        POOLDATAUSER = IUiPoolDataProviderV3(_IUiPoolDataProviderV3);
        policyNFTContract = PolicyNFT(_policyNFTContract);
        insuranceFee = _insuranceFee;
        tresury = _tresury;
        pricePolicy = _pricePolicy;
    }

    function allUserPositions()
        external
        view
        returns (IUiPoolDataProviderV3.UserReserveData[] memory)
    {
        (
            IUiPoolDataProviderV3.UserReserveData[] memory userData,

        ) = POOLDATAUSER.getUserReservesData(ADDRESSES_PROVIDER, msg.sender);
        return userData;
    }

    function _getUserData()
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
        return POOL.getUserAccountData(msg.sender);
    }

    function getUserData()
        external
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
        return POOL.getUserAccountData(msg.sender);
    }

    function _getHealthFactor() internal view returns (uint256) {
        (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            ,
            uint256 currentLiquidationThreshold,
            ,

        ) = _getUserData();

        uint256 HF = (totalCollateralBase.mul(currentLiquidationThreshold)).div(
            10000
        );

        return HF.div(1e18);
    }

    function buyInsurance() external {
        (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            ,
            ,

        ) = _getUserData();

        // require(totalDebtBase > 0, "Not borrow");

        uint healthFactor = _getHealthFactor();

        require(!isSecured[msg.sender], "You are already insured");
        //require(healthFactor > 1, "Position to liquidate");

        uint256 totalInsured = (totalCollateralBase.div(100)).div(2);

        // Transfer policy payment and fee

        usdcToken.transferFrom(msg.sender, address(this), pricePolicy);
        usdcToken.transferFrom(msg.sender, tresury, insuranceFee);

        // Mint PolicyNft
        uint256 tokenId = policyNFTContract.safeMint(msg.sender);

        idOwner[msg.sender] = tokenId;
        isSecured[msg.sender] = true;

        // Assign insurance details to the NFT
        nftData[tokenId] = NFTMetaData({
            totalLent: totalCollateralBase,
            totalBorrowed: totalDebtBase,
            borrowingLimit: availableBorrowsBase,
            health: healthFactor,
            totalInsured: totalInsured,
            owner: msg.sender
        });
    }

    // Function to claim insurance if the position is liquidated

    function claimInsurance() external {
        // como saber si el usuario esta liquidado

        uint idToken = idOwner[msg.sender];

        policyNFTContract.burn(idToken, msg.sender);
        NFTMetaData memory dataNft = nftData[idToken];
        uint256 total = dataNft.totalInsured;
        uint256 percentage2 = (total.mul(percentageFee)).div(10000);
        uint256 percentage98 = total - percentage2;

        usdcToken.approve(address(this), total);
        usdcToken.transferFrom(address(this), msg.sender, percentage98);

        usdcToken.transferFrom(address(this), tresury, percentage2);
        isSecured[msg.sender] = false;

        delete nftData[idToken];
        delete idOwner[msg.sender];
    }

    //function para ver la data del nft

    function getDataNft() external view returns (NFTMetaData memory) {
        uint idToken = idOwner[msg.sender];
        NFTMetaData memory dataNft = nftData[idToken];

        return dataNft;
    }

    // Función para cambiar la tarifa de seguro
    function setInsuranceFee(uint256 _newFee) external onlyOwner {
        insuranceFee = _newFee;
    }
}
