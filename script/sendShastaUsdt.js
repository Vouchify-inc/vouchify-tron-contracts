require("dotenv").config();

const TronWebModule = require("tronweb");

const TronWeb = TronWebModule.TronWeb || TronWebModule;
const USDT_ABI = [
    {
        name: "decimals",
        type: "function",
        stateMutability: "view",
        inputs: [],
        outputs: [{ type: "uint8" }]
    },
    {
        name: "symbol",
        type: "function",
        stateMutability: "view",
        inputs: [],
        outputs: [{ type: "string" }]
    },
    {
        name: "balanceOf",
        type: "function",
        stateMutability: "view",
        inputs: [{ name: "account", type: "address" }],
        outputs: [{ type: "uint256" }]
    },
    {
        name: "transfer",
        type: "function",
        stateMutability: "nonpayable",
        inputs: [
            { name: "to", type: "address" },
            { name: "value", type: "uint256" }
        ],
        outputs: [{ type: "bool" }]
    }
];

function parseArgs(argv) {
    const options = {};

    for (let index = 0; index < argv.length; index += 1) {
        const token = argv[index];

        if (!token.startsWith("--")) {
            continue;
        }

        const key = token.slice(2);
        const next = argv[index + 1];

        if (!next || next.startsWith("--")) {
            options[key] = true;
            continue;
        }

        options[key] = next;
        index += 1;
    }

    return options;
}

function usage() {
    console.log("Usage:");
    console.log("  npm run send:usdt:shasta -- --to T... --amount 12.5");
    console.log("");
    console.log("Options:");
    console.log("  --to             Recipient Tron address in base58.");
    console.log("  --amount         Human-readable USDT amount, for example 1 or 12.5.");
    console.log("  --key-env        Env var holding the sender private key. Defaults to PRIVATE_KEY_SHASTA, then PRIVATE_KEY.");
    console.log("  --token-env      Env var holding the TRC20 token address. Defaults to TRON_USDT_TOKEN.");
    console.log("  --rpc-env        Env var holding the Shasta RPC URL. Defaults to TRON_SHASTA_RPC_URL.");
    console.log("  --fee-limit      Fee limit in sun. Defaults to 100000000.");
    console.log("  --decimals       Override token decimals instead of reading them from chain.");
    console.log("  --dry-run        Validate inputs and print the transaction plan without broadcasting.");
    console.log("  --help           Show this help output.");
}

function normalizePrivateKey(value) {
    if (!value) {
        return undefined;
    }

    return value.startsWith("0x") || value.startsWith("0X") ? value.slice(2) : value;
}

function requireEnv(name) {
    const value = process.env[name];

    if (!value) {
        throw new Error(`Missing required environment variable: ${name}`);
    }

    return value.trim();
}

function parsePositiveInteger(value, name) {
    const parsed = Number.parseInt(value, 10);

    if (!Number.isFinite(parsed) || parsed <= 0) {
        throw new Error(`${name} must be a positive integer.`);
    }

    return parsed;
}

function parseAmountToBaseUnits(amount, decimals) {
    if (typeof amount !== "string" || amount.trim() === "") {
        throw new Error("--amount is required.");
    }

    const normalized = amount.trim();

    if (!/^\d+(\.\d+)?$/.test(normalized)) {
        throw new Error(`Invalid amount: ${amount}`);
    }

    const [wholePart, fractionPart = ""] = normalized.split(".");

    if (fractionPart.length > decimals) {
        throw new Error(`Amount ${amount} has more than ${decimals} decimal places.`);
    }

    const whole = BigInt(wholePart) * 10n ** BigInt(decimals);
    const fraction = BigInt((fractionPart + "0".repeat(decimals)).slice(0, decimals));
    const units = whole + fraction;

    if (units <= 0n) {
        throw new Error("Amount must be greater than zero.");
    }

    return units;
}

function formatUnits(value, decimals) {
    const base = BigInt(value);
    const divisor = 10n ** BigInt(decimals);
    const whole = base / divisor;
    const fraction = (base % divisor).toString().padStart(decimals, "0").replace(/0+$/, "");

    return fraction ? `${whole}.${fraction}` : whole.toString();
}

