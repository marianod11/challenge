// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {PolicyNFT} from "../src/PolicyNFT.sol";

contract PolicyNFTTest is Test {
    PolicyNFT public policyNFT;

    function setUp() public {
        policyNFT = new PolicyNFT("http://ipfs/");
    }

    function test_Mint() public {
        vm.expectRevert("Only contract Policy");
        policyNFT.safeMint(msg.sender);
    }



    function test_burn() public {
        vm.expectRevert("Only contract Policy");
        policyNFT.burn(0, msg.sender);
    }

    function test_set_address() public {
        address newAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        policyNFT.setPolicyAddress(newAddress);
        assertEq(newAddress, policyNFT.policyAddress());
    }

    function test_set_token_uri() public {
        string memory uri = "https://example.ipfs";
        policyNFT.setTokenUri(uri);
        assertEq(uri, policyNFT.baseURI());
    }
}
