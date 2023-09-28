// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PolicyNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    address public policyAddress;

    string public baseURI;
    string public baseExtension = ".json";

    event Attest(address indexed to, uint256 indexed tokenId);
    event Revoke(address indexed to, uint256 indexed tokenId);

    constructor(string memory _uri) ERC721("PolicyNFT", "pNFT") {
        baseURI = _uri;
    }

    modifier onlyContractPolicy() {
        require(policyAddress == msg.sender, "Only contract Policy");
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

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = baseURI;
        uint256 idIpfs = tokenId;

        return
            string(
                abi.encodePacked(
                    currentBaseURI,
                    idIpfs.toString(),
                    baseExtension
                )
            );
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

    function setTokenUri(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }
}
