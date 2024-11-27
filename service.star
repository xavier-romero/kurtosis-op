# cfg = {
#     "name": "op-geth",
#     "image": "xavierromero/op-geth:latest",
#     "cmd": [
#         "op-geth",
#     ],
#     "vars": {},
#     "artifacts": [],
#     "ports": [
#         {
#             "port": 8545
#         },
#         {
#             "port": 123,
#             "protocol": "tcp",
#         },
#     ]
# }


def run(plan, cfg):
    service_name = cfg.get("name")
    service_image = cfg.get("image")
    service_vars = cfg.get("vars", {})
    service_files = {
        "/in": Directory(
            artifact_names=[
                plan.get_files_artifact(_artifact)
                for _artifact in cfg.get("artifacts", [])
            ]
        )
    }
    service_cmd = cfg.get("cmd", [])
    service_ports = cfg.get("ports", {})

    service_config = ServiceConfig(
        image=service_image,
        ports={
            "{}{}".format(service_name, service_port["port"]): PortSpec(
                service_port["port"],
                application_protocol=service_port.get("protocol", "http"),
                wait="20s",
            )
            for service_port in service_ports
        },
        env_vars=service_vars,
        files=service_files,
        cmd=service_cmd,
    )

    plan.add_service(
        name=service_name,
        config=service_config,
        description="Adding service {}".format(service_name),
    )
