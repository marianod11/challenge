# Documentación Técnica del Challenge

## Introducción

El proyecto cuenta con una serie de contratos necesarios para pode permitir a los usuarios a comprar pólizas de seguro en forma de NFT y reclamarlas en caso de que sus posiciones en el protocolo Aave sean liquidadas. A continuación, se presenta una documentación técnica que describe las principales características .

## Arquitectura

El proyecto cuenta, con los contratos:

- **Interfaces** : carpeta donde se guardan las interfaces necesarias para el funcionamiento.
- **Challenge.sol**: tiene la logica de compra de polizas, el reclamo de polizas, y para visualizar la informacion de sus posiciones, y nft.
- **GovernorPolicy.sol**: contrato Governable del proyecto.
- **MarketInteractions.sol**: contrato que lo use para simular un ambiente del protocolo Aave.
- **PolicyNFT.sol**: Contrato NFT que representas las polizas, esta soul-bound, y cumple los requisitos de Open-sea.
- **USDCToken**: token USDC fake.

## Estructura del Contrato Challenge

El contrato "Challenge" está estructurado de la siguiente manera:

- Utiliza contratos importados de OpenZeppelin

  - `@openzeppelin/contracts/token/ERC20/IERC20.sol`
  - `@openzeppelin/contracts/token/ERC721/ERC721.sol`
  - `@openzeppelin/contracts/access/Ownable.sol`
  - `@openzeppelin/contracts/utils/math/SafeMath.sol`

- Define variables de estado importantes como

  - **usdcToken**: address contracto USDC fake.
  - **insuranceFee**: fee para la compro de polizas.
  - **claimFee**: porcetaje de fee para el cliam.
  - **tresury**: address a donde van los fee.
  - **governor**: address governor.

- Tiene las variables de entorno relacionas al protocolo Aave.
- Tiene una estructura de datos `NFTMetaData` para almacenar metadatos relacionados con las pólizas de seguro.
- Define mapeos para rastrear información de los propietarios de tokens y si están asegurados.
- Implementa funciones públicas para la compra y reclamo de pólizas de seguro, así como para obtener información sobre la posición del usuario y cambiar la tarifa de seguro.

## Funciones Principales

A continuación, se describen las principales funciones del contrato:

- `allUserPositions(address _user)`: devuelve todas las posiciones del usuario .

- `buyInsurance(address _user)`: Permite a un usuario comprar una póliza de seguro si cumple con ciertos requisitos, como haber pedido algun préstamo y tener un factor de salud mayor a 1. Los precios de la poliza de seguro es dependiendo el healthFactor, variando en dos precios, se tranfiere al contrato y al tesoreria. Luego se mintea y se guarda la informacion en la data del NFT.

- `claimInsurance(address _user)`: Permite a un usuario reclamar una póliza de seguro si su posición es liquidada.Se burnea el Nft. Se transfieren fondos al usuario y a la tesoreria. Y si elimina toda la data del NFT.

- `function _getUserData(address _user)`: funcion para obtener las reservas del usuario.

- `function _getHealthFactor(address _user)`: function para calcular el HealthFactor del usuario.

- `getDataNft(address _user)`: Devuelve los metadatos asociados con la póliza de seguro de un usuario.

- `setInsuranceFee(uint256 _newFee)`: Permite al propietario del contrato cambiar la tarifa de seguro.

## Estructura del Contrato NFT (PolicyNFT)

El contrato "PolicyNFT" se estructura de la siguiente manera:

- Utiliza la biblioteca `Counters` para gestionar contadores de tokens.
- Implementa el estándar ERC-721 para la creación y gestión de NFT.
- Hereda la funcionalidad del contrato "Ownable" de OpenZeppelin, lo que permite establecer un propietario del contrato.
- Las funciones `_beforeTokenTransfer()` y `_afterTokenTransfer()` estan modificados para que NFT quede soul-bound .

## USO

#### Get Started

Instalar OpenZeppelin

- `forge install Openzeppelin/openzeppelin-contracts`

En la carpeta test, estan realizados casos, donde se simula un ambiente y asi poder probar las funcionabilidades.

Comando para correr los test en un fork de arbitrum:

- `forge test --fork-url https://arbitrum-mainnet.infura.io/v3/90b9c25b2643401bbc837156b08c7e8`
