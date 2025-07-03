// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";
import {SimpleVoting} from "../src/SimpleVoting.sol";
// import {HelperConfig} from "../script/HelperConfig.s.sol";
import {DeploySimpleVoting} from "../script/DeploySimpleVoting.s.sol";

contract SimpleVotingTest is Test, DeploySimpleVoting {
    SimpleVoting simpleVoting;
    // HelperConfig public helperConfig;

    address public USER = makeAddr("user");
    uint256 public constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        DeploySimpleVoting deploySimpleVoting = new DeploySimpleVoting();
        simpleVoting = deploySimpleVoting.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    /*//////////////////////////////////////////////////////////////
                               CREATE POLL
    //////////////////////////////////////////////////////////////*/

    function test__PollWithThisNameAlreadyExists() external {
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

    function test__OnlyOwnerCanCreatePoll() external {
        string memory question = "Is this contract good?";
        uint256 duration = 1 hours;

        vm.prank(USER);
        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", USER)
        );
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

        vm.prank(owner);
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
}
