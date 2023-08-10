// SPDX-License-Identifier: MIT
pragma solidity =0.8.19; // @audit version

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol"; // @audit made imports withh import {} from ...
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol"; 

contract PonziContract is ReentrancyGuard, Ownable {
    event RegistrationDeadline(uint256 registrationDeadline);
    event Withdraw(uint256 amount);

    uint256 private registrationDeadline;
    address[] public affiliates_;
    mapping(address => bool) public affiliates;
    uint256 public affiliatesCount;

    modifier onlyAfilliates() {
        bool affiliate;
        for (uint256 i = 0; i < affiliatesCount; i++) { // @audit cheaper to use uchecked ++i
            if (affiliates_[i] == msg.sender) {
                affiliate = true;
            }
        }
        require(affiliate == true, "Not an Affiliate!"); // @audit use custom errors cheaper than require
        _;
    }

    function setDeadline(uint256 _regDeadline) external onlyOwner { // @audit risk of centralization
        registrationDeadline = _regDeadline; // @audit add check to not set same value twice
        emit RegistrationDeadline(registrationDeadline);
    }

    function joinPonzi(
        address[] calldata _afilliates
    ) external payable nonReentrant {
        require(
            block.timestamp < registrationDeadline,
            "Registration not Active!"
        );
        require(_afilliates.length == affiliatesCount, "Invalid length");
        require(msg.value == affiliatesCount * 1 ether, "Insufficient Ether");
        for (uint256 i = 0; i < _afilliates.length; i++) { // @audit cheaper to use unchecked ++i
            _afilliates[i].call{value: 1 ether}("");
        }
        affiliatesCount += 1;

        affiliates[msg.sender] = true; 
        affiliates_.push(msg.sender);
    }

    function buyOwnerRole(address newAdmin) external payable onlyAfilliates {
        require(msg.value == 10 ether, "Invalid Ether amount"); // @audit risk of stealing owner's rights
        _transferOwnership(newAdmin);
    }

    function ownerWithdraw(address to, uint256 amount) external onlyOwner { // @audit risk of centralization
        payable(to).call{value: amount}(""); // @audit HIGH rugpull
        emit Withdraw(amount);
    }

    function addNewAffilliate(address newAfilliate) external onlyOwner { // @audit risk of centralization
        affiliatesCount += 1; // @audit affiliatesCount = affiliatesCount + 1 is cheaper
        affiliates[newAfilliate] = true;
        affiliates_.push(newAfilliate);
    }

    receive() external payable {} // @audit lost funds risk
}
