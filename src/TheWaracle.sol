//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IBookOfLore {
    function addLoreWithScribe(
        address tokenContract,
        uint256 tokenId,
        uint256 parentLoreId,
        bool nsfw,
        string memory loreMetadataURI
    ) external;
}

contract TheWaracle is ReentrancyGuard, Ownable {
    error TheWaracle__TokenContractNotOnAllowlist();
    error TheWaracle__TokenDoesNotExist();
    error TheWaracle__MustOwnTokenToFindEnemy();
    error ERC721NonexistentToken(); // For debugging

    struct Enemy {
        address enemyContract;
        uint256 enemyTokenId;
    }

    uint256 private constant WIZARDS_TOTAL_SUPPLY = 10000;
    uint256 private constant WARRIOR_TOTAL_SUPPLY = 16000;
    uint256 private constant WIZSOULWARRIOR_TOTAL_SUPPLY = 26000;
    address public enemyContract;
    uint256 public enemyTokenId;
    address private immutable i_wizardsAddress;
    address private immutable i_soulsAddress;
    address private immutable i_warriorsAddress;
    address private immutable i_bookOfLoreAddress;
    string public baseLoreURI;

    mapping(address tokenContract => mapping(uint256 tokenId => Enemy)) private enemies;
    mapping(address => bool) public waracleAllowlist;

    event EnemyFoundAndRecorded(address tokenContract, uint256 tokenId, address enemyContract, uint256 enemyTokenId);

    modifier onlyAllowedContract(address _tokenContract) {
        if (waracleAllowlist[_tokenContract] == false) {
            revert TheWaracle__TokenContractNotOnAllowlist();
        }
        _;
    }

    constructor(
        address _wizardsAddress,
        address _soulsAddress,
        address _warriorsAddress,
        address _bookOfLoreAddress,
        string memory _baseLoreURI
    ) Ownable(msg.sender) {
        i_wizardsAddress = _wizardsAddress;
        i_soulsAddress = _soulsAddress;
        i_warriorsAddress = _warriorsAddress;
        i_bookOfLoreAddress = _bookOfLoreAddress;
        setBaseLoreURI(_baseLoreURI);
    }

    function enemy(address _tokenContract, uint256 _tokenId)
        public
        onlyAllowedContract(_tokenContract)
        returns (address, uint256)
    {
        if (IERC721(_tokenContract).ownerOf(_tokenId) != msg.sender) {
            revert TheWaracle__MustOwnTokenToFindEnemy();
        }
        // Enemy already exists
        if ((enemies[_tokenContract][_tokenId]).enemyContract != address(0)) {
            enemyContract = (enemies[_tokenContract][_tokenId]).enemyContract;
            enemyTokenId = (enemies[_tokenContract][_tokenId]).enemyTokenId;
        } else {
            /* No enemy exists, find enemy */
            (enemyContract, enemyTokenId) = newEnemy(_tokenContract, _tokenId);
            /* Record new enemies in both directions */
            enemies[_tokenContract][_tokenId] = Enemy(enemyContract, enemyTokenId);
            enemies[enemyContract][enemyTokenId] = Enemy(_tokenContract, _tokenId);
            emit EnemyFoundAndRecorded(_tokenContract, _tokenId, enemyContract, enemyTokenId);
        }
        return (enemyContract, enemyTokenId);
    }

    function newEnemy(address _tokenContract, uint256 _tokenId)
        private
        view
        onlyAllowedContract(_tokenContract)
        returns (address _enemyContract, uint256 _enemyTokenId)
    {
        address owner;
        uint256 enemyNumber = _generateRandomNumber(_tokenId);
        // Now, with that random number, assign it to a token in wizards, souls, or warriors:
        if (enemyNumber <= WIZARDS_TOTAL_SUPPLY) {
            try IERC721(i_wizardsAddress).ownerOf(enemyNumber) returns (address _owner) {
                owner = _owner;
            } catch Error(string memory) /*reason*/ {
                /* Enemy is # of Wizard that HAS been burned -- return corresponding Soul */
                // errorAsIKnowIt = "ERC721NonexistentToken"; (Would love for someone to clarify why this...
                // ...doesn't work even though ERC721NonexistentToken is the error that is thrown in terminal)
                // require(_startsWith(reason, errorAsIKnowIt), "Unexpected ERC721 error");
                return (i_soulsAddress, enemyNumber);
            } catch (bytes memory) /*lowLevelData*/ {
                return (i_soulsAddress, enemyNumber);
            }
            if (owner != address(0)) {
                /* Enemy is # of Wizard that HAS NOT been burned */
                return (i_wizardsAddress, enemyNumber);
            }
        } else {
            /* Enemy is a Warrior */
            return (i_warriorsAddress, enemyNumber - WIZARDS_TOTAL_SUPPLY);
        }
    }

    function addLore(address _tokenContract, uint256 _tokenId, string memory _loreMetadataURI)
        public
        nonReentrant
        onlyAllowedContract(_tokenContract)
    {
        if (i_bookOfLoreAddress != address(0)) {
            IBookOfLore(i_bookOfLoreAddress).addLoreWithScribe(_tokenContract, _tokenId, 0, false, _loreMetadataURI);
        }
    }

    function setBaseLoreURI(string memory _baseLoreURI) public onlyOwner {
        baseLoreURI = _baseLoreURI;
    }

    function setWaracleAllowlist(address tokenContract) public onlyOwner {
        waracleAllowlist[tokenContract] = true;
    }

    // Not truly/provably random, but good enough for our purposes
    function _generateRandomNumber(uint256 seed) internal view returns (uint256) {
        uint256 offset = seed % 256;
        uint256 blockNumber = (block.number - offset);
        bytes32 blockHash = blockhash(blockNumber);
        return ((uint256(blockHash) % WIZSOULWARRIOR_TOTAL_SUPPLY) + 1);
    }

    // function _startsWith(bytes memory bytesFromError, bytes memory bytesIProvided) internal pure returns (bool) {
    //     // Check if the length of the input string is less than the length of the prefix
    //     if (bytesFromError.length < bytesIProvided.length) {
    //         return false;
    //     }
    //     // Iterate through each character of the prefix
    //     for (uint256 i = 0; i < bytesIProvided.length; i++) {
    //         // Check if the current character of input string matches the corresponding character of prefix
    //         if (bytesFromError[i] != bytesIProvided[i]) {
    //             return false; // If not, the input string does not start with the prefix
    //         }
    //     }
    //     return true; // If all characters match, the input string starts with the prefix
    // }

    function getEnemies(address _tokenContract, uint256 _tokenId) public view returns (address, uint256) {
        return ((enemies[_tokenContract][_tokenId]).enemyContract, (enemies[_tokenContract][_tokenId]).enemyTokenId);
    }

    function getWaracleAllowList(address _tokenContract) public view returns (bool) {
        return waracleAllowlist[_tokenContract];
    }
}
