//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {NftMockContract} from "../../test/mocks/NftMockContract.sol";
import {SoulMockContract} from "../../test/mocks/SoulMockContract.sol";
import {BookOfLoreMock} from "../../test/mocks/BookOfLoreMock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address wizardsAddress;
        address soulsAddress;
        address warriorsAddress;
        address bookOfLoreAddress;
        string baseLoreURI;
    }

    string _baseLoreURI = "https://api.deadsecrets.io/lore/";
    NetworkConfig public activeNetworkConfig;
    NftMockContract wizMockContract;
    SoulMockContract soulsMockContract;
    NftMockContract warriorsMockContract;
    BookOfLoreMock bookOfLoreMockContract;

    modifier nftContractsDeployed() {
        vm.startBroadcast();
        wizMockContract = new NftMockContract("Wizard", "WIZ");
        soulsMockContract = new SoulMockContract("Souls", "SOUL");
        warriorsMockContract = new NftMockContract("Warriors", "WARRIOR");
        bookOfLoreMockContract = new BookOfLoreMock();
        vm.stopBroadcast();
        _;
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        }
        if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public nftContractsDeployed returns (NetworkConfig memory) {
        return NetworkConfig({
            wizardsAddress: address(wizMockContract),
            soulsAddress: address(soulsMockContract),
            warriorsAddress: address(warriorsMockContract),
            bookOfLoreAddress: address(bookOfLoreMockContract),
            baseLoreURI: _baseLoreURI
        });
    }

    function getMainnetEthConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            wizardsAddress: 0x521f9C7505005CFA19A8E5786a9c3c9c9F5e6f42,
            soulsAddress: 0x251b5F14A825C537ff788604eA1b58e49b70726f,
            warriorsAddress: 0x9690b63Eb85467BE5267A3603f770589Ab12Dc95,
            bookOfLoreAddress: 0x4218948D1Da133CF4B0758639a8C065Dbdccb2BB,
            baseLoreURI: _baseLoreURI
        });
    }

    function getOrCreateAnvilEthConfig() public nftContractsDeployed returns (NetworkConfig memory) {
        if (activeNetworkConfig.wizardsAddress != address(0)) {
            return activeNetworkConfig;
        }

        return NetworkConfig({
            wizardsAddress: address(wizMockContract),
            soulsAddress: address(soulsMockContract),
            warriorsAddress: address(warriorsMockContract),
            bookOfLoreAddress: address(bookOfLoreMockContract),
            baseLoreURI: _baseLoreURI
        });
    }
}
