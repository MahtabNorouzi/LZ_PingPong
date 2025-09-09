
# LZ_PingPong Example

> This repo is based on the [LayerZero OApp Example](https://github.com/LayerZero-Labs/devtools/tree/main/examples/oapp).  
> For full details about LayerZero’s OApp standard, please see the [official README](https://github.com/LayerZero-Labs/devtools/tree/main/examples/oapp).

---

## Overview

This project contains a minimal **Omnichain Application (OApp)** implementation using the [LayerZero v2 protocol](https://docs.layerzero.network).  
It demonstrates a simple **ping-pong messaging pattern** between two OApps deployed on different endpoints:

- **Chain A** sends `"Hello, World!"` to **Chain B**.  
- **Chain B** stores the message and replies with `"message received"`.  
- **Chain A** receives the reply.  

The key contract is [`MyOApp.sol`](./contracts/MyOApp.sol), which extends LayerZero’s `OApp` and implements custom send/receive logic.

---

## Running the Example with Foundry

This repo includes Foundry tests that simulate two OApps wired together across two mock endpoints.

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation) (`forge >= 0.2.0`)

### Run the tests
```bash
forge test -vv
```

You should see both OApps successfully exchange messages.

## Example Output

Here is the result of running `forge test`:

<img width="878" height="252" alt="test-output" src="https://github.com/user-attachments/assets/15c8b228-b1b1-48c0-b34c-1c0a663d4bca" />

## Repository Structure

- `contracts/MyOApp.sol` — Example omnichain contract with ping-pong logic  
- `test/MyOApp.t.sol` — Foundry test simulating cross-chain messaging  
- `layerzero.config.ts` — Configuration file for LayerZero wiring  
- `hardhat.config.ts`, `foundry.toml` — Project configs for Hardhat and Foundry

