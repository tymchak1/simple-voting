// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Logic: user can vote only one time, can check amount of votes, and only YES/NO (enum)
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleVoting is Ownable {
    error AlreadyVoted();
    error VotingEnded();
    error NameAlreadyExists();
    error VotingNotEndedYet();
    error PollDoesNotExist();

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

    Poll[] private s_polls;
    mapping(uint256 => mapping(address => bool)) s_hasVoted;

    constructor() Ownable(msg.sender) {}

    function createPoll(
        string calldata _question,
        uint256 _durationInSeconds
    ) external onlyOwner {
        for (uint256 i = 0; i < s_polls.length; i++) {
            if (
                keccak256(bytes(s_polls[i].question)) ==
                keccak256(bytes(_question))
            ) {
                revert NameAlreadyExists();
            }
        }

        Poll memory newPoll = Poll({
            question: _question,
            yesVotes: 0,
            noVotes: 0,
            votingTime: block.timestamp + _durationInSeconds
        });
        s_polls.push(newPoll);
    }

    function vote(uint256 pollIndex, Vote theVote) external {
        if (s_hasVoted[pollIndex][msg.sender]) {
            revert AlreadyVoted();
        }
        Poll storage poll = s_polls[pollIndex];

        if (block.timestamp > poll.votingTime) {
            revert VotingEnded();
        }

        s_hasVoted[pollIndex][msg.sender] = true;

        if (theVote == Vote.YES) {
            poll.yesVotes += 1;
        } else {
            poll.noVotes += 1;
        }
    }

    // get results
    function pollResults(
        uint256 pollIndex
    ) external view returns (string memory) {
        Poll memory poll = s_polls[pollIndex];

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
        Poll memory poll = s_polls[pollIndex];
        return (poll.question, poll.yesVotes, poll.noVotes, poll.votingTime);
    }

    function getPollByIndex(uint256 index) external view returns (Poll memory) {
        if (index >= s_polls.length) {
            revert PollDoesNotExist();
        }
        return s_polls[index];
    }

    function getPollQuestion(
        uint256 index
    ) external view returns (string memory) {
        return s_polls[index].question;
    }

    function getPollCount() external view returns (uint256) {
        return s_polls.length;
    }

    function getPollYesVotes(uint256 index) external view returns (uint256) {
        return s_polls[index].yesVotes;
    }

    function getPollNoVotes(uint256 index) external view returns (uint256) {
        return s_polls[index].noVotes;
    }

    function getPollVotingTime(uint256 index) external view returns (uint256) {
        return s_polls[index].votingTime;
    }
}
