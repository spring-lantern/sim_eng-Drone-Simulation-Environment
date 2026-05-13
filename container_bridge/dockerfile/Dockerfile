# ============================================================
# container_bridge
# Base: osrf/ros:jazzy-desktop-full (Ubuntu 24.04 + ROS 2 Jazzy)
#       Uses the pre-compiled bridge package from TommyChang's builder.
#       container_bridge — Jazzy + Noetic-libs + ros1_bridge
# Role: forward ROS 1 ↔ ROS 2 messages via ros1_bridge.
#       Also acts as the ROS 2 entry point for container_sim (Jazzy)
#       via direct DDS over --network=host.
# ============================================================
FROM osrf/ros:jazzy-desktop-full

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

# ------------------------------------------------------------
# Add the ros-for-jammy/noble PPA which provides Noetic runtime
# libraries built for Ubuntu 24.04. This is the same trick the
# builder image uses to make Noetic and Jazzy coexist on Noble.
# ------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    curl gnupg \
 && add-apt-repository -y ppa:ros-for-jammy/noble \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    ros-noetic-roscpp \
    ros-noetic-rospy \
    ros-noetic-std-msgs \
    ros-noetic-sensor-msgs \
    ros-noetic-geometry-msgs \
    ros-noetic-nav-msgs \
    ros-noetic-tf2-msgs \
    ros-noetic-rosbag \
    python3-pip \
    nano vim sudo iputils-ping net-tools \
 && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# COPY the pre-compiled bridge package into the image
# ------------------------------------------------------------
COPY bridge_pkg/ros-jazzy-ros1-bridge /opt/ros-jazzy-ros1-bridge

# ------------------------------------------------------------
# Non-root user matching host UID/GID
# ------------------------------------------------------------
ARG USER_UID=1000
ARG USER_GID=1000
ARG USER_NAME=dev
# Ubuntu 24.04 ships a default `ubuntu` user at UID/GID 1000 that collides
# with our build args. Remove it before creating $USER_NAME.
RUN (userdel -r ubuntu 2>/dev/null || true) \
 && (groupdel ubuntu 2>/dev/null || true) \
 && groupadd --gid $USER_GID $USER_NAME \
 && useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash $USER_NAME \
 && echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER $USER_NAME
WORKDIR /home/$USER_NAME

# Source Jazzy + bridge in every shell
RUN echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc \
 && echo "source /opt/ros-jazzy-ros1-bridge/install/local_setup.bash" >> ~/.bashrc \
 && echo "export ROS_DOMAIN_ID=42" >> ~/.bashrc \
 && echo "export RMW_IMPLEMENTATION=rmw_fastrtps_cpp" >> ~/.bashrc \
 && echo "export ROS_MASTER_URI=http://localhost:11311" >> ~/.bashrc

CMD ["/bin/bash"]