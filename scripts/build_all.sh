#!/bin/bash
# ============================================================
# build_all.sh — build all three sim_eng Docker images, then
# bring the stack up via docker compose.
# Run this from anywhere; it figures out paths from its own location.
# ============================================================
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SIM_ENG_DIR="$( dirname "$SCRIPT_DIR" )"
YAML="$SIM_ENG_DIR/scripts/docker-compose.yml"

# If invoked under sudo, SUDO_UID/SUDO_GID hold the *real* calling user's
# IDs. Fall back to id -u/-g for normal (non-sudo) invocation. Without this,
# `sudo ./build_all.sh` would bake UID=0/GID=0 into the image and collide
# with the existing root group inside the container.
USER_UID=${SUDO_UID:-$(id -u)}
USER_GID=${SUDO_GID:-$(id -g)}

echo "=========================================="
echo "Building sim_eng Docker images"
echo "Host UID:GID = $USER_UID:$USER_GID"
echo "=========================================="

# ------------------------------------------------------------
# 1/3 — container_ctrl
#       Ubuntu 20.04 + ROS Noetic + MAVROS (planner / PX4Ctrl side)
# ------------------------------------------------------------
echo
echo "--- [1/3] Building sim_eng/ctrl:v1.0 ---"
docker build \
    --build-arg USER_UID=$USER_UID \
    --build-arg USER_GID=$USER_GID \
    -t sim_eng/ctrl:v1.0 \
    -f "$SIM_ENG_DIR/container_ctrl/dockerfile/Dockerfile" \
    "$SIM_ENG_DIR/container_ctrl/dockerfile"

# ------------------------------------------------------------
# 2/3 — container_bridge
#       Ubuntu 24.04 + ROS 2 Jazzy + Noetic libs (ros-for-jammy/noble PPA)
#       + pre-built ros1_bridge install tree (COPYed in from bridge_pkg/)
# ------------------------------------------------------------
echo
echo "--- [2/3] Building sim_eng/bridge:v1.0 ---"
docker build \
    --build-arg USER_UID=$USER_UID \
    --build-arg USER_GID=$USER_GID \
    -t sim_eng/bridge:v1.0 \
    -f "$SIM_ENG_DIR/container_bridge/dockerfile/Dockerfile" \
    "$SIM_ENG_DIR/container_bridge/dockerfile"

# ------------------------------------------------------------
# 3/3 — container_sim
#       Ubuntu 24.04 + ROS 2 Jazzy + Gazebo Harmonic + PX4 source
# ------------------------------------------------------------
echo
echo "--- [3/3] Building sim_eng/sim:v1.0 ---"
docker build \
    --build-arg USER_UID=$USER_UID \
    --build-arg USER_GID=$USER_GID \
    -t sim_eng/sim:v1.0 \
    -f "$SIM_ENG_DIR/container_sim/dockerfile/Dockerfile" \
    "$SIM_ENG_DIR/container_sim/dockerfile"

echo
echo "=========================================="
echo "All three images built:"
docker images | grep '^sim_eng/'
echo "=========================================="

# ------------------------------------------------------------
# Grant the local Docker daemon access to the host X server so GUI
# apps inside the containers (rviz, Gazebo, rqt) can draw on the host.
# ------------------------------------------------------------
echo
echo "--- Granting Docker access to host X server ---"
xhost +local:docker

# ------------------------------------------------------------
# Bring the stack up using the Compose file.
# ------------------------------------------------------------
echo
echo "--- Starting the stack with docker compose up ---"
docker compose -f "$YAML" up -d

echo
echo "=========================================="
echo "Stack is up. Attach to a container with:"
echo "  docker compose -f $YAML exec ctrl   bash"
echo "  docker compose -f $YAML exec bridge bash"
echo "  docker compose -f $YAML exec sim    bash"
echo
echo "Stop the stack with:"
echo "  docker compose -f $YAML down"
echo "=========================================="
