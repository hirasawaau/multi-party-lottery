# multi-party-lottery

## Description

The game that Users can input a number between 0 and 999 and await the prize.

## Flow

### Construct the contract

#### Required parameters

- `_N` is maximum number of participants in the contract.
- `_T1` is the time in seconds that the contract will be open for the participants to join and commit the hash.
- `_T2` is the time in seconds that the contract will be open for the participants to reveal the number.
- `_T3` is the time in seconds that the contract will be open for the owner of contract announce the winner.

### Steps

#### Stage 0,1

1. The owner of the contract constructs the contract with the required parameters.
2. Participants join the contract by sending the hash of their number (called `Lottery::stg1_join(bytes32 hashedData)`). [Get hashed by `Lottery::hashAnswer(uint8 data,string salt)`]
3. Waiting `T1` seconds for the participants to join and commit the hash to next stage (called `Lottery::stg1_request_to_stg2()`).

#### Stage 2

1. Participants reveal their number.
2. Waiting `T2` seconds for the participants to reveal the number. If the participants do not reveal the number, they will be disqualified. (called `Lottery::stg2_reveal(uint8 data, string salt`)

#### Stage 3

1. The owner of the contract announces the winner. (called `Lottery::stg3_announce_winner()`)
2. The winner or owner will get the prize automatically when called above function.

#### Stage 4 (if the winner is not announced by owner in `T3` seconds)

1. The participants can get the prize by calling `Lottery::stg4_refund()`.
