# Bitcoin DAO Smart Contract

A decentralized autonomous organization (DAO) implementation on the Bitcoin blockchain using Clarity smart contracts. This DAO enables users to stake BTC (simulated with STX for testing), create proposals, vote, and execute decisions in a decentralized manner.

## Features

- **Staking**: Users can stake tokens to participate in governance
- **Proposal Creation**: Stakeholders can create proposals with titles and descriptions
- **Voting**: Weighted voting system based on stake amounts
- **Proposal Execution**: Automatic execution of passed proposals
- **Security**: Built-in validation and safety checks

## Technical Overview

### Core Components

1. **Staking System**

   - Minimum stake requirement: 100,000 sats
   - Total stake tracking
   - Individual stake tracking per user

2. **Proposal System**

   - Proposal duration: ~1 day (144 blocks)
   - Title limit: 50 characters
   - Description limit: 500 characters
   - Status tracking: active/executed
   - Vote counting mechanism

3. **Voting Mechanism**
   - Weight-based voting
   - One vote per user per proposal
   - 10% quorum requirement
   - Yes/No voting options

### Key Functions

```clarity
;; Staking
(define-public (stake (amount uint)))

;; Proposal Management
(define-public (create-proposal (title (string-ascii 50))
                              (description (string-ascii 500))
                              (duration uint)))

;; Voting
(define-public (vote (proposal-id uint) (vote-for bool)))

;; Execution
(define-public (execute-proposal (proposal-id uint)))
```

## Getting Started

### Prerequisites

- Stacks blockchain environment
- Clarity CLI tools
- STX tokens for testing

### Installation

1. Clone the repository
2. Deploy using Clarity CLI:
   ```bash
   clarity deploy bitcoin-dao.clar
   ```

### Usage Example

```clarity
;; Stake tokens
(contract-call? .bitcoin-dao stake u100000)

;; Create a proposal
(contract-call? .bitcoin-dao create-proposal "Update Parameters"
               "Adjust minimum stake requirement" u144)

;; Vote on a proposal
(contract-call? .bitcoin-dao vote u1 true)

;; Execute a passed proposal
(contract-call? .bitcoin-dao execute-proposal u1)
```

## Error Codes

- `ERR-NOT-AUTHORIZED (u100)`: Unauthorized action
- `ERR-PROPOSAL-NOT-FOUND (u101)`: Invalid proposal ID
- `ERR-INVALID-AMOUNT (u102)`: Invalid stake amount
- `ERR-ALREADY-VOTED (u103)`: Duplicate vote attempt
- `ERR-PROPOSAL-EXPIRED (u104)`: Expired proposal
- `ERR-INSUFFICIENT-STAKE (u105)`: Stake requirement not met
- `ERR-PROPOSAL-NOT-ACTIVE (u106)`: Inactive proposal
- `ERR-INVALID-STATE (u107)`: Invalid proposal state
- `ERR-INVALID-TITLE (u108)`: Invalid proposal title
- `ERR-INVALID-DESCRIPTION (u109)`: Invalid proposal description
- `ERR-INVALID-VOTE (u110)`: Invalid vote value
