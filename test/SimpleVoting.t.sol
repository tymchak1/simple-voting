// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";
import {SimpleVoting} from "../src/SimpleVoting.sol";
// import {HelperConfig} from "../script/HelperConfig.s.sol";
import {DeploySimpleVoting} from "../script/DeploySimpleVoting.s.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleVotingTest is Test, DeploySimpleVoting {
    SimpleVoting simpleVoting;
    // HelperConfig public helperConfig;

    address public USER = makeAddr("user");
    uint256 public constant STARTING_BALANCE = 10 ether;

    event PollCreated(uint256 indexed pollId, uint256 indexed createdAt);
    event UserVoted(uint256 indexed pollId, address indexed user, SimpleVoting.Vote vote);

    function setUp() external {
        DeploySimpleVoting deploySimpleVoting = new DeploySimpleVoting();
        simpleVoting = deploySimpleVoting.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    /*//////////////////////////////////////////////////////////////
                               CREATE POLL
    //////////////////////////////////////////////////////////////*/

    function test__RevertIfPollWithThisNameAlreadyExists() external {
        //  Arrange
        string memory question = "Is this contract good?";
        uint256 duration = 1 hours;

        address owner = simpleVoting.owner();

        //  Act&Assert
        vm.prank(owner);
        simpleVoting.createPoll(question, duration);

        vm.prank(owner);
        vm.expectRevert(SimpleVoting.NameAlreadyExists.selector);
        simpleVoting.createPoll(question, duration);
    }

    function test__RevertIfNotOwnerCreatesPoll() external {
        string memory question = "Is this contract good?";
        uint256 duration = 1 hours;

        vm.prank(USER);
        // vm.expectRevert(
        //     abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", USER)
        // );

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));
        simpleVoting.createPoll(question, duration);
    }

    function test__PollAddedToArrayOfPolls() external {
        string memory question = "Is this contract good?";
        uint256 duration = 1 hours;
        address owner = simpleVoting.owner();

        vm.prank(owner);
        simpleVoting.createPoll(question, duration);

        string memory storedQuestion = simpleVoting.getPollQuestion(0);
        assertEq(storedQuestion, question);
    }

    function test__PollCreatedSuccessfully() external {
        string memory question = "Is this contract good?";
        uint256 duration = 1 hours;
        address owner = simpleVoting.owner();

        vm.warp(1000);
        uint256 expectedPollId = 0;
        vm.prank(owner);

        vm.expectEmit(true, true, false, false, address(simpleVoting));
        emit PollCreated(expectedPollId, 1000);

        simpleVoting.createPoll(question, duration);

        uint256 pollCount = simpleVoting.getPollCount();
        assertEq(pollCount, 1);

        string memory storedQuestion = simpleVoting.getPollQuestion(0);
        assertEq(storedQuestion, question);

        uint256 yesVotes = simpleVoting.getPollYesVotes(0);
        uint256 noVotes = simpleVoting.getPollNoVotes(0);
        uint256 votingTime = simpleVoting.getPollVotingTime(0);

        assertEq(yesVotes, 0);
        assertEq(noVotes, 0);
        assertGt(votingTime, block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                                Vote
    //////////////////////////////////////////////////////////////*/
    function test__RevertIf_PollDoesNotExist() external {
        // Arrange
        vm.prank(USER);

        // Act & Assert
        vm.expectRevert(SimpleVoting.PollDoesNotExist.selector);
        simpleVoting.vote(1, SimpleVoting.Vote.YES);
    }

    function test__RevertIf_UserAlreadyVoted() external {
        // Arrange (create poll)
        string memory question = "Is this contract good?";
        uint256 duration = 1 hours;
        address owner = simpleVoting.owner();

        vm.prank(owner);
        simpleVoting.createPoll(question, duration);
        // Act (1st time voitng)
        vm.startPrank(USER);
        simpleVoting.vote(0, SimpleVoting.Vote.YES);

        // Assert
        vm.expectRevert(SimpleVoting.AlreadyVoted.selector);
        simpleVoting.vote(0, SimpleVoting.Vote.YES);
        vm.stopPrank();
    }

    function test__RevertIfVotingEnded() external {
        string memory question = "Is this contract good?";
        uint256 duration = 1 hours;
        address owner = simpleVoting.owner();

        vm.prank(owner);
        simpleVoting.createPoll(question, duration);

        vm.warp(block.timestamp + duration + 1);
        vm.prank(USER);
        vm.expectRevert(SimpleVoting.VotingEnded.selector);
        simpleVoting.vote(0, SimpleVoting.Vote.YES);
    }

    function test__UserIsMarkedAsVotedAfterVoting() external {
        string memory question = "Is this contract good?";
        uint256 duration = 1 hours;
        address owner = simpleVoting.owner();

        vm.prank(owner);
        simpleVoting.createPoll(question, duration);
        vm.prank(USER);
        uint256 pollId = 0;
        simpleVoting.vote(0, SimpleVoting.Vote.YES);
        assertEq(simpleVoting.hasUserVoted(pollId, USER), true);
    }

    function test__VotedSuccessfully() external {
        string memory question = "Is this contract good?";
        uint256 duration = 1 hours;
        address owner = simpleVoting.owner();

        vm.prank(owner);
        simpleVoting.createPoll(question, duration);

        uint256 pollId = 0;

        vm.expectEmit(true, true, false, true, address(simpleVoting));
        emit UserVoted(pollId, USER, SimpleVoting.Vote.YES);

        vm.startPrank(USER);
        simpleVoting.vote(0, SimpleVoting.Vote.YES);
        assertEq(simpleVoting.hasUserVoted(pollId, USER), true);

        uint256 yesVotes = simpleVoting.getPollYesVotes(0);
        uint256 noVotes = simpleVoting.getPollNoVotes(0);

        assertEq(yesVotes, 1);
        assertEq(noVotes, 0);

        vm.stopPrank();
    }
}
