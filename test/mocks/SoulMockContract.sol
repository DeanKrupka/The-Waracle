//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Burnable is IERC721 {
    function burn(uint256 tokenId) external;
}

contract SoulMockContract is ERC721, ERC721Burnable, Ownable {
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    function burnAndMint(address _tokenContract, uint256 _tokenId) public {
        // burn the wizardToken :(
        IERC721Burnable(_tokenContract).burn(_tokenId);
        // mint a new soulToken :)
        _safeMint(_msgSender(), _tokenId);
    }
}
