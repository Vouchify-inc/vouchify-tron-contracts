require("dotenv").config();

function normalizePrivateKey(value) {
    if (!value) {
        return undefined;
    }

    return value.startsWith("0x") || value.startsWith("0X") ? value.slice(2) : value;
}

function networkConfig({ privateKey, fullHost, networkId, userFeePercentage = 100 }) {
    return {
        privateKey: normalizePrivateKey(privateKey),
        userFeePercentage,
        feeLimit: 1_000 * 1e6,
        originEnergyLimit: 10_000_000,
        callValue: 0,
        fullHost,
        network_id: networkId
    };
}

module.exports = {
    contracts_directory: "./src",
    contracts_build_directory: "./build/contracts",
    migrations_directory: "./migrations",
    networks: {
        development: networkConfig({
            privateKey: process.env.PRIVATE_KEY_DEV || process.env.PRIVATE_KEY,
            fullHost: process.env.TRON_DEV_FULL_HOST || "http://127.0.0.1:9090",
            networkId: "*",
            userFeePercentage: 0
        }),
        shasta: networkConfig({
            privateKey: process.env.PRIVATE_KEY_SHASTA || process.env.PRIVATE_KEY,
            fullHost: process.env.TRON_SHASTA_RPC_URL || "https://api.shasta.trongrid.io",
            networkId: "2",
            userFeePercentage: 50
        }),
        nile: networkConfig({
            privateKey: process.env.PRIVATE_KEY_NILE || process.env.PRIVATE_KEY,
            fullHost: process.env.TRON_NILE_RPC_URL || "https://nile.trongrid.io",
            networkId: "3",
            userFeePercentage: 100
        }),
        mainnet: networkConfig({
            privateKey: process.env.PRIVATE_KEY_MAINNET || process.env.PRIVATE_KEY,
            fullHost: process.env.TRON_MAINNET_RPC_URL || "https://api.trongrid.io",
            networkId: "*",
            userFeePercentage: 100
        })
    },
    compilers: {
        solc: {
            version: "0.8.24",
            settings: {
                optimizer: {
                    enabled: true,
                    runs: 200
                },
                evmVersion: "cancun",
                viaIR: true
            }
        }
    }
};