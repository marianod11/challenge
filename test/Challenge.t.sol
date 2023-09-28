// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import {Test, console2} from "forge-std/Test.sol";
import {Challenge} from "../src/Challenge.sol";
import {USDCToken} from "../src/USDCToken.sol";
import {PolicyNFT} from "../src/PolicyNFT.sol";
import {MarketInteractions} from "../src/MarketInteractions.sol";

interface IWETH {
    function balanceOf(address) external view returns (uint256);

    function deposit() external payable;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract ChallengeTest is Test {
    Challenge public challenge;
    USDCToken public usdc;
    PolicyNFT public policyNFT;
    MarketInteractions public marketInteractions;
    IWETH public weth;

    function setUp() public {
        address providerAddress = 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb;
        address poolDataProvider = 0x145dE30c929a065582da84Cf96F88460dB9745A7;

        policyNFT = new PolicyNFT("http://ipfs/");
        marketInteractions = new MarketInteractions(
            providerAddress,
            poolDataProvider
        );
        weth = IWETH(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
        usdc = new USDCToken(
            "USDC",
            "USDC",
            6,
            1000000000000e6,
            address(this),
            address(this)
        );
        challenge = new Challenge(
            address(usdc),
            providerAddress,
            poolDataProvider,
            msg.sender,
            address(policyNFT),
            10e6
        );

        policyNFT.setPolicyAddress(address(challenge));
    }

    function test_buy_polizy_fail_not_borrow_yes_supply() public {
        weth.deposit{value: 100e18}();

        uint256 balAfter = weth.balanceOf(address(this));
        weth.approve(address(marketInteractions), balAfter);
        marketInteractions.supplyLiquidity(10e18, address(this));

        vm.expectRevert("You haven't borrowed");
        challenge.buyInsurance(address(this));
    }

    function test_buy_polizy_borrow_yes() public {
        weth.deposit{value: 100e18}();

        uint256 balAfter = weth.balanceOf(address(this));
        weth.approve(address(marketInteractions), balAfter);
        marketInteractions.supplyLiquidity(10e18, address(this));
        address dai = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
        marketInteractions.borrowWETH(500e18, dai, address(this));

        challenge.buyInsurance(address(this));
        uint balance = policyNFT.balanceOf(address(this));
        assertEq(balance, 1);
    }

    function test_buy_polizy_tranfer_soul_bound() public {
        weth.deposit{value: 100e18}();

        uint256 balAfter = weth.balanceOf(address(this));
        weth.approve(address(marketInteractions), balAfter);
        marketInteractions.supplyLiquidity(10e18, address(this));
        address dai = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
        marketInteractions.borrowWETH(500e18, dai, address(this));

        challenge.buyInsurance(address(this));

        vm.expectRevert("Not allowed to transfer token");
        policyNFT.transferFrom(msg.sender, address(this), 0);

        uint balance = policyNFT.balanceOf(address(this));
        assertEq(balance, 1);
    }

    function test_claim_insurance() public {
        weth.deposit{value: 100e18}();

        uint256 balAfter = weth.balanceOf(address(this));
        weth.approve(address(marketInteractions), balAfter);
        marketInteractions.supplyLiquidity(10e18, address(this));
        address dai = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
        marketInteractions.borrowWETH(500e18, dai, address(this));

        challenge.buyInsurance(address(this));

        marketInteractions.borrowWETH(12000e18, dai, address(this));

        uint balance = policyNFT.balanceOf(address(this));
        assertEq(balance, 1);

        challenge.claimInsurance(address(this));

        uint balanceBefore = policyNFT.balanceOf(address(this));
        assertEq(balanceBefore, 0);
    }

    function test_set_fee() public {
        uint newFee = 5e6;
        challenge.setInsuranceFee(newFee);
        assertEq(newFee, challenge.insuranceFee());
    }
}
