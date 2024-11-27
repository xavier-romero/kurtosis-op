config_package = "./config.star"
ethereum_package = "./external/ethereum.star"
tools_package = "./tools.star"
op_geth_package = "./op-geth.star"
service_package = "./service.star"


def run(plan, args):
    # Import config
    cfg = import_module(config_package).get_config(args)

    # Deploy L1
    import_module(ethereum_package).run(plan, cfg.get("l1"))

    # Deploy tools image
    tools_config = {
        "addresses": cfg["addresses"],
        "l1_rpc_url": cfg["l1_rpc_url"],
        "l1_preallocated_mnemonic": cfg["l1"].get("preallocated_mnemonic"),
        "l1_chainid": cfg["l1"]["chain_id"],
        "l2_chainid": cfg["l2"]["chain_id"],
        "l1_blocktime": cfg["l1"]["seconds_per_slot"],
        "l2_blocktime": cfg["l2"]["blocktime"],
    }
    import_module(tools_package).run(plan, tools_config)

    # Wait for L1 to be ready
    import_module(tools_package).execute_step(plan, "wait_for_l1")

    # Fund accounts on L1
    import_module(tools_package).execute_step(plan, "fund_accounts_on_l1")

    # Wait for L1 to have finalized blocks
    import_module(tools_package).execute_step(plan, "wait_for_l1_finalized_blocks")

    # Deploy contracts
    import_module(tools_package).execute_step(plan, "deploy_contracts")

    # Generate L2 config
    import_module(tools_package).execute_step(plan, "generate_l2_config")

    # Save artifacts
    import_module(tools_package).save_artifacts(
        plan, {"l1_chainid": cfg["l1"]["chain_id"]}
    )

    # Deploy op-geth
    import_module(service_package).run(
        plan, import_module(config_package).op_geth_config(cfg)
    )

    # Deploy op-node
    import_module(service_package).run(
        plan, import_module(config_package).op_node_config(cfg)
    )

    # Deploy op-batcher
    import_module(service_package).run(
        plan, import_module(config_package).op_batcher_config(cfg)
    )
