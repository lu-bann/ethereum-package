redis_module = import_module("github.com/kurtosis-tech/redis-package/main.star")
postgres_module = import_module("github.com/kurtosis-tech/postgres-package/main.star")
constants = import_module("../../package_io/constants.star")
shared_utils = import_module("../../shared_utils/shared_utils.star")
static_files = import_module("../../static_files/static_files.star")

DUMMY_SECRET_KEY = "0x607a11b45a7219cc61a3d9c5fd08c7eebd602a6a19a977f8d3771d5711a550f2"
DUMMY_PUB_KEY = "0xa55c1285d84ba83a5ad26420cd5ad3091e49c55a813eee651cd467db38a8c8e63192f47955e9376f6b42f6d190571cb5"

IMAGE = "lubann/helix:latest"

POSTGRES_PORT_ID = "postgres"
POSTGRES_PORT_NUMBER = 5432
POSTGRES_DB = "db"
POSTGRES_USER = "postgres"
POSTGRES_PASSWORD = "pass"

HELIX_ENDPOINT_PORT = 9062
LAUNCH_ADMINER = True

# The min/max CPU/memory that mev-relay can use
RELAY_MIN_CPU = 100
RELAY_MAX_CPU = 1000
RELAY_MIN_MEMORY = 128
RELAY_MAX_MEMORY = 1024

# The min/max CPU/memory that postgres can use
POSTGRES_MIN_CPU = 10
POSTGRES_MAX_CPU = 1000
POSTGRES_MIN_MEMORY = 32
POSTGRES_MAX_MEMORY = 1024

# The min/max CPU/memory that redis can use
REDIS_MIN_CPU = 10
REDIS_MAX_CPU = 1000
REDIS_MIN_MEMORY = 16
REDIS_MAX_MEMORY = 1024


def launch_helix(
    plan,
    config_template,
    network_id,
    beacon_uris,
    validator_root,
    builder_uri,
    seconds_per_slot,
    persistent,
    global_node_selectors,
):
    node_selectors = global_node_selectors

     # Read the template files with Helix configuration and network configuration
    helix_config_template = read_file(
        static_files.HELIX_CONFIG_TEMPLATE_FILEPATH
    )
    helix_network_config_template = read_file(
        static_files.HELIX_NETWORK_CONFIG_TEMPLATE_FILEPATH
    )
    plan.print("Successfully launching helix redis")
    redis = redis_module.run(
        plan,
        service_name="helix-redis",
        min_cpu=REDIS_MIN_CPU,
        max_cpu=REDIS_MAX_CPU,
        min_memory=REDIS_MIN_MEMORY,
        max_memory=REDIS_MAX_MEMORY,
        node_selectors=node_selectors,
    )
    plan.print("Successfully launched helix redis")
    # making the password postgres as the relay expects it to be postgres
    postgres = postgres_module.run(
        plan,
        password=POSTGRES_PASSWORD,
        user=POSTGRES_USER,
        database=POSTGRES_DB,
        service_name="helix-postgres",
        persistent=persistent,
        launch_adminer=LAUNCH_ADMINER,
        min_cpu=POSTGRES_MIN_CPU,
        max_cpu=POSTGRES_MAX_CPU,
        min_memory=POSTGRES_MIN_MEMORY,
        max_memory=POSTGRES_MAX_MEMORY,
        node_selectors=node_selectors,
        image="timescale/timescaledb-ha:pg16",
    )
    plan.print("Successfully launched helix postgres")
    # print network name
    redis_url = "{}:{}".format(redis.hostname, redis.port_number)

    template_data = {
        "Hostname": postgres.hostname,
        "Port": postgres.port_number,
        "DbName": POSTGRES_DB,
        "User": POSTGRES_USER,
        "Password": POSTGRES_PASSWORD,
        "Region": 0,
        "RegionName": "",
        "RedisUrl": redis_url,
        "BeaconClientUrl": "",
        "SimulatorUrl": "",
        "NetworkDirPath": "",
        "GenesisValidatorRoot": validator_root,
        "GenesisTime": str(seconds_per_slot),
    }

    template_and_data = shared_utils.new_template_and_data(
        config_template, template_data
    )


    api = plan.add_service(
        name="helix-relay",
        config=ServiceConfig(
            image=image,
            files={
                HELIX_CONFIG_MOUNT_DIRPATH_ON_SERVICE: config_files_artifact_name
            },
            cmd=[
                "--config",
                shared_utils.path_join(
                    HELIX_CONFIG_MOUNT_DIRPATH_ON_SERVICE,
                    HELIX_CONFIG_FILENAME,
                )
            ],
            ports={
                "api": PortSpec(
                    number=HELIX_RELAY_ENDPOINT_PORT, transport_protocol="TCP"
                )
            },
            env_vars=env_vars,
            min_cpu=RELAY_MIN_CPU,
            max_cpu=RELAY_MAX_CPU,
            min_memory=RELAY_MIN_MEMORY,
            max_memory=RELAY_MAX_MEMORY,
            node_selectors=node_selectors,
        ),
    )

    return "http://{0}@{1}:{2}".format(
        DUMMY_PUB_KEY, api.ip_address, HELIX_ENDPOINT_PORT
    )

def new_helix_config(
    plan,
    service_name,
    network,
    fee_recipient,
    mnemonic,
    extra_data,
    global_node_selectors,
):

def new_helix_config_template_data(
    hostname,
    port,
    db_name,
    user,
    password,
    ssl_mode,
    region,
    region_name,
    redis_url,
    broadcast_url,
    simulator_url,
    beacon_client_url,
    dir_path,
    genesis_validator_root,
    genesis_time,
):
    