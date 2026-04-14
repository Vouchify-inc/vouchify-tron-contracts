require("dotenv").config();

const { HDNodeWallet } = require("ethers");
const TronWebModule = require("tronweb");

const TronWeb = TronWebModule.TronWeb || TronWebModule;
const DEFAULT_BASE_PATH = "m/44'/195'/0'/0";

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

function toInteger(value, fallback) {
    if (value === undefined) {
        return fallback;
    }

    const parsed = Number.parseInt(value, 10);

    if (Number.isNaN(parsed) || parsed < 0) {
        throw new Error(`Invalid integer value: ${value}`);
    }

    return parsed;
}

function usage() {
    console.log("Usage:");
    console.log("  npm run derive:key -- --mnemonic \"word1 word2 ...\" --index 0");
    console.log("  npm run derive:key -- --target TPDHWhsBtGwTk62s5vbKubB5RqkXbfKLuD --from 0 --to 20");
    console.log("");
    console.log("Options:");
    console.log("  --mnemonic   Seed phrase. Falls back to TRON_MNEMONIC from .env if omitted.");
    console.log(`  --path       Base derivation path. Defaults to ${DEFAULT_BASE_PATH}`);
    console.log("  --index      Child index to derive. Defaults to 0.");
    console.log("  --from       Starting index when searching for --target. Defaults to 0.");
    console.log("  --to         Ending index when searching for --target. Defaults to --from.");
    console.log("  --target     TRON address to search for across the index range.");
}

function deriveAccount(mnemonic, basePath, index) {
    const path = `${basePath}/${index}`;
    const wallet = HDNodeWallet.fromPhrase(mnemonic, undefined, path);
    const privateKey = wallet.privateKey.replace(/^0x/i, "");
    const address = TronWeb.address.fromPrivateKey(privateKey);

    return {
        index,
        path,
        privateKey,
        address
    };
}

function printAccount(account) {
    console.log(`index: ${account.index}`);
    console.log(`path: ${account.path}`);
    console.log(`address: ${account.address}`);
    console.log(`privateKey: ${account.privateKey}`);
}

function main() {
    const options = parseArgs(process.argv.slice(2));

    if (options.help) {
        usage();
        return;
    }

    const mnemonic = options.mnemonic || process.env.TRON_MNEMONIC;

    if (!mnemonic) {
        throw new Error("Missing mnemonic. Pass --mnemonic or set TRON_MNEMONIC in .env.");
    }

    const basePath = options.path || DEFAULT_BASE_PATH;

    if (options.target) {
        const fromIndex = toInteger(options.from, 0);
        const toIndex = toInteger(options.to, fromIndex);
        const target = options.target.trim();

        if (toIndex < fromIndex) {
            throw new Error("--to must be greater than or equal to --from.");
        }

        for (let index = fromIndex; index <= toIndex; index += 1) {
            const account = deriveAccount(mnemonic, basePath, index);

            if (account.address === target) {
                console.log("Match found.");
                printAccount(account);
                return;
            }
        }

        console.log(`No match found for ${target} in ${basePath}/[${fromIndex}..${toIndex}].`);
        return;
    }

    const index = toInteger(options.index, 0);
    const account = deriveAccount(mnemonic, basePath, index);
    printAccount(account);
}

try {
    main();
} catch (error) {
    console.error(error.message);
    process.exitCode = 1;
}