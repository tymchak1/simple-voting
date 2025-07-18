// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AlreadyVoted, VotingEnded, VotingNotEndedYet, NameAlreadyExists, PollDoesNotExist} from "./Errors.sol";

/**
 * @title SimpleVoting
 * @notice Contract for creating and conducting simple polls with time-based voting
 * @dev Allows users to vote YES or NO on polls created by the contract owner
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
     * @notice Voting options for a poll
     */
    enum Vote {
        YES, // Positive vote - user supports the proposal
        NO // Negative vote - user opposes the proposal

    }
    /**
     * @notice Possible results of a poll once voting is finished
     */
    enum PollResult {
        Approved,
        Rejected,
        Tie
    }
    /**
     * @notice Represents a single poll with voting data and time limitations
     */

    struct Poll {
        string question; // The poll question being asked
        uint64 votingTime; // Timestamp when voting ends
        uint32 yesVotes; // Number of YES votes received
        uint32 noVotes; // Number of NO votes received
    }

    /// @notice Stores all created polls in chronological order
    Poll[] private s_polls;

    /// @notice Mapping to track if poll name exists to prevent duplicates
    mapping(bytes32 => bool) private s_questionExists;

    /// @notice Tracks if a user has voted in specific poll (pollId => userAddress => hasVoted)
    mapping(uint256 pollId => mapping(address userAddress => bool hasVoted)) s_hasVoted;

    /// @notice Emitted when new poll is created
    /// @param pollId The ID of the newly created poll
    /// @param createdAt Timestamp when the poll was created
    event PollCreated(uint256 indexed pollId, uint256 createdAt);

    /// @notice Emitted when a user votes on a poll
    /// @param pollId The ID of the poll being voted on
    /// @param user Address of the user who voted
    /// @param vote The vote choice (YES/NO)
    event VoteCast(uint256 indexed pollId, address indexed user, Vote vote);

    /**
     * @notice Ensures that poll with given ID exists
     * @dev Reverts if pollId is out of range (poll does not exist)
     * @param pollId the ID of the poll to validate
     */
    modifier pollExists(uint256 pollId) {
        if (pollId >= s_polls.length) {
            revert PollDoesNotExist();
        }
        _;
    }

    /// @notice Sets the contract deployer as an owner
    constructor() Ownable(msg.sender) {}

    /// @notice Creates a new poll that users can vote on
    /// @dev Only owner can cerate a poll with duplicate question check and it is stored in the polls array
    /// @param  _question The qustion to be asked in the poll
    /// @param _durationInSeconds How long the poll will be active (in seconds)
    function createPoll(string calldata _question, uint64 _durationInSeconds) external onlyOwner {
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
        s_questionExists[questionHash] = true;

        uint256 pollId = s_polls.length - 1;
        emit PollCreated(pollId, uint64(block.timestamp));
    }

    /// @notice Vote YES or NO on a specific poll
    /// @dev Records a user's vote on poll with validation check (no voted before, within the time limit)
    /// @param pollId The ID of the poll to vote on
    /// @param theVote The vote option (YES/NO)
    function vote(uint256 pollId, Vote theVote) external pollExists(pollId) {
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

    /// @notice Retrieves the result of a poll after voting has ended
    /// @dev Reverts if the poll does not exist or if voting is still ongoing
    /// @param pollId The ID of the poll to check
    /// @return PollResult Approved if YES votes > NO votes, Rejected if NO votes > YES votes, Tie if equal

    function getPollResults(uint256 pollId) external view pollExists(pollId) returns (PollResult) {
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

    /// @notice Returns complete poll data for a given poll ID
    /// @dev Reverts if the poll with the given ID does not exist
    /// @param pollId The ID of the poll
    /// @return Poll The full poll structure: question, voting time, and vote counts
    function getPollByIndex(uint256 pollId) external view pollExists(pollId) returns (Poll memory) {
        return s_polls[pollId];
    }

    /// @notice Retrieves the question text of a poll
    /// @dev For testing and frontend convenience only
    /// @param pollId The ID of the poll
    /// @return string The poll's question
    function getPollQuestion(uint256 pollId) external view pollExists(pollId) returns (string memory) {
        return s_polls[pollId].question;
    }

    /// @notice Returns the total number of polls created
    /// @dev For testing and frontend convenience
    /// @return uint256 The count of polls stored in the contract
    function getPollCount() external view returns (uint256) {
        return s_polls.length;
    }

    /// @notice Returns the total number of YES votes in a poll
    /// @dev For testing and frontend convenience
    /// @param pollId The ID of the poll
    /// @return uint256 Number of YES votes
    function getPollYesVotes(uint256 pollId) external view pollExists(pollId) returns (uint32) {
        return s_polls[pollId].yesVotes;
    }

    /// @notice Returns the total number of NO votes in a poll
    /// @dev For testing and frontend convenience
    /// @param pollId The ID of the poll
    /// @return uint256 Number of NO votes
    function getPollNoVotes(uint256 pollId) external view pollExists(pollId) returns (uint32) {
        return s_polls[pollId].noVotes;
    }

    /// @notice Returns the voting time of a poll
    /// @dev For testing and frontend convenience
    /// @param pollId The ID of the poll
    /// @return uint256 Timestamp that represents deadline
    function getPollVotingTime(uint256 pollId) external view pollExists(pollId) returns (uint64) {
        return s_polls[pollId].votingTime;
    }

    /// @notice Checks if a specific user has already voted in given poll
    /// @dev For testing and frontend convenience
    /// @param pollId The ID of the poll
    /// @param user The address of the user
    /// @return bool True if user voted, False otherwise
    function hasUserVoted(uint256 pollId, address user) external view pollExists(pollId) returns (bool) {
        return s_hasVoted[pollId][user];
    }
}
