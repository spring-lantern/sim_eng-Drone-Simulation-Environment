# ============================================================
# container_sim
# Base: osrf/ros:jazzy-desktop-full (Ubuntu 24.04 + ROS 2 Jazzy)
# Role: physics simulation (Gazebo Harmonic) + PX4 SITL flight stack,
#       publishing sensor data (LiDAR, camera, IMU) over ROS 2 / DDS.
# ============================================================
FROM osrf/ros:jazzy-desktop-full

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

# ------------------------------------------------------------
# Gazebo Harmonic via the ROS 2 vendor packages (officially paired
# with Jazzy). Plus MAVROS-2 for parity with the ctrl side, and
# Nav2 stack which most drone planners depend on.
# ------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-jazzy-ros-gz \
    ros-jazzy-ros-gz-bridge \
    ros-jazzy-ros-gz-sim \
    ros-jazzy-ros-gz-interfaces \
    ros-jazzy-mavros \
    ros-jazzy-mavros-extras \
    ros-jazzy-mavros-msgs \
    ros-jazzy-nav2-bringup \
    ros-jazzy-robot-localization \
    ros-jazzy-rmw-fastrtps-cpp \
    ros-jazzy-rqt \
    ros-jazzy-rqt-common-plugins \
    ros-jazzy-rviz2 \
    python3-colcon-common-extensions \
    python3-vcstool \
    python3-rosdep \
    python3-pip \
    build-essential cmake \
    git wget curl nano vim sudo \
    iputils-ping net-tools \
    libgl1-mesa-dri mesa-utils \
 && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# GeographicLib datasets for MAVROS
# ------------------------------------------------------------
# Skipped at build time because raw.githubusercontent.com is unreachable from
# this build host. MAVROS only needs the datasets when doing GPS/geoid fusion
# at runtime — install them inside the running container when you need GPS:
#   wget https://raw.githubusercontent.com/mavlink/mavros/master/mavros/scripts/install_geographiclib_datasets.sh
#   sudo bash install_geographiclib_datasets.sh
# RUN wget https://raw.githubusercontent.com/mavlink/mavros/master/mavros/scripts/install_geographiclib_datasets.sh \
#  && bash install_geographiclib_datasets.sh \
#  && rm install_geographiclib_datasets.sh

# ------------------------------------------------------------
# PX4 SITL — pin to a known-good release tag rather than tracking main.
# Comment out this block on the first build if you want a faster initial
# image; you can clone PX4 inside the container later instead.
# ------------------------------------------------------------
RUN git clone https://github.com/PX4/PX4-Autopilot.git /opt/PX4-Autopilot \
 && cd /opt/PX4-Autopilot \
 && git checkout v1.15.4 \
 && git submodule update --init --recursive \
 && bash Tools/setup/ubuntu.sh --no-nuttx --no-sim-tools \
 || echo "WARNING: PX4 setup had issues — you can rebuild manually later"

# PX4 SITL build skipped at image-build time to keep the image small and
# the build fast. Run it once inside the container when you actually need it:
#   cd /opt/PX4-Autopilot && DONT_RUN=1 make px4_sitl gz_x500
# To re-enable at image-build time, fold this back into the RUN above:
#   && DONT_RUN=1 make px4_sitl gz_x500 \

# ------------------------------------------------------------
# Non-root user matching host UID/GID
# ------------------------------------------------------------
ARG USER_UID=1000
ARG USER_GID=1000
ARG USER_NAME=dev
# Ubuntu 24.04 ships a default `ubuntu` user at UID/GID 1000 that collides
# with our build args. Remove it before creating $USER_NAME. Each cleanup
# step is individually guarded with `|| true` so it tolerates the user/group
# already being absent, but the critical groupadd/useradd/sudoers steps
# below are NOT swallowed — if they fail, the build should fail loudly.
RUN (userdel -r ubuntu 2>/dev/null || true) \
 && (groupdel ubuntu 2>/dev/null || true) \
 && groupadd --gid $USER_GID $USER_NAME \
 && useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash $USER_NAME \
 && echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
 && (chown -R $USER_UID:$USER_GID /opt/PX4-Autopilot 2>/dev/null || true)

USER $USER_NAME
WORKDIR /home/$USER_NAME

# Auto-source Jazzy and pin DDS settings to match container_bridge
RUN echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc \
 && echo "export ROS_DOMAIN_ID=42" >> ~/.bashrc \
 && echo "export RMW_IMPLEMENTATION=rmw_fastrtps_cpp" >> ~/.bashrc

CMD ["/bin/bash"]
