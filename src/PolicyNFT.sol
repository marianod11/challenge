// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract PolicyNFT is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    address policyAddress;

    event Attest(address indexed to, uint256 indexed tokenId);
    event Revoke(address indexed to, uint256 indexed tokenId);

    constructor() ERC721("PolicyNFT", "pNFT") {}

    modifier onlyContractPolicy() {
        require(policyAddress == msg.sender);
        _;
    }

    function safeMint(address to) public onlyContractPolicy returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        _tokenIdCounter.increment();
        return tokenId;
    }

    function burn(uint256 tokenId, address _user) external onlyContractPolicy {
        require(
            ownerOf(tokenId) == _user,
            "Only owner of the token can burn it"
        );
        _burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256,
        uint256
    ) internal pure override {
        require(
            from == address(0) || to == address(0),
            "Not allowed to transfer token"
        );
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256
    ) internal override {
        if (from == address(0)) {
            emit Attest(to, tokenId);
        } else if (to == address(0)) {
            emit Revoke(to, tokenId);
        }
    }

    function setPolicyAddress(address _addressPolicy) external onlyOwner {
        policyAddress = _addressPolicy;
    }
}
