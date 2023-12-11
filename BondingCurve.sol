// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


contract BondingCurve {

    uint256 public interestRate;
    uint256 growthConstant = 500;
    uint256 minRate = 3;

    function getInteresRate(uint _IDRatio) public returns(uint){
        interestRate = minRate*(3*(growthConstant*_IDRatio));
        return interestRate;

    }
}







