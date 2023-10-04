// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

import {Challenge} from "../src/Challenge.sol";
import {USDCToken} from "../src/USDCToken.sol";
import {PolicyNFT} from "../src/PolicyNFT.sol";

contract ScriptChallenge is Script {
    function setUp() public {}

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address account = vm.addr(privateKey);

        address providerAddress = 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb;
        address poolDataProvider = 0x145dE30c929a065582da84Cf96F88460dB9745A7;

        console.log("Account", account);

        vm.startBroadcast(privateKey);

        USDCToken usdcToken = new USDCToken(
            "USDC",
            "USDC",
            6,
            1000000000000e6,
            account,
            account
        );

        console.log(address(usdcToken));

        PolicyNFT policyNFT = new PolicyNFT("http://ipfs/");


        Challenge challenge = new Challenge(
            address(usdcToken),
            providerAddress,
            poolDataProvider,
            msg.sender,
            address(policyNFT),
            10e6
        );

        console.log(address(challenge));

        policyNFT.setPolicyAddress(address(challenge));

        vm.stopBroadcast();
    }
}
