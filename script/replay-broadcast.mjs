#!/usr/bin/env node

import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { spawnSync } from "node:child_process";

const usage = `
Replay a Foundry broadcast JSON file with cast send.

Usage:
  node script/replay-broadcast.mjs \
    --broadcast broadcast/Deploy.s.sol/9745/run-latest.json \
    --rpc-url https://plasma-mainnet.g.alchemy.com/v2/your-key \
    --private-key 0x... \
    [--start-index 0] \
    [--count 999] \
    [--legacy] \
    [--dry-run]

Options:
  --broadcast    Path to the Foundry broadcast JSON file.
  --rpc-url      Target RPC URL.
  --private-key  Signer private key used by cast send.
  --start-index  Zero-based transaction index to start from.
  --count        Number of transactions to replay from start-index.
  --legacy       Send legacy transactions instead of EIP-1559.
  --dry-run      Print the cast commands without sending them.
`;

function parseArgs(argv) {
  const args = {
    startIndex: 0,
    count: Number.POSITIVE_INFINITY,
    legacy: false,
    dryRun: false,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];

    if (arg === "--legacy") {
      args.legacy = true;
      continue;
    }

    if (arg === "--dry-run") {
      args.dryRun = true;
      continue;
    }

    const value = argv[index + 1];
    if (!value || value.startsWith("--")) {
      throw new Error(`Missing value for ${arg}`);
    }

    switch (arg) {
      case "--broadcast":
        args.broadcast = value;
        break;
      case "--rpc-url":
        args.rpcUrl = value;
        break;
      case "--private-key":
        args.privateKey = value;
        break;
      case "--start-index":
        args.startIndex = Number(value);
        break;
      case "--count":
        args.count = Number(value);
        break;
      default:
        throw new Error(`Unknown argument: ${arg}`);
    }

    index += 1;
  }

  if (!args.broadcast || !args.rpcUrl || !args.privateKey) {
    throw new Error("--broadcast, --rpc-url, and --private-key are required");
  }

  if (!Number.isInteger(args.startIndex) || args.startIndex < 0) {
    throw new Error("--start-index must be a non-negative integer");
  }

  if (!Number.isInteger(args.count) || args.count < 1) {
    throw new Error("--count must be a positive integer");
  }

  return args;
}

function toDecimalString(value, fallback = "0") {
  if (value === undefined || value === null || value === "") {
    return fallback;
  }

  if (typeof value === "number") {
    return String(value);
  }

  return String(BigInt(value));
}

function buildCastArgs(tx, options) {
  const txData = tx.transaction || {};
  const args = [
    "send",
    "--rpc-url",
    options.rpcUrl,
    "--private-key",
    options.privateKey,
    "--nonce",
    toDecimalString(txData.nonce),
    "--gas-limit",
    toDecimalString(txData.gas),
    "--value",
    toDecimalString(txData.value),
  ];

  if (options.legacy) {
    args.push("--legacy");
  }

  if (tx.transactionType === "CREATE") {
    args.push("--create", txData.input);
    return args;
  }

  if (tx.transactionType === "CALL") {
    if (!txData.to) {
      throw new Error("CALL transaction is missing a target address");
    }
    args.push(txData.to, "--data", txData.input || "0x");
    return args;
  }

  throw new Error(`Unsupported transaction type: ${tx.transactionType}`);
}

function quoteArg(arg) {
  if (/^[A-Za-z0-9_./:-]+$/.test(arg)) {
    return arg;
  }
  return `'${arg.replace(/'/g, `'\\''`)}'`;
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  const broadcastPath = resolve(process.cwd(), args.broadcast);
  const broadcast = JSON.parse(readFileSync(broadcastPath, "utf8"));
  const transactions = Array.isArray(broadcast.transactions) ? broadcast.transactions : [];

  const selected = transactions.slice(args.startIndex, args.startIndex + args.count);
  if (selected.length === 0) {
    throw new Error("No transactions matched the requested range");
  }

  console.log(`Loaded ${transactions.length} broadcast transactions from ${broadcastPath}`);
  console.log(`Replaying ${selected.length} transaction(s) starting at index ${args.startIndex}`);

  selected.forEach((tx, offset) => {
    const absoluteIndex = args.startIndex + offset;
    const castArgs = buildCastArgs(tx, args);
    const printableCommand = ["cast", ...castArgs]
      .map((part) => quoteArg(part))
      .join(" ");

    console.log(`\n[${absoluteIndex}] ${tx.transactionType} ${tx.contractName || "UnknownContract"}`);
    console.log(printableCommand);

    if (args.dryRun) {
      return;
    }

    const result = spawnSync("cast", castArgs, {
      encoding: "utf8",
      stdio: "pipe",
    });

    if (result.stdout.trim()) {
      console.log(result.stdout.trim());
    }

    if (result.status !== 0) {
      if (result.stderr.trim()) {
        console.error(result.stderr.trim());
      }
      throw new Error(`cast send failed at transaction index ${absoluteIndex}`);
    }
  });

  console.log("\nReplay completed successfully.");
}

try {
  main();
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  console.error(usage.trim());
  process.exit(1);
}