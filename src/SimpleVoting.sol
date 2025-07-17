// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AlreadyVoted, VotingEnded, VotingNotEndedYet, NameAlreadyExists, PollDoesNotExist} from "./Errors.sol";

/**
 * @title SimpleVoting
 * @dev Contract for creating and conducting simple polls with time-based voting
 * @notice Allows users to vote YES or NO on polls created by the contract owner
 * @author tymchak1
 *
 * Key features:
 * - Only contract owner can create polls
 * - Users can vote only once per poll
 * - Only YES/NO votes are allowed
 * - Each poll has a limited time for voting
 */

contract SimpleVoting is Ownable {
    /**
     * @dev Voting options for a poll
     */
    enum Vote {
        YES, // Positive vote - user supports the proposal
        NO // Negative vote - user opposes the proposal
    }
    /**
     * @dev Possible results of a poll once voting is finished
     */
    enum PollResult {
        Approved,
        Rejected,
        Tie
    }
    /**
     * @dev Represents a single poll with voting data and time limitations
     */
    struct Poll {
        string question; // The poll question being asked
        uint64 votingTime; // Timestamp when voting ends
        uint32 yesVotes; // Number of YES votes received
        uint32 noVotes; // Number of NO votes received
    }

    /// @dev Stores all created polls in chronological order
    Poll[] private s_polls;

    /// @dev Mapping to track if poll name exists to prevent duplicates
    mapping(bytes32 => bool) private s_questionExists;

    /// @dev Tracks if a user has voted in specific poll (pollId => userAddress => hasVoted)
    mapping(uint256 pollId => mapping(address userAddress => bool hasVoted)) s_hasVoted;

    /// @dev Emitted when new poll is created
    /// @param pollId The ID of the newly created poll
    /// @param createdAt Timestamp when the poll was created
    event PollCreated(uint256 indexed pollId, uint256 createdAt);

    /// @dev Emitted when a user votes on a poll
    /// @param pollId The ID of the poll being voted on
    /// @param user Address of the user who voted
    /// @param vote The vote choice (YES/NO)
    event VoteCast(uint256 indexed pollId, address indexed user, Vote vote);

    /// @dev Sets the contract deployer as an owner
    constructor() Ownable(msg.sender) {}

    /// @dev Creates a poll with duplicate question check and stores it in the polls array
    /// @notice Creates a new poll that users can vote on (owner only)
    /// @param  _question The qustion to be asked in the poll
    /// @param _durationInSeconds How long the poll will be active (in seconds)
    function createPoll(
        string calldata _question,
        uint64 _durationInSeconds
    ) external onlyOwner {
        bytes32 questionHash = keccak256(bytes(_question));

        if (s_questionExists[questionHash]) {
            revert NameAlreadyExists();
        }

        Poll memory newPoll = Poll({
            question: _question,
            votingTime: uint64(block.timestamp) + _durationInSeconds,
            yesVotes: 0,
            noVotes: 0
        });
        s_polls.push(newPoll);

        uint256 pollId = s_polls.length - 1;
        emit PollCreated(pollId, uint64(block.timestamp));
    }

    /// @dev Records a user's vote on poll with validation check (no voted before, within the time limit)
    /// @notice Vote YES or NO on a specific poll
    /// @param pollId The ID of the poll to vote on
    /// @param theVote The vote option (YES/NO)
    function vote(uint256 pollId, Vote theVote) external {
        if (pollId >= s_polls.length) {
            revert PollDoesNotExist();
        }

        Poll storage poll = s_polls[pollId];

        if (s_hasVoted[pollId][msg.sender]) {
            revert AlreadyVoted();
        }
        if (block.timestamp > uint256(poll.votingTime)) {
            revert VotingEnded();
        }

        s_hasVoted[pollId][msg.sender] = true;
        unchecked {
            // for overflow needed more than 4 billion votes
            if (theVote == Vote.YES) {
                poll.yesVotes += 1;
            } else {
                poll.noVotes += 1;
            }
        }
        emit VoteCast(pollId, msg.sender, theVote);
    }

    /// @dev

    function getPollResults(uint256 pollId) external view returns (PollResult) {
        if (pollId >= s_polls.length) {
            revert PollDoesNotExist();
        }
        Poll memory poll = s_polls[pollId];

        if (block.timestamp < poll.votingTime) {
            revert VotingNotEndedYet();
        }

        if (poll.yesVotes > poll.noVotes) {
            return PollResult.Approved;
        } else if (poll.yesVotes < poll.noVotes) {
            return PollResult.Rejected;
        } else {
            return PollResult.Tie;
        }
    }

    /// @dev Retrieves poll detailes (for testing and frontend convenience, reverts if the poll does not exist)
    /// @notice Retrieves full details of a poll by its ID
    /// @param pollId The ID of the poll
    /// @return Poll The poll data structure
    function getPollByIndex(
        uint256 pollId
    ) external view returns (Poll memory) {
        if (pollId >= s_polls.length) {
            revert PollDoesNotExist();
        }
        return s_polls[pollId];
    }

    /// @dev Retrieves the question of a poll
    /// @notice For testing and frontend convenience only
    /// @param pollId The ID of the poll
    /// @return string The poll question
    function getPollQuestion(
        uint256 pollId
    ) external view returns (string memory) {
        return s_polls[pollId].question;
    }

    /// @dev Returns the total number of polls created (for testing and frontend convenience)
    /// @return uint256 The count of polls stored in the contract
    function getPollCount() external view returns (uint256) {
        return s_polls.length;
    }

    /// @dev Returns the total number of YES votes in a poll (for testing and frontend convenience)
    /// @param pollId The ID of the poll
    /// @return uint256 Number of YES votes
    function getPollYesVotes(uint256 pollId) external view returns (uint256) {
        return s_polls[pollId].yesVotes;
    }

    /// @dev Returns the total number of NO votes in a poll (for testing and frontend convenience)
    /// @param pollId The ID of the poll
    /// @return uint256 Number of NO votes
    function getPollNoVotes(uint256 pollId) external view returns (uint256) {
        return s_polls[pollId].noVotes;
    }

    /// @dev Returns the voting time of a poll (for testing and frontend convenience)
    /// @param pollId The ID of the poll
    /// @return uint256 Timestamp that represents deadline
    function getPollVotingTime(uint256 pollId) external view returns (uint256) {
        return s_polls[pollId].votingTime;
    }

    /// @dev Checks if a specific user has already voted in given poll (for testing and frontend convenience)
    /// @param pollId The ID of the poll
    /// @param user The address of the user
    /// @return bool True if user voted, False otherwise
    function hasUserVoted(
        uint256 pollId,
        address user
    ) external view returns (bool) {
        return s_hasVoted[pollId][user];
    }
}
