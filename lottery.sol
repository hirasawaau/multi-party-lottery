// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "commit-reveal.sol";

contract Lottery is CommitReveal {
    uint8 public N;

    uint8 private T1;

    uint8 private T2;

    uint8 private T3;

    uint8 private currentState = 0;

    function getCurrentState() public view returns (uint8) {
        return currentState;
    }

    uint8 private numPlayer = 0;

    uint8 private winner = 0;

    bool private is_winner_announced = false;

    uint8 private numRevealed = 0;

    uint8[] answers;

    mapping(address => uint8) ids;
    mapping(uint8 => address) idToAddress;

    mapping(address => bool) registered;

    address private owner;

    uint256 rewards;

    uint256 startTime;

    constructor(uint8 _N, uint8 _T1, uint8 _T2, uint8 _T3) {
        N = _N;
        T1 = _T1 * (1 seconds);
        T2 = _T2 * (1 seconds);
        T3 = _T3 * (1 seconds);

        owner = msg.sender;
        answers = new uint8[](N);
    }

    function goToStage(uint8 n) private {
        require(n >= 1 && n <= 4, "Error(lottery::goToStage): Stage incorrect");
        require(
            currentState == n - 1,
            "Error(lottery::goToStage): Current stage and next stage is not correct"
        );
        if (n == 1) {
            currentState = 1;
            startTime = block.timestamp;
        } else if (n == 2) {
            require(
                block.timestamp - startTime > T1,
                "Error(lottery::goToStage): Time is not enough"
            );
            currentState = 2;
            startTime = block.timestamp;
        } else if (n == 3) {
            require(
                block.timestamp - startTime > T2,
                "Error(lottery::goToStage): Time is not enough"
            );
            currentState = 3;
            startTime = block.timestamp;
        } else if (n == 4) {
            require(
                block.timestamp - startTime > T3,
                "Error(lottery::goToStage): Time is not enough"
            );
            currentState = 4;
        }
        emit StageChanged(currentState, currentState - 1);
    }

    event StageChanged(uint8 currentState, uint8 previousStage);

    // Stage 1 Functions

    function stg1_join(bytes32 hashed32) public payable {
        require(
            currentState <= 1,
            "Error(lottery::stg1_join): Stage must be 0 or 1"
        );
        require(numPlayer < N, "Error(lottery::stg1_join): Player exceeded");
        require(
            msg.value == 0.001 ether,
            "Error(lottery::stg1_join): Amount value is incorrect."
        );

        rewards += msg.value;
        commit(hashed32);

        numPlayer++;
        registered[msg.sender] = true;
        emit PlayerJoin(msg.sender);

        if (currentState == 0) {
            goToStage(1);
        }

        if (numPlayer == N && block.timestamp - startTime > T1) {
            goToStage(2);
        }
    }

    function stg1_request_to_stg2() public {
        goToStage(2);
    }

    event PlayerJoin(address player);

    // Stage 2 Functions

    function stg2_reveal(uint8 data, string memory salt) public {
        require(
            currentState == 2,
            "Error(lottery::stg2_reveal): Stage must be 2"
        );
        revealAnswer(data, bytes32(abi.encodePacked(salt)));
        if (data < 0 || data > 999) {
            emit PlayerDoesntMeetRequire(msg.sender, data);
        } else {
            ids[msg.sender] = numRevealed;
            idToAddress[numRevealed] = msg.sender;
            answers[numRevealed] = data;
            numRevealed++;
            emit PlayerReveal(msg.sender);

            if (numPlayer == numRevealed && block.timestamp - startTime > T2) {
                goToStage(3);
            }
        }
    }

    event PlayerReveal(address player);
    event PlayerDoesntMeetRequire(address player, uint8 data);

    function stg2_request_to_stg3() public {
        goToStage(3);
    }

    // Stage 3 Functions

    function _reset() private {
        currentState = 0;
        numPlayer = 0;
        numRevealed = 0;
        delete answers;
        answers = new uint8[](N);

        emit ContractReset();
    }

    event ContractReset();

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Error(lottery::onlyOwner): This function is called only owner."
        );
        _;
    }

    function stg3_announce_winner() public onlyOwner {
        require(
            currentState == 3,
            "Error(lottery::stg3_announce_winner): Stage only 3."
        );
        require(
            !is_winner_announced,
            "Error(lottery::stg3_announce_winner): Winner is announced."
        );
        if (numRevealed != 0) {
            uint8 result = answers[0];
            for (uint8 i = 1; i < numRevealed; i++) {
                result = result ^ answers[i];
            }

            bytes32 hashedData = Hash(result);
            winner = uint8(uint256(hashedData) % numRevealed);
            is_winner_announced = true;

            emit Winner(winner, idToAddress[winner]);

            address payable winner_payable = payable(idToAddress[winner]);
            address payable owner_payable = payable(owner);

            winner_payable.transfer((address(this).balance * 98) / 100);
            owner_payable.transfer(address(this).balance);
        } else {
            address payable owner_payable = payable(owner);
            owner_payable.transfer(address(this).balance);
        }

        _reset();
    }

    function stg3_request_to_stg4() public {
        require(
            currentState == 3,
            "Error(lottery::stg3_announce_winner): Stage only 3."
        );
        goToStage(4);
    }

    event Winner(uint8 id, address winner);

    // Stage 4 Function
    function stg4_refund() public {
        require(currentState == 4, "Error(lottery::stg4_refund): Stage only 4");
        require(
            registered[msg.sender],
            "Error(lottery::stg4_refund: Not in contract"
        );

        address payable sender_payable = payable(msg.sender);
        sender_payable.transfer(0.001 ether);
        registered[msg.sender] = false;
        emit Refund(msg.sender);
    }

    event Refund(address player);

    function hashAnswer(
        uint8 data,
        string memory salt
    ) public view returns (bytes32) {
        return getHashSalt(data, bytes32(abi.encodePacked(salt)));
    }
}