async function getTokenMetadata(contract, fallbackDecimals) {
    let symbol = "USDT";
    let decimals = fallbackDecimals;

    if (decimals === undefined) {
        try {
            const decimalsResult = await contract.decimals().call();
            decimals = Number.parseInt(decimalsResult.toString(), 10);
        } catch (error) {
            decimals = 6;
        }
    }

    try {
        const symbolResult = await contract.symbol().call();
        if (symbolResult) {
            symbol = symbolResult.toString();
        }
    } catch (error) {
        symbol = "USDT";
    }

    return { symbol, decimals };
}

async function main() {
    const options = parseArgs(process.argv.slice(2));

    if (options.help) {
        usage();
        return;
    }

    const recipient = options.to;

    if (!recipient) {
        throw new Error("Missing required --to recipient address.");
    }

    if (!TronWeb.isAddress(recipient)) {
        throw new Error(`Invalid Tron recipient address: ${recipient}`);
    }

    const keyEnvName = options["key-env"] || (process.env.PRIVATE_KEY_SHASTA ? "PRIVATE_KEY_SHASTA" : "PRIVATE_KEY");
    const tokenEnvName = options["token-env"] || "TRON_USDT_TOKEN";
    const rpcEnvName = options["rpc-env"] || "TRON_SHASTA_RPC_URL";
    const privateKey = normalizePrivateKey(requireEnv(keyEnvName));
    const fullHost = requireEnv(rpcEnvName);
    const tokenAddress = requireEnv(tokenEnvName);

    if (!TronWeb.isAddress(tokenAddress)) {
        throw new Error(`Invalid token address from ${tokenEnvName}: ${tokenAddress}`);
    }

    const headers = process.env.TRONGRID_API_KEY
        ? { "TRON-PRO-API-KEY": process.env.TRONGRID_API_KEY }
        : undefined;

    const tronWeb = new TronWeb({
        fullHost,
        headers,
        privateKey
    });

    const sender = TronWeb.address.fromPrivateKey(privateKey);

    if (!sender) {
        throw new Error(`Unable to derive sender address from ${keyEnvName}.`);
    }

    const contract = tronWeb.contract(USDT_ABI, tokenAddress);
    const requestedDecimals = options.decimals === undefined
        ? undefined
        : parsePositiveInteger(options.decimals, "--decimals");
    const { symbol, decimals } = await getTokenMetadata(contract, requestedDecimals);
    const amountInBaseUnits = parseAmountToBaseUnits(options.amount, decimals);
    const feeLimit = options["fee-limit"] === undefined
        ? 100_000_000
        : parsePositiveInteger(options["fee-limit"], "--fee-limit");

    const senderBalanceBefore = BigInt((await contract.balanceOf(sender).call()).toString());

    if (senderBalanceBefore < amountInBaseUnits) {
        throw new Error(
            `Insufficient ${symbol} balance. Sender has ${formatUnits(senderBalanceBefore, decimals)} ${symbol} but needs ${formatUnits(amountInBaseUnits, decimals)} ${symbol}.`
        );
    }

    console.log(`Network RPC: ${fullHost}`);
    console.log(`Token (${tokenEnvName}): ${tokenAddress}`);
    console.log(`Sender (${keyEnvName}): ${sender}`);
    console.log(`Recipient: ${recipient}`);
    console.log(`Amount: ${formatUnits(amountInBaseUnits, decimals)} ${symbol}`);
    console.log(`Fee limit: ${feeLimit} sun`);
    console.log(`Sender balance before: ${formatUnits(senderBalanceBefore, decimals)} ${symbol}`);

    if (options["dry-run"]) {
        console.log("Dry run only. No transaction broadcast.");
        return;
    }

    const txid = await contract.transfer(recipient, amountInBaseUnits.toString()).send({
        feeLimit,
        shouldPollResponse: false
    });

    console.log(`Broadcast txid: ${txid}`);
    console.log(`Tronscan: https://shasta.tronscan.org/#/transaction/${txid}`);
}

main().catch((error) => {
    console.error(error.message || error);
    process.exitCode = 1;
});