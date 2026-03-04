# Echidna Playground
Hi! this is my personal playground for echidna, a repository I use to practice using the tool echidna by crytic. If you want to download as well, you can click [here](https://github.com/crytic/echidna/) to visit the official github repository. 

## Contents

### 1. BasicVault
`BasicVault` is a minimal ETH vault that exposes only `deposit()` and `withdraw()` functions. The corresponding Echidna harness (`EchidnaBasicVault`) simply inherits `BasicVault` and defines an invariant over the built-in state. The intended bug is that `withdraw()` does **not** update `totalDeposited`, so an invariant such as `totalDeposited == address(this).balance` will eventually be violated.

### 2. MediumVault
`MediumVault` improves on `BasicVault` by correctly updating `totalDeposited` in `withdraw()`, but introduces a `receive()` function to accept donations. Echidna only calls functions that are part of the contract ABI or have the `echidna_` prefix; it does not automatically generate raw transactions with empty calldata to hit `receive()` or `fallback()`. To expose the donation-related accounting bug, we use a dedicated harness (`EchidnaMediumVault`) that deploys `MediumVault` internally and provides explicit entry points (for example, `do_donate()`) that Echidna can fuzz.

### 3. AdvancedVault
`AdvancedVault` is an ERC4626-based vault that tracks deposits via a `totalDeposited` variable. The `deposit()` and `withdraw()` functions correctly update this variable, but `redeem()` is intentionally left inconsistent. Because Echidna cannot directly deploy contracts that require constructor arguments, we use a harness (`EchidnaAdvancedVault`) that instantiates `AdvancedVault` in its constructor and then defines properties over the vault’s state, allowing Echidna to find sequences where `redeem()` breaks the accounting invariants.

## Repository Structure
```
echidna/
├── EchidnaBasicVault.sol      # Property-based tests for BasicVault
├── EchidnaMediumVault.sol     # Property-based tests for MediumVault
├── EchidnaAdvancedVault.sol   # Property-based tests for AdvancedVault
└── Results/                   # Saved Echidna run outputs
```

`src/` – Smart contract sources

```
src/
├── BasicVault.sol             # Simple ETH vault with naive accounting
├── MediumVault.sol            # More complex vault example
└── AdvancedVault.sol          # Advanced vault example (for richer properties)
```

## How To Run

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed (`forge` available in your `PATH`).
- [Echidna](https://github.com/crytic/echidna) installed (`echidna` available in your `PATH`).

### 1. Clone the repository

### 2. Compile the contracts with Foundry

From the `playground/` directory:

```bash
forge build
```

### 3. Run Echidna

You can run Echidna directly on any of the harness contracts in the `echidna/` folder, for example:

- Basic vault properties:

	```bash
	echidna ./echidna/EchidnaBasicVault.sol --contract EchidnaBasicVault
	```

- Medium vault properties:

	```bash
	echidna ./echidna/EchidnaMediumVault.sol --contract EchidnaMediumVault
	```

- Advanced vault properties:

	```bash
	echidna ./echidna/EchidnaAdvancedVault.sol --contract EchidnaAdvancedVault
	```

Echidna will compile the specified harness, execute the property-based tests, and report any counterexamples it finds.

## Library installed
```
forge install OpenZeppelin/openzeppelin-contracts
```
