// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Challenge is ERC721Enumerable, Ownable {

    IERC20 public usdcToken;

    uint256 public insuranceFee;
    uint256 public claimFee;

    address public oracle;

    ILendingPoolAddressesProvider public provider;
    ILendingPool public lendingPool;

    struct NFTMetaData {
        uint256 sizeOfLent;
        uint256 sizeOfBorrow;
        uint256 totalInsured;
        address tokenAddress;
    }

    mapping(uint256 => NFTMetaData) public nftData;

    event InsurancePurchased(
        address indexed owner,
        uint256 tokenId,
        uint256 loanPositionId,
        uint256 premiumAmount
    );
    event ClaimedInsurance(
        address indexed owner,
        uint256 tokenId,
        uint256 insuredAmount
    );

    constructor(
        string memory _name,
        string memory _symbol,
        address _usdcToken,
        uint256 _insuranceFee,
        uint256 _claimFee,
        address _oracle
        address _providerAddress
    ) ERC721(_name, _symbol) {
        usdcToken = IERC20(_usdcToken);
        insuranceFee = _insuranceFee;
        claimFee = _claimFee;
        oracle = _oracle;
        provider = ILendingPoolAddressesProvider(_providerAddress);
        lendingPool = ILendingPool(provider.getLendingPool());
    }


    function getUserPositions(address _user) external view returns (uint256[] memory) {
        address[] memory assets = lendingPool.getReservesList();
        uint256[] memory userPositions = new uint256[](assets.length);

        for (uint256 i = 0; i < assets.length; i++) {
            // Obtener el saldo depositado
            (uint256 userDepositBalance, , ) = lendingPool.getUserReserveData(assets[i], _user);
            userPositions[i] = userDepositBalance;
        }

        return userPositions;
    }









    function buyInsurance(uint256 _loanPositionId) external {
        // Verifica que la posición de préstamo sea válida y que el usuario pague la tarifa de seguro

        // Transfiere tokens USDC como prima de seguro al contrato

        // Crea un nuevo NFT como póliza de seguro
        uint256 tokenId = totalSupply() + 1;
        _mint(msg.sender, tokenId);

        //consulta al oraculo

        // Asigna los detalles del seguro al NFT
        nftData[tokenId] = NFTMetaData({
            loanPositionId: _loanPositionId,
            sizeOfBorrow: 0,
            isLiquidated: false
        });

        emit InsurancePurchased(
            msg.sender,
            tokenId,
            _loanPositionId,
            insuranceFee
        );
    }

    // Función para consultar la posición del usuario en el protocolo
    function getPositionDetails(
        uint256 _tokenId /* Detalles de la posición */
    ) external view returns () {
        // Implementa la lógica para consultar la posición en el protocolo
    }

    // Función para reclamar seguro si la posición es liquidada
    function claimInsurance(uint256 _tokenId) external {
        // Verifica si la posición está liquidada y que el usuario pague la tarifa de reclamación

        // Transfiere tokens USDC como pago de reclamación al usuario

        // Quema el NFT
        _burn(_tokenId);

        emit ClaimedInsurance(
            msg.sender,
            _tokenId,
            nftDetails[_tokenId].insuredAmount
        );
    }

    // Función para actualizar los detalles del seguro en el NFT
    function _updateInsuranceDetails(
        uint256 _tokenId,
        uint256 _insuredAmount,
        bool _isLiquidated
    ) internal {
        // Actualiza los detalles del seguro en el NFT
        nftDetails[_tokenId].insuredAmount = _insuredAmount;
        nftDetails[_tokenId].isLiquidated = _isLiquidated;
    }

    // Función para cambiar la tarifa de seguro
    function setInsuranceFee(uint256 _newFee) external onlyOwner {
        insuranceFee = _newFee;
    }

    // Función para cambiar la tarifa de reclamación
    function setClaimFee(uint256 _newFee) external onlyOwner {
        claimFee = _newFee;
    }

    // Función para cambiar la dirección del contrato de oráculo
    function setoracle(address _newOracle) external onlyOwner {
        oracle = _newOracle;
    }

    // Función para consultar el estado de salud de la posición utilizando el contrato de oráculo
    function checkPositionHealth(
        uint256 _loanPositionId
    ) internal view returns (bool) {
        // Implementa la lógica para verificar el estado de salud de la posición
    }
}
