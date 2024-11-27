TOOLS_IMAGE = "xavierromero/tool-op:latest"
SERVICE_NAME = "tools"
ARTIFACTS_IN = [
    {
        "name": "wait_for_l1.sh",
        "file": "./scripts/wait_for_l1.sh",
    },
    {
        "name": "fund_accounts_on_l1.sh",
        "file": "./scripts/fund_accounts_on_l1.sh",
    },
    {
        "name": "wait_for_l1_finalized_blocks.sh",
        "file": "./scripts/wait_for_l1_finalized_blocks.sh",
    },
    {
        "name": "deploy_contracts.sh",
        "file": "./scripts/deploy_contracts.sh",
    },
    {
        "name": "generate_l2_config.sh",
        "file": "./scripts/generate_l2_config.sh",
    },
]
ARTIFACTS_OUT = {
    "path": "/out",
    "files": ["genesis.json", "rollup.json", "jwt.txt", "deploy_config.json"],
}


def run(plan, cfg):
    artifacts = []
    for artifact_cfg in ARTIFACTS_IN:
        template = read_file(src=artifact_cfg["file"])
        artifact = plan.render_templates(
            name=artifact_cfg["name"],
            config={artifact_cfg["name"]: struct(template=template, data=cfg)},
        )
        artifacts.append(artifact)

    plan.add_service(
        name=SERVICE_NAME,
        config=ServiceConfig(
            image=TOOLS_IMAGE,
            files={
                "/out": Directory(persistent_key="tools-out"),
                "/in/": Directory(artifact_names=artifacts),
            },
            # These two lines are only necessary to deploy to any Kubernetes environment (e.g. GKE).
            entrypoint=["bash", "-c"],
            env_vars={"PS1": "tools"},  # To allow .bashrc to be loaded on each exec.
            cmd=["sleep infinity"],
            user=User(uid=0, gid=0),  # Run the container as root user.
        ),
    )


def execute_step(plan, step):
    script = "/in/{}.sh".format(step)
    plan.exec(
        description="Executing {}".format(step),
        service_name=SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/bash",
                "-c",
                "chmod +x {0} && {0}".format(script),
            ]
        ),
    )


def save_artifacts(plan, cfg):
    for artifact_to_save in ARTIFACTS_OUT["files"]:
        plan.store_service_files(
            service_name=SERVICE_NAME,
            name=artifact_to_save,
            src="{}/{}".format(ARTIFACTS_OUT["path"], artifact_to_save),
            description="Storing {}".format(artifact_to_save),
        )

    extra_artifacts = ["{}.deploy".format(cfg["l1_chainid"])]

    for artifact_to_save in extra_artifacts:
        plan.store_service_files(
            service_name=SERVICE_NAME,
            name=artifact_to_save,
            src="{}/{}".format(ARTIFACTS_OUT["path"], artifact_to_save),
            description="Storing {}".format(artifact_to_save),
        )
