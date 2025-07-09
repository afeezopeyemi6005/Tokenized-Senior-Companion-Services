# Tokenized Senior Companion Services

A comprehensive blockchain-based platform for connecting seniors with companion services, built on the Stacks blockchain using Clarity smart contracts.

## Overview

This system provides a decentralized platform for senior companion services with five core contracts:

1. **Companion Matching Contract** - Pairs seniors with compatible social partners
2. **Activity Planning Contract** - Coordinates engaging recreational experiences
3. **Health Check Contract** - Monitors basic wellness indicators during visits
4. **Family Communication Contract** - Provides regular updates to relatives
5. **Emergency Assistance Contract** - Ensures rapid help during health crises

## Features

- Tokenized service payments and rewards
- Decentralized companion matching based on compatibility scores
- Activity planning and scheduling system
- Health monitoring and reporting
- Family communication and updates
- Emergency response coordination
- Reputation and rating system for companions

## Contract Architecture

Each contract operates independently without cross-contract calls, ensuring modularity and security:

### Companion Matching Contract
- Register seniors and companions
- Calculate compatibility scores
- Manage matching process
- Handle service payments

### Activity Planning Contract
- Create and manage activity proposals
- Schedule activities with companions
- Track participation and completion
- Reward system for engagement

### Health Check Contract
- Record health indicators during visits
- Monitor wellness trends
- Alert system for concerning changes
- Privacy-focused health data management

### Family Communication Contract
- Register family members
- Send regular updates about senior's activities
- Emergency notification system
- Communication preferences management

### Emergency Assistance Contract
- Emergency contact registration
- Rapid response coordination
- Location and status tracking
- Integration with local emergency services

## Getting Started

### Prerequisites
- Stacks blockchain node
- Clarity development environment
- Testing framework (Vitest)

### Installation

1. Clone the repository
2. Install dependencies
3. Deploy contracts to Stacks testnet
4. Run tests to verify functionality

### Testing

Run the test suite using Vitest:

\`\`\`bash
npm test
\`\`\`

## Security Considerations

- All contracts implement proper access controls
- Personal health data is encrypted and privacy-focused
- Emergency systems have redundant safeguards
- Financial transactions use secure token standards

## Contributing

Please read our contributing guidelines and submit pull requests for any improvements.

## License

This project is licensed under the MIT License.
