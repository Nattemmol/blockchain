# Foundry project — foundry_new

This project was initialized with Foundry. These notes show how to run Foundry tooling (forge, cast, anvil) on Windows when Foundry is installed inside WSL (Ubuntu). They also document the local Anvil deployment workflow we used.

Prerequisites
- Windows with WSL2 and an Ubuntu distro installed and available as `Ubuntu`.
- Foundry installed inside the Ubuntu WSL (`foundryup` → `forge`, `cast`, `anvil`).
- (Optional) A small Windows shim folder at `C:\Users\kalki\bin` (this project uses shims that forward `forge`, `cast`, `anvil` from PowerShell into WSL).

Quick setup (one-time)

1. If you haven't already, add the shim folder to your Windows user PATH so PowerShell recognizes `forge`/`cast`/`anvil` shims:

```powershell
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Users\kalki\bin", "User")
```

2. Restart your PowerShell terminal (or open a new one) so the new PATH takes effect.

Start Anvil (local node)

You can run Anvil directly from WSL (recommended) or use the Windows shim. The examples below use `wsl` so they work even if the shims are not available.

Start Anvil (default port 8545):

```powershell
wsl -d Ubuntu -- bash -lc "cd '/mnt/c/Users/kalki/Desktop/3rd year/5th/blockchain/foundry_new' && ~/.foundry/bin/anvil --host 0.0.0.0 > anvil.log 2>&1 & echo $! > anvil.pid"
wsl -d Ubuntu -- bash -lc "tail -n 40 anvil.log"
```

Start Anvil on port 7545 (if you need that port):

```powershell
wsl -d Ubuntu -- bash -lc "cd '/mnt/c/Users/kalki/Desktop/3rd year/5th/blockchain/foundry_new' && nohup ~/.foundry/bin/anvil --host 0.0.0.0 --port 7545 > anvil.log 2>&1 & echo $! > anvil.pid"
wsl -d Ubuntu -- bash -lc "tail -n 40 anvil.log"
```

Deploy a contract (example)

When Anvil starts it prints unlocked accounts and their private keys to `anvil.log`. For local testing you can use one of those keys. Example deploy command (broadcastes transaction):

```powershell
$env:Path += ';C:\Users\kalki\bin'    # If you rely on shims in the current session
forge create SimpleStorage --private-key 0x<PRIVATE_KEY_HEX> --rpc-url http://127.0.0.1:7545 --broadcast
```

Notes:
- The private keys printed by Anvil are ephemeral and only for local testing. Do NOT use real/private keys from mainnet here.
- If you prefer reproducible keys, stop Anvil and restart with `--mnemonic '<your mnemonic>'`.

Running tests

Run tests from WSL or via `wsl` from PowerShell. Example (from PowerShell):

```powershell
wsl -d Ubuntu -- bash -lc "cd '/mnt/c/Users/kalki/Desktop/3rd year/5th/blockchain/foundry_new' && ~/.foundry/bin/forge test"
```

Using the Windows shims

This workspace includes shims in `C:\Users\kalki\bin` that forward `forge`, `cast` and `anvil` into your Ubuntu WSL. They were created so you can run Foundry commands directly from PowerShell without manually calling `wsl`. To use them:

- Ensure `C:\Users\kalki\bin` is on your PATH (see the `SetEnvironmentVariable` command above).
- Open a new PowerShell session and run `forge --version`, `cast --version` etc.

Troubleshooting
- If PowerShell complains `forge: The term 'forge' is not recognized` — either add the shim folder to PATH or run the command from WSL.
- If `forge create` warns `Dry run enabled, not broadcasting transaction` — add `--broadcast` to actually send the tx.
- If `forge` says `Error accessing local wallet` — provide `--private-key`, `--mnemonic-path`, `--keystore` or run `--interactive` to supply credentials.

Files added by this setup
- `C:\Users\kalki\bin\forge.cmd`, `cast.cmd`, `anvil.cmd` — simple Windows shims that forward commands to WSL (created for convenience).

If you'd like, I can also add a VS Code devcontainer or small PowerShell shortcuts to start Anvil automatically.

Enjoy developing!
## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
