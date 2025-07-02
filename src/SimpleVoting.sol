// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Logic: user can vote only one time, can check amount of votes, and only YES/NO (enum)
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleVoting is Ownable {
    error AlreadyVoted();
    error VotingEnded();
    error NameAlreadyExists();
    error VotingNotEndedYet();

    enum Vote {
        YES,
        NO
    }

    struct Poll {
        string question;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 votingTime;
    }

    address private immutable i_owner;
    Poll[] private s_poles;
    uint256 private s_pollIndex;
    mapping(uint256 => mapping(address => bool)) s_hasVoted;

    constructor() Ownable(i_owner) {
        i_owner = msg.sender;
    }

    function createPoll(
        string calldata _question,
        uint256 _durationInSeconds
    ) external onlyOwner {
        Poll memory newPoll = s_poles[s_pollIndex];

        for (uint256 i = 0; i < s_pollIndex; i++) {
            if (
                keccak256(bytes(s_poles[i].question)) ==
                keccak256(bytes(_question))
            ) {
                revert NameAlreadyExists();
            }
        }

        newPoll.question = _question;
        newPoll.votingTime = block.timestamp + _durationInSeconds;
        s_pollIndex++;
    }

    function vote(uint256 pollIndex, Vote vote) external {
        if (s_hasVoted[pollIndex][msg.sender]) {
            revert AlreadyVoted();
        }
        Poll memory poll = s_poles[pollIndex];
        if (block.timestamp > poll.votingTime) {
            revert VotingEnded();
        }

        s_hasVoted[pollIndex][msg.sender] = true;

        if (vote == Vote.YES) {
            poll.yesVotes += 1;
        } else {
            poll.noVotes += 1;
        }
    }

    // get results
    function pollResults(
        uint256 pollIndex
    ) external view returns (string memory) {
        Poll memory poll = s_poles[pollIndex];

        if (block.timestamp < poll.votingTime) {
            revert VotingNotEndedYet();
        }

        if (poll.yesVotes > poll.noVotes) {
            return "Approved";
        } else if (poll.yesVotes < poll.noVotes) {
            return "Rejected";
        } else {
            return "Tie";
        }
    }

    function getPollInfo(
        uint256 pollIndex
    )
        external
        view
        returns (
            string memory question,
            uint256 yesVotes,
            uint256 noVotes,
            uint256 votingTime
        )
    {
        Poll memory poll = s_poles[pollIndex];
        return (poll.question, poll.yesVotes, poll.noVotes, poll.votingTime);
    }

    function getPoles() external view returns (Poll[] memory) {
        Poll[] memory polls = new Poll[](s_pollIndex);
        for (uint256 i = 0; i < s_pollIndex; i++) {
            polls[i] = s_poles[i];
        }
        return polls;
    }
}
