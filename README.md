# sim_eng — Drone Simulation Environment

Three-container setup for drone path-planning simulation with mixed ROS 1 / ROS 2.

## Architecture

```
container_ctrl   (Ubuntu 20.04 + ROS Noetic + MAVROS)            ← planner / PX4Ctrl
       ↕ TCPROS (ROS 1 master at localhost:11311)
container_bridge (Ubuntu 24.04 + ROS 2 Jazzy + Noetic libs + ros1_bridge)
       ↕ DDS (ROS_DOMAIN_ID=42, Fast DDS)
container_sim    (Ubuntu 24.04 + ROS 2 Jazzy + Gazebo Harmonic + PX4 SITL)
```

`container_bridge` and `container_sim` now both run **ROS 2 Jazzy on Ubuntu 24.04**,
so the ROS 2 link between them is same-version DDS rather than the previous
cross-version Humble ↔ Jazzy setup. The bridge picks up Noetic runtime libraries
from the [ros-for-jammy/noble](https://launchpad.net/~ros-for-jammy/+archive/ubuntu/noble)
PPA, and the `ros1_bridge` install tree is COPYed into the image from
`container_bridge/dockerfile/bridge_pkg/ros-jazzy-ros1-bridge/` (pre-built on
the host so the image build doesn't have to compile it).

All three containers run with `--network=host`, so they share the host's
network namespace. ROS 1 master, DDS multicast discovery, and MAVLink UDP
all work transparently between them.

## Directory layout

```
~/sim_eng/
├── container_ctrl/
│   ├── dockerfile/Dockerfile          ← build context for ctrl image
│   └── ws_ctrl/                        ← mounted into ctrl as /home/dev/ws_ctrl
├── container_bridge/
│   ├── dockerfile/
│   │   ├── Dockerfile                  ← build context for bridge image
│   │   └── bridge_pkg/ros-jazzy-ros1-bridge/   ← pre-built bridge install tree
│   └── ws_bridge/                          ← /home/dev/ws_bridge inside container_bridge
├── container_sim/
│   ├── dockerfile/Dockerfile           ← build context for sim image
│   └── ws_sim/                         ← /home/dev/ws_sim inside container_sim
├── scripts/
│   ├── build_all.sh                    ← build all three images, then docker compose up
│   └── docker-compose.yml              ← defines the three services (no build:, uses prebuilt images)
└── README.md
```

## First-time build & launch

```bash
chmod +x ~/sim_eng/scripts/*.sh
~/sim_eng/scripts/build_all.sh
```

`build_all.sh` builds the three images sequentially, runs `xhost +local:docker`
to grant the containers access to the host X server, then `docker compose up -d`
against `scripts/docker-compose.yml`. Expect 30–60 minutes for the first build —
the sim image is the slowest because it clones PX4 and pulls Gazebo Harmonic.

The PX4 SITL `make` step is intentionally skipped at image-build time (it
takes ~30 min and bloats the image). Inside the running sim container:

```bash
cd /opt/PX4-Autopilot && DONT_RUN=1 make px4_sitl gz_x500
```

## Re-running without rebuilding

Once images exist, bring the stack up without rebuilding:

```bash
xhost +local:docker
docker compose -f ~/sim_eng/scripts/docker-compose.yml up -d
```

## Attaching to a container

```bash
docker compose -f ~/sim_eng/scripts/docker-compose.yml exec ctrl   bash
docker compose -f ~/sim_eng/scripts/docker-compose.yml exec bridge bash
docker compose -f ~/sim_eng/scripts/docker-compose.yml exec sim    bash
```

## Inside container_bridge: starting the bridge

The bridge container auto-sources Jazzy and the pre-built `ros1_bridge`
install on shell entry, sets `ROS_MASTER_URI=http://localhost:11311` for the
ROS 1 side, and pins `ROS_DOMAIN_ID=42` / `RMW_IMPLEMENTATION=rmw_fastrtps_cpp`
for the ROS 2 side. To start the bridge:

```bash
# In container_bridge:
roscore &                                   # ROS 1 master (or run in container_ctrl)
ros2 run ros1_bridge dynamic_bridge
```

In practice `roscore` typically runs in `container_ctrl` (the ROS 1 side);
the bridge connects to it over the shared host network at localhost:11311.

## Verifying ROS 2 ↔ ROS 2 connectivity (bridge ↔ sim, both Jazzy)

```bash
# In container_bridge:
ros2 run demo_nodes_cpp talker

# In container_sim:
ros2 topic list      # should show /chatter
ros2 topic echo /chatter
```

If you see messages, the DDS link works.

## Verifying ROS 1 ↔ ROS 2 connectivity (Noetic ↔ Jazzy via bridge)

```bash
# In container_ctrl:
roscore &
rostopic pub /chatter std_msgs/String "data: 'hello from ROS 1'"

# In container_bridge, after starting the bridge:
ros2 topic list      # should show /chatter
ros2 topic echo /chatter std_msgs/msg/String
```

## Workspace mounts

Each container has a host-side working directory bind-mounted into
`/home/dev/ws_<name>`:

| Container         | Host directory                                  | Container path        |
| ----------------- | ----------------------------------------------- | --------------------- |
| `container_ctrl`  | `~/sim_eng/container_ctrl/ws_ctrl`              | `/home/dev/ws_ctrl`   |
| `container_bridge`| `~/sim_eng/container_bridge/ws_bridge`          | `/home/dev/ws_bridge` |
| `container_sim`   | `~/sim_eng/container_sim/ws_sim`                | `/home/dev/ws_sim`    |

Put your source code under the host-side directory so it persists across
container restarts.

## Notes

- `ROS_DOMAIN_ID=42` and `RMW_IMPLEMENTATION=rmw_fastrtps_cpp` are pinned
  on both ROS 2 sides (container_bridge and container_sim) to keep DDS
  vendor and domain consistent.
- The MAVROS geographiclib dataset install is commented out in both the
  ctrl and sim Dockerfiles because `raw.githubusercontent.com` is not
  reachable from the build host. Run the install script inside the
  container if you need GPS / geoid fusion.
- The ros1_bridge install tree must exist at
  `container_bridge/dockerfile/bridge_pkg/ros-jazzy-ros1-bridge/` before
  building the bridge image, otherwise the `COPY` in the Dockerfile fails.
