//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {DeadSecrets} from "../src/DeadSecrets.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployDeadSecrets is Script {
    function run() external returns (DeadSecrets, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            address wizardsAddress,
            address soulsAddress,
            address warriorsAddress,
            address bookOfLoreAddress,
            string memory baseLoreURI
        ) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        DeadSecrets deadSecrets =
            new DeadSecrets(wizardsAddress, soulsAddress, warriorsAddress, bookOfLoreAddress, baseLoreURI);
        vm.stopBroadcast();
        return (deadSecrets, helperConfig);
    }
}
