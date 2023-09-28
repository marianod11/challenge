# Challenge Technical Documentation

## Introduction

The project includes a series of contracts necessary to allow users to purchase insurance policies in the form of NFTs and claim them in case their positions in the Aave protocol are liquidated. Below is technical documentation describing the main features.

## Architecture

The project includes:

- **Interfaces**: a folder where the necessary interfaces for operation are stored.
- **Challenge.sol**: contains the logic for purchasing policies, claiming policies, and viewing user position and NFT information.
- **GovernorPolicy.sol**: Governable contract of the project.
- **MarketInteractions.sol**: a contract used to simulate an environment of the Aave protocol.
- **PolicyNFT.sol**: NFT contract representing policies, it is soul-bound, and complies with OpenSea requirements.
- **USDCToken**: fake USDC token.

## Challenge Contract Structure

The "Challenge" contract is structured as follows:

- It uses contracts imported from OpenZeppelin:

  - `@openzeppelin/contracts/token/ERC20/IERC20.sol`
  - `@openzeppelin/contracts/token/ERC721/ERC721.sol`
  - `@openzeppelin/contracts/access/Ownable.sol`
  - `@openzeppelin/contracts/utils/math/SafeMath.sol`

- Defines important state variables such as:

  - **usdcToken**: address of the fake USDC contract.
  - **insuranceFee**: fee for purchasing policies.
  - **claimFee**: percentage of fee for the claim.
  - **treasury**: address where fees go.
  - **governor**: governor's address.

- It has environment variables related to the Aave protocol.
- It has a data structure `NFTMetaData` to store metadata related to insurance policies.
- Defines mappings to track information about token owners and whether they are insured.
- Implements public functions for purchasing and claiming insurance policies, as well as getting user position information and changing the insurance fee.

## Main Functions

The main functions of the contract are described below:

- `allUserPositions(address _user)`: returns all user positions.

- `buyInsurance(address _user)`: Allows a user to purchase an insurance policy if they meet certain requirements, such as having taken out a loan and having a health factor greater than 1. The insurance policy prices depend on the healthFactor, varying in two prices, it is transferred to the contract and the treasury. Then it is minted, and the information is stored in the NFT data.

### Personal rating

I hope that I was able to meet most of the requirements, my idea was to make a contact, which allows the purchase of insurance policies for users who have already carried out an action of requesting a loan in the aave protocol, since it is there Where their liquidity is at risk, I put security so that only these can buy.
After collecting the policy, I am never quite sure how a user will find out that they have been liquidated, without going outside the blockchain. I put some verification so that it can be done.
As for the tests, sometimes the aave environment has a flaw, mostly in the issue of requesting loans, but the idea works.

I hope you like the work and we can get to another interview so you can better explain what I wanted to do in this challenge.

Greetings.

Mariano Dell Aquila
