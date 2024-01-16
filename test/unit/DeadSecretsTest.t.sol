//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeadSecrets} from "../../src/DeadSecrets.sol";
import {DeployDeadSecrets} from "../../script/DeployDeadSecrets.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {NftMockContract} from "../mocks/NftMockContract.sol";
import {SoulMockContract} from "../mocks/SoulMockContract.sol";
import {BookOfLoreMock} from "../../test/mocks/BookOfLoreMock.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DeadSecretsTest is Test {
    error DeadSecrets__TokenContractNotOnAllowlist();
    error DeadSecrets__MustOwnTokenToFindEnemy();
    error DeadSecretsTest__Failed();

    event logString(string log);

    DeadSecrets deadSecrets;
    HelperConfig helperConfig;
    NftMockContract wizMockContract;
    SoulMockContract soulsMockContract;
    NftMockContract warriorsMockContract;
    BookOfLoreMock bookOfLoreMockContract;

    address wizardsAddress;
    address soulsAddress;
    address warriorsAddress;
    address bookOfLoreAddress;
    string baseLoreURI;

    uint256 private constant WIZARDS_TOTAL_SUPPLY = 10000;
    uint256 private constant WARRIOR_TOTAL_SUPPLY = 16000;
    uint256 private constant WIZSOULWARRIOR_TOTAL_SUPPLY = 26001;
    address PLAYER1 = makeAddr("player1");
    address PLAYER2 = makeAddr("player2");
    address PLAYER3 = makeAddr("player3");
    address PLAYER4 = makeAddr("player4");
    address RANDOM_CONTRACT = makeAddr("randomContract");
    uint256[] soulTokenIds = new uint256[](1499);

    modifier soulTokensPrepared() {
        uint256 index = 0;
        for (uint256 i = 2; i < 3000; i += 2) {
            soulTokenIds[index] = i;
            index++;
        }
        _; // ALL EVEN WIZARDS < 3000 TURN TO SOULS
    }

    modifier allNftsMinted() {
        for (uint256 i = 1; i <= 3333; i++) {
            vm.prank(PLAYER1);
            (NftMockContract(wizardsAddress)).mintNft();
        }
        for (uint256 i = 3334; i <= 6666; i++) {
            vm.prank(PLAYER2);
            (NftMockContract(wizardsAddress)).mintNft();
        }
        for (uint256 i = 6667; i <= 10000; i++) {
            vm.prank(PLAYER3);
            (NftMockContract(wizardsAddress)).mintNft();
        }
        for (uint256 i = 1; i <= 4000; i++) {
            vm.prank(PLAYER1);
            (NftMockContract(warriorsAddress)).mintNft();
        }
        for (uint256 i = 4001; i <= 8000; i++) {
            vm.prank(PLAYER2);
            (NftMockContract(warriorsAddress)).mintNft();
        }
        for (uint256 i = 8001; i <= 12000; i++) {
            vm.prank(PLAYER3);
            (NftMockContract(warriorsAddress)).mintNft();
        }
        for (uint256 i = 12001; i <= 16000; i++) {
            vm.prank(PLAYER4);
            (NftMockContract(warriorsAddress)).mintNft();
        }
        for (uint256 i = 0; i < soulTokenIds.length; i++) {
            vm.prank(PLAYER1);
            IERC721(wizardsAddress).approve(address(soulsAddress), soulTokenIds[i]);
            vm.prank(PLAYER1);
            (SoulMockContract(soulsAddress)).burnAndMint(wizardsAddress, soulTokenIds[i]);
        }
        _;
    }

    modifier timePassed() {
        vm.warp(block.timestamp + 4555556566567657575);
        vm.roll(block.number + 4555556566567657575);
        _;
    }

    function setUp() public {
        DeployDeadSecrets deployer = new DeployDeadSecrets();
        (deadSecrets, helperConfig) = deployer.run();
        (wizardsAddress, soulsAddress, warriorsAddress, bookOfLoreAddress, baseLoreURI) =
            helperConfig.activeNetworkConfig();

        vm.startPrank(deadSecrets.owner());
        deadSecrets.setDeadSecretsAllowlist(wizardsAddress);
        deadSecrets.setDeadSecretsAllowlist(soulsAddress);
        deadSecrets.setDeadSecretsAllowlist(warriorsAddress);
        vm.stopPrank();

        wizMockContract = new NftMockContract("Wizard", "WIZ");
        soulsMockContract = new SoulMockContract("Souls", "SOUL");
        warriorsMockContract = new NftMockContract("Warriors", "WARRIOR");
        bookOfLoreMockContract = new BookOfLoreMock();

        vm.startPrank(BookOfLoreMock(bookOfLoreAddress).owner());
        BookOfLoreMock(bookOfLoreAddress).setScribeAllowlist(address(deadSecrets), true);
        BookOfLoreMock(bookOfLoreAddress).setLoreTokenAllowlist(wizardsAddress, true);
        BookOfLoreMock(bookOfLoreAddress).setLoreTokenAllowlist(soulsAddress, true);
        BookOfLoreMock(bookOfLoreAddress).setLoreTokenAllowlist(warriorsAddress, true);
        vm.stopPrank();
    }

    function testRevertsIfNotOnAllowList() public {
        vm.expectRevert(DeadSecrets.DeadSecrets__TokenContractNotOnAllowlist.selector);
        vm.prank(PLAYER1);
        deadSecrets.enemy(RANDOM_CONTRACT, 1);
    }

    function testPlayerOneHasAnNft() public soulTokensPrepared allNftsMinted {
        address shouldBePlayerOne = NftMockContract(wizardsAddress).ownerOf(333);
        assertEq(shouldBePlayerOne, PLAYER1);
    }

    function testSoulNftsMintCorrectly() public soulTokensPrepared allNftsMinted {
        address shouldBePlayerOne = SoulMockContract(soulsAddress).ownerOf(soulTokenIds[0]);
        assertEq(shouldBePlayerOne, PLAYER1);
        assertEq(SoulMockContract(soulsAddress).balanceOf(PLAYER1), soulTokenIds.length);
    }

    ///////////////////////////
    // Test setUp is correct //
    ///////////////////////////
    function testDeadSecretsAllowList() public {
        assertEq(deadSecrets.deadSecretsAllowlist(wizardsAddress), true);
        assertEq(deadSecrets.deadSecretsAllowlist(soulsAddress), true);
        assertEq(deadSecrets.deadSecretsAllowlist(warriorsAddress), true);
    }

    ///////////////////////////
    //  onlyOwner functions  //
    ///////////////////////////
    function testSetDeadSecretsAsOtherThanOwner() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, PLAYER2));
        vm.prank(PLAYER2); // Player 2 is not the owner
        deadSecrets.setDeadSecretsAllowlist(RANDOM_CONTRACT);
    }

    ///////////////////////////
    //    enemy() function   //
    ///////////////////////////
    function testFindAndStoreEnemyForAWizToken() public soulTokensPrepared allNftsMinted timePassed {
        vm.prank(PLAYER1);
        (address enemyContract, uint256 enemyTokenId) = deadSecrets.enemy(wizardsAddress, 1);
        vm.prank(PLAYER1);
        (address enemyContract2, uint256 enemyTokenId2) = deadSecrets.getEnemies(wizardsAddress, 1);
        assertEq(enemyContract, enemyContract2);
        assertEq(enemyTokenId, enemyTokenId2);
    }

    function testFindAndStoreEnemyBothDirections() public soulTokensPrepared allNftsMinted timePassed {
        vm.prank(PLAYER1);
        (address enemyContract, uint256 enemyTokenId) = deadSecrets.enemy(wizardsAddress, 1);
        vm.prank(PLAYER1);
        (address shouldBeWizAddress, uint256 shouldBeWizTokenId) = deadSecrets.getEnemies(enemyContract, enemyTokenId);
        assertEq(wizardsAddress, shouldBeWizAddress);
        assertEq(1, shouldBeWizTokenId);
    }

    function testFindAndStoreEnemyForASoulToken() public soulTokensPrepared allNftsMinted timePassed {
        vm.prank(PLAYER1);
        (address enemyContract, uint256 enemyTokenId) = deadSecrets.enemy(soulsAddress, soulTokenIds[0]);
        vm.prank(PLAYER1);
        (address enemyContract2, uint256 enemyTokenId2) = deadSecrets.getEnemies(soulsAddress, soulTokenIds[0]);
        assertEq(enemyContract, enemyContract2);
        assertEq(enemyTokenId, enemyTokenId2);
    }

    function testFindEnemyForNonExistantSoul() public soulTokensPrepared allNftsMinted timePassed {
        vm.expectRevert();
        vm.prank(PLAYER1);
        deadSecrets.enemy(soulsAddress, 4111);
    }

    function testFindAndStoreEnemyForAWarriorToken() public soulTokensPrepared allNftsMinted timePassed {
        vm.prank(PLAYER1);
        (address enemyContract, uint256 enemyTokenId) = deadSecrets.enemy(warriorsAddress, 3999);
        vm.prank(PLAYER1);
        (address enemyContract2, uint256 enemyTokenId2) = deadSecrets.getEnemies(warriorsAddress, 3999);
        assertEq(enemyContract, enemyContract2);
        assertEq(enemyTokenId, enemyTokenId2);
    }

    function testEnemyRevertsIfNotOwnerOfToken() public soulTokensPrepared allNftsMinted timePassed {
        vm.expectRevert(DeadSecrets.DeadSecrets__MustOwnTokenToFindEnemy.selector);
        vm.prank(PLAYER2);
        deadSecrets.enemy(wizardsAddress, 11);
    }

    function testVerifySomeEnemiesEndUpSouls() public soulTokensPrepared allNftsMinted timePassed {
        uint256 numberOfSouls = 0;
        for (uint256 i = 1; i < 500; i++) {
            vm.warp(block.timestamp + 334567);
            vm.roll(block.number + 17000);
            vm.prank(PLAYER1);
            (address enemyContract,) = deadSecrets.enemy(warriorsAddress, i);
            if (enemyContract == soulsAddress) {
                numberOfSouls++;
            }
        }
        assert(numberOfSouls > 0);
    }

    function testVerifySomeEnemiesEndUpWizards() public soulTokensPrepared allNftsMinted timePassed {
        uint256 numberOfWizards = 0;
        for (uint256 i = 1; i < 500; i++) {
            vm.warp(block.timestamp + 334567);
            vm.roll(block.number + 17000);
            vm.prank(PLAYER1);
            (address enemyContract,) = deadSecrets.enemy(warriorsAddress, i);
            if (enemyContract == wizardsAddress) {
                numberOfWizards++;
            }
        }
        assert(numberOfWizards > 0);
    }

    function testVerifySomeEnemiesEndUpWarriors() public soulTokensPrepared allNftsMinted timePassed {
        uint256 numberOfWarriors = 0;
        for (uint256 i = 1; i < 500; i++) {
            vm.warp(block.timestamp + 334567);
            vm.roll(block.number + 17000);
            vm.prank(PLAYER1);
            (address enemyContract,) = deadSecrets.enemy(warriorsAddress, i);
            if (enemyContract == warriorsAddress) {
                numberOfWarriors++;
            }
        }
        assert(numberOfWarriors > 0);
    }

    ///////////////////////////
    //  addLore() function   //
    ///////////////////////////
    function testAddLore() public soulTokensPrepared allNftsMinted timePassed {
        uint256 tokenId = 5;
        address owner = NftMockContract(wizardsAddress).ownerOf(tokenId);
        vm.prank(owner, owner);
        deadSecrets.addLore(wizardsAddress, tokenId, "testLore");
        assertEq(BookOfLoreMock(bookOfLoreAddress).numLore(wizardsAddress, tokenId), 1);
    }
}
