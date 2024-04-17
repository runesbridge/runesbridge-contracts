// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {IRunesBridge} from "./IRunesBridge.sol";
import {IUNCXTokenVesting} from "./IUNCXTokenVesting.sol";

contract UnlockAndBurn {
    IRunesBridge public runesBridge =
        IRunesBridge(0xe91598331A36A78f7fEfe277cE7C1915DA0AfB93);
    IUNCXTokenVesting tokenVesting =
        IUNCXTokenVesting(0xDba68f07d1b7Ca219f78ae8582C213d975c25cAf);


    function unlockAndBurn(uint256 lockID, uint256 amount) external {
        tokenVesting.withdraw(lockID, amount);
        runesBridge.burn(amount);
    }
}
