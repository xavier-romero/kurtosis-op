DEFAULT_PARAMS_FILE = "params.json"
L1_RPC_URL = "http://el-1-geth-lighthouse:8545"
OP_GETH_NAME = "op-geth"
OP_NODE_NAME = "op-node"


def get_config(args):
    params = read_file(src=args.get("config", DEFAULT_PARAMS_FILE))
    args = json.decode(params)
    args["l1_rpc_url"] = L1_RPC_URL

    return args


def op_geth_config(cfg):
    return {
        "name": OP_GETH_NAME,
        "image": cfg.get("images").get(OP_GETH_NAME),
        "cmd": [
            "bash",
            "-c",
            'geth init --state.scheme=hash --datadir=/datadir /in/genesis.json && \
            geth \
            --datadir ./datadir \
            --http \
            --http.corsdomain="*" \
            --http.vhosts="*" \
            --http.addr=0.0.0.0 \
            --http.api=web3,debug,eth,txpool,net,engine \
            --ws \
            --ws.addr=0.0.0.0 \
            --ws.port=8546 \
            --ws.origins="*" \
            --ws.api=debug,eth,txpool,net,engine \
            --syncmode=full \
            --gcmode=archive \
            --nodiscover \
            --maxpeers=0 \
            --networkid=42069 \
            --authrpc.vhosts="*" \
            --authrpc.addr=0.0.0.0 \
            --authrpc.port=8551 \
            --authrpc.jwtsecret=/in/jwt.txt \
            --rollup.disabletxpoolgossip=true',
        ],
        "vars": {},
        "artifacts": ["genesis.json", "jwt.txt"],
        "ports": [
            {"port": 8545, "protocol": "http"},
            {"port": 8546, "protocol": "http"},
        ],
    }


def op_node_config(cfg):
    sequencer_private_key = cfg.get("addresses").get("sequencer").get("private_key")
    return {
        "name": OP_NODE_NAME,
        "image": cfg.get("images").get(OP_NODE_NAME),
        "cmd": [
            "bash",
            "-c",
            "op-node \
            --l2=http://"
            + OP_GETH_NAME
            + ":8551 \
            --l2.jwt-secret=/in/jwt.txt \
            --sequencer.enabled \
            --sequencer.l1-confs=5 \
            --verifier.l1-confs=4 \
            --rollup.config=/in/rollup.json \
            --rpc.addr=0.0.0.0 \
            --p2p.disable \
            --rpc.enable-admin \
            --p2p.sequencer.key="
            + sequencer_private_key
            + " \
            --l1="
            + L1_RPC_URL
            + " \
            --l1.rpckind=debug_geth",
        ],
        "vars": {},
        "artifacts": ["rollup.json", "jwt.txt"],
    }


def op_batcher_config(cfg):
    batcher_private_key = cfg.get("addresses").get("batcher").get("private_key")
    return {
        "name": "op-batcher",
        "image": cfg.get("images").get("op-batcher"),
        "cmd": [
            "bash",
            "-c",
            "op-batcher \
            --l2-eth-rpc=http://"
            + OP_GETH_NAME
            + ":8545 \
            --rollup-rpc=http://"
            + OP_NODE_NAME
            + ":9545 \
            --poll-interval=1s \
            --sub-safety-margin=6 \
            --num-confirmations=1 \
            --safe-abort-nonce-too-low-count=3 \
            --resubmission-timeout=30s \
            --rpc.addr=0.0.0.0 \
            --rpc.port=8548 \
            --rpc.enable-admin \
            --max-channel-duration=25 \
            --l1-eth-rpc="
            + L1_RPC_URL
            + " \
            --private-key="
            + batcher_private_key,
        ],
        "vars": {},
        "artifacts": [],
    }


def op_proposer(cfg):
    proposer_private_key = cfg.get("addresses").get("proposer").get("private_key")
    deploy_file = "{}.deploy".format(cfg["l1"]["chain_id"])
    return {
        "name": "op-proposer",
        "image": cfg.get("images").get("op-proposer"),
        "cmd": [
            "bash",
            "-c",
            "op-proposer \
            --poll-interval=12s \
            --rpc.port=8560 \
            --rollup-rpc=http://"
            + OP_NODE_NAME
            + ":9545 \
            --l2oo-address=$(cat "
            + deploy_file
            + " | jq -r .L2OutputOracleProxy) \
            --private-key="
            + proposer_private_key
            + " \
            --l1-eth-rpc="
            + L1_RPC_URL,
        ],
        "vars": {},
        "artifacts": [deploy_file],
    }
