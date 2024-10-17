redis_module = import_module("github.com/kurtosis-tech/redis-package/main.star")
postgres_module = import_module("github.com/kurtosis-tech/postgres-package/main.star")
constants = import_module("../../package_io/constants.star")
shared_utils = import_module("../../shared_utils/shared_utils.star")
static_files = import_module("../../static_files/static_files.star")

DUMMY_SECRET_KEY = "0x607a11b45a7219cc61a3d9c5fd08c7eebd602a6a19a977f8d3771d5711a550f2"
DUMMY_PUB_KEY = "0xa55c1285d84ba83a5ad26420cd5ad3091e49c55a813eee651cd467db38a8c8e63192f47955e9376f6b42f6d190571cb5"

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
    mev_params,
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

    redis = redis_module.run(
        plan,
        service_name="helix-redis",
        min_cpu=REDIS_MIN_CPU,
        max_cpu=REDIS_MAX_CPU,
        min_memory=REDIS_MIN_MEMORY,
        max_memory=REDIS_MAX_MEMORY,
        node_selectors=node_selectors,
    )
    # making the password postgres as the relay expects it to be postgres
    postgres = postgres_module.run(
        plan,
        password="postgres",
        user="postgres",
        database="postgres",
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

    # print network name

    image = mev_params.helix_image

    env_vars = {
        "GENESIS_FORK_VERSION": constants.GENESIS_FORK_VERSION,
        "BELLATRIX_FORK_VERSION": constants.BELLATRIX_FORK_VERSION,
        "CAPELLA_FORK_VERSION": constants.CAPELLA_FORK_VERSION,
        "DENEB_FORK_VERSION": constants.DENEB_FORK_VERSION,
        "GENESIS_VALIDATORS_ROOT": validator_root,
        "SEC_PER_SLOT": str(seconds_per_slot),
        "LOG_LEVEL": "debug",
        "DB_TABLE_PREFIX": "custom",
    }

    redis_url = "{}:{}".format(redis.hostname, redis.port_number)
    postgres_url = postgres.url + "?sslmode=disable"

    api = plan.add_service(
        name=HELIX_ENDPOINT,
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
    