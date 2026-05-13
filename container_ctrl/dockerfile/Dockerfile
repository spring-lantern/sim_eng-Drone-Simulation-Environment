# ============================================================
# container_ctrl
# Base: Ubuntu 20.04 + ROS 1 Noetic (desktop-full)
# Role: perception, path planning, control logic (PX4Ctrl + MAVROS)
# ============================================================
FROM osrf/ros:noetic-desktop-full

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

# ------------------------------------------------------------
# Core dev tools and ROS 1 packages commonly used for drone control
# ------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-noetic-mavros \
    ros-noetic-mavros-extras \
    ros-noetic-mavros-msgs \
    ros-noetic-tf2-tools \
    ros-noetic-rqt \
    ros-noetic-rqt-common-plugins \
    ros-noetic-rviz \
    python3-catkin-tools \
    python3-rosdep \
    python3-rosinstall \
    python3-rosinstall-generator \
    python3-wstool \
    python3-pip \
    build-essential \
    git wget curl nano vim sudo \
    iputils-ping net-tools \
 && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# GeographicLib datasets required by MAVROS for GPS/IMU fusion
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
# Non-root user matching host UID/GID, to avoid permission grief
# on mounted volumes
# ------------------------------------------------------------
ARG USER_UID=1000
ARG USER_GID=1000
ARG USER_NAME=sl
RUN groupadd --gid $USER_GID $USER_NAME \
 && useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash $USER_NAME \
 && echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER $USER_NAME
WORKDIR /home/$USER_NAME

# Auto-source ROS Noetic + custom prompt with red [container_ctrl] tag
# and bold-yellow username.
RUN echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc \
 && echo "export ROS_MASTER_URI=http://localhost:11311" >> ~/.bashrc \
 && echo "export ROS_HOSTNAME=localhost" >> ~/.bashrc \
 && echo "export PS1='\[\033[1;41;97m\] container_ctrl \[\033[0m\] \[\033[1;33m\]\u\[\033[0m\]@\h:\w\\\$ '" >> ~/.bashrc

CMD ["/bin/bash"]
