// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "commit-reveal.sol";


contract Lottery is CommitReveal {
    uint8 private N;

    uint8 private T1;

    uint8 private T2;

    uint8 private T3;

    uint8 private currentState = 0;

    uint8 private numPlayer = 0;

    mapping (address => uint8) answers;

    uint rewards;

    uint256 startTime;

    constructor(uint8 _N, uint8 _T1, uint8 _T2, uint8 _T3) {
        N = _N;
        T1 = _T1 * (1 seconds);
        T2 = _T2 * (1 seconds);
        T3 = _T3 * (1 seconds);
    }

    function goToStage(uint8 n) public  {
        require(n >= 1 && n <= 4, "Error(lottery::goToStage): Stage incorrect");
        require(currentState == n-1, "Error(lottery::goToStage): Current stage and next stage is not correct");
        if(n == 1) {
            currentState = 1;
            startTime = block.timestamp;
        } else if(n == 2) {
            require(block.timestamp - startTime > T1, "Error(lottery::goToStage): Time is not enough");
            currentState = 2;
            startTime = block.timestamp;
        } else if (n == 3) {
            require(block.timestamp - startTime > T2, "Error(lottery::goToStage): Time is not enough");
            currentState = 3;
            startTime = block.timestamp;
        } else if (n == 4) {
            require(block.timestamp - startTime > T3, "Error(lottery::goToStage): Time is not enough");
            currentState = 4;
        }
        emit StageChanged(currentState , currentState-1);
    }

    event StageChanged(uint8 currentState,uint8 previousStage);

    // Stage 1 Functions

    function stg1_join(bytes32 hashed32) public payable {
        require(currentState <= 1, "Error(lottery::stg1_join): Stage must be 0 or 1");
        require(numPlayer < N , "Error(lottery::stg1_join): Player exceeded");
        require(msg.value == 0.001 ether, "Error(lottery::stg1_join): Amount value is incorrect.");
        
        rewards += msg.value;
        commit(hashed32);

        emit PlayerJoin(msg.sender);

        if(currentState == 0) {
            goToStage(1);
        }
    } 
    
    event PlayerJoin(address player);

    // Stage 2 Functions

    function stg2_reveal(uint8 data, bytes32 salt) public {
        require(currentState == 2, "Error(lottery::stg2_reveal): Stage must be 2");
        revealAnswer(data, salt);
        answers[msg.sender] = data;
        emit PlayerReveal(msg.sender);
    }

    event PlayerReveal(address player);


    



}