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
     * @dev Constructor del contrato Challenge
     * @param _usdcToken Dirección del contrato del token USDC
     * @param _addressProvider Dirección del proveedor de direcciones del mercado
     * @param _IUiPoolDataProviderV3 Dirección del contrato de datos del usuario del pool
     * @param _tresury Dirección de la tesorería
     * @param _policyNFTContract Dirección del contrato de tokens no fungibles de pólizas
     * @param _insuranceFee Tarifa de seguro inicial
     */
    constructor(
        address _usdcToken,
        address _addressProvider,
        address _IUiPoolDataProviderV3,
        address _tresury,
        address _policyNFTContract,
        uint256 _insuranceFee //   address _governor,
    ) {
        usdcToken = IERC20(_usdcToken);
        ADDRESSES_PROVIDER = IPoolAddressesProvider(_addressProvider);
        POOL = IPool(ADDRESSES_PROVIDER.getPool());
        POOLDATAUSER = IUiPoolDataProviderV3(_IUiPoolDataProviderV3);
        tresury = _tresury;
        policyNFTContract = PolicyNFT(_policyNFTContract);
        insuranceFee = _insuranceFee;
        // governor = _governor;
    }

    /**
     * @dev Devuelve la información de todas las posiciones del usuario .
     * @param _user La dirección del usuarios.
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
    * @dev Obtiene los datos de estado de las reservas del usuario.
    * @param _user La dirección del usuario .
    * @return totalCollateralBase Total de colateral depositado por el usuario.
    * @return totalDebtBase Total de deuda del usuario.
    * @return availableBorrowsBase Límite de préstamo disponible para el usuario.
    * @return currentLiquidationThreshold Umbral actual de liquidación del usuario.
    * @return ltv Relación préstamo-valor (LTV) del usuario.
    * @return healthFactor Factor de salud financiera del usuario.
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
     * @dev Obtiene el Health Factor de un usuario.
     * @param _user La dirección del usuario .
     * @return El Health Factor del usuario.
     */
    function _getHealthFactor(address _user) internal view returns (uint256) {
        (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            ,
            uint256 currentLiquidationThreshold,
            ,

        ) = _getUserData(_user);

        uint256 HF = (totalCollateralBase * currentLiquidationThreshold) /
            totalDebtBase;

        return HF.div(1e18);
    }

    /**
     * @dev Permite a un usuario comprar una póliza .
     * @param _user La dirección del usuario.
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
     * @dev Permite a un usuario reclamar el pago de la póliza de seguro si su posición se liquida.
     * @param _user La dirección del usuario .
     */
    function claimInsurance(address _user) external {
        // como saber si el usuario esta liquidado

        uint idToken = idOwner[_user];

        policyNFTContract.burn(idToken, _user);
        NFTMetaData memory dataNft = nftData[idToken];
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
     * @dev Obtiene los datos de una póliza de seguro asociada a un usuario.
     * @param _user La dirección del usuario para consultar los datos de su póliza.
     * @return  NFTMetaData.
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
