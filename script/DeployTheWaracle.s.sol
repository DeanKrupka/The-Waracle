//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {TheWaracle} from "../src/TheWaracle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployTheWaracle is Script {
    function run() external returns (TheWaracle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            address wizardsAddress,
            address soulsAddress,
            address warriorsAddress,
            address bookOfLoreAddress,
            string memory baseLoreURI
        ) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        TheWaracle theWaracle =
            new TheWaracle(wizardsAddress, soulsAddress, warriorsAddress, bookOfLoreAddress, baseLoreURI);
        vm.stopBroadcast();
        return (theWaracle, helperConfig);
    }
}
