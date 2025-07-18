# SimpleVoting Smart Contract

A decentralized voting system built on Ethereum that allows poll creation and secure voting with time-based constraints.

## 🚀 Features

- **Owner-Controlled Poll Creation**: Only contract owner can create new polls
- **Time-Limited Voting**: Each poll has a configurable voting duration
- **One Vote Per User**: Prevents double voting through address tracking
- **Binary Voting**: Simple YES/NO vote options
- **Real-Time Results**: View poll results after voting ends
- **Gas Optimized**: Efficient storage and minimal gas consumption

## 📋 Table of Contents

- [Architecture](#architecture)
- [Installation](#installation)
- [Deployment](#deployment)
- [Usage](#usage)
- [API Reference](#api-reference)
- [Testing](#testing)
- [Security](#security)
- [Gas Optimization](#gas-optimization)
- [Contributing](#contributing)
- [License](#license)

## 🏗️ Architecture

### Contract Structure

```
SimpleVoting/
├── src/
│   ├── SimpleVoting.sol    # Main voting contract
│   └── Errors.sol          # Custom error definitions
├── test/
│   └── SimpleVoting.t.sol
├── script/
│   └── DeploySimpleVoting.s.sol
│   └── HelperConfig.s.sol
└── README.md
```

[SimpleVoting.sol](https://github.com/tymchak1/simple-voting/blob/master/src/SimpleVoting.sol)  
[Errors.sol](https://github.com/tymchak1/simple-voting/blob/master/src/Errors.sol)

### Key Components

- **Poll Management**: Create and manage voting polls
- **Vote Tracking**: Record and validate user votes
- **Time Management**: Handle voting deadlines
- **Result Calculation**: Determine poll outcomes

## 🛠️ Installation

1. Install `foundryup`:

```bash
curl -L https://foundry.paradigm.xyz | bash
```

2. Run `foundryup`:

```bash
foundryup
```
### Setup

```bash
# Clone the repository
git clone https://github.com/tymchak1/simple-voting.git
cd simple-voting

# Install dependencies
forge install

# Compile contracts
forge build
```

## 🚀 Deployment
```bash
forge script script/DeploySimpleVoting.s.sol --private-key $PRIVATE_KEY --rpc-url $RPC_URL --broadcast
```

### Local Network

```bash
# Start local Anvil network (Foundry's local node)
anvil

# Deploy to local network
forge script script/DeploySimpleVoting.s.sol --private-key $PRIVATE_KEY --rpc-url http://127.0.0.1:8545 --broadcast
```

### Testnet Deployment

```bash
forge script script/DeploySimpleVoting.s.sol --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL --broadcast
```

### Environment Variables

Create a `.env` file:

```env
PRIVATE_KEY=your_private_key_here
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/your_project_id
ETHERSCAN_API_KEY=your_etherscan_api_key
```

### Core Functions

#### `createPoll(string question, uint64 duration)`
Creates a new voting poll.
- **Access**: Owner only
- **Parameters**: 
  - `question`: The poll question
  - `duration`: Voting duration in seconds
- **Events**: Emits `PollCreated(uint256 pollId, string question)`

#### `vote(uint256 pollId, Vote choice)`
Cast a vote on a specific poll.
- **Access**: Public
- **Parameters**:
  - `pollId`: ID of the poll
  - `choice`: 0 for YES, 1 for NO
- **Events**: Emits `VoteCast(uint256 pollId, address voter, uint8 choice)`

#### `getPollResults(uint256 pollId)`
Get the final result of a poll.
- **Access**: Public (view)
- **Returns**: `PollResult` enum (Approved/Rejected/Tie)
- **Requirements**: Voting must be ended

### View Functions

| Function                         | Description               | Returns       |
| -------------------------------- | ------------------------- | ------------- |
| `getPollByIndex(uint256)`        | Get complete poll data    | `Poll` struct |
| `getPollCount()`                 | Get total number of polls | `uint256`     |
| `getPollYesVotes(uint256)`       | Get YES vote count        | `uint32`      |
| `getPollNoVotes(uint256)`        | Get NO vote count         | `uint32`      |
| `hasUserVoted(uint256, address)` | Check if user voted       | `bool`        |

## 🧪 Testing

```bash
# Run all tests
forge test

# Run with coverage
forge coverage

# Run specific test file
forge test --match-path SimpleVoting.t.sol
```

### Test Coverage

- ✅ Poll creation and validation
- ✅ Voting mechanics and restrictions
- ✅ Time-based voting constraints
- ✅ Result calculation accuracy
- ✅ Access control functionality
- ✅ Error handling and edge cases

### Security Measures

- **Access Control**: OpenZeppelin's `Ownable` for owner-only functions
- **Reentrancy Protection**: Not applicable (no external calls)
- **Integer Overflow**: Safe math with Solidity ^0.8.20
- **Front-running**: Minimal impact due to simple voting logic

### Known Limitations

- Poll questions cannot be updated after creation
- No vote delegation mechanism
- Results are final once voting ends
- No privacy protection for votes (public blockchain)

### Gas Costs (Estimated)

| Function         | Gas Cost |
| ---------------- | -------- |
| `createPoll`     | ~100,000 |
| `vote`           | ~45,000  |
| `getPollResults` | ~25,000  |

### Optimization Techniques

- Struct packing for storage efficiency
- `unchecked` blocks for safe arithmetic
- Custom errors instead of string messages
- Minimal external calls


## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Team

- **Developer**: [@tymchak1](https://github.com/tymchak1)

⭐ **Star this repository if you find it useful!**