ARG UBUNTU_VERSION=22.10 //Default value provided

FROM ubuntu:${UBUNTU_VERSION}

RUN apt-get update && apt-get install -y build-essential curl cmake git reprepro rclone

RUN mkdir -p /root/.config/rclone/

WORKDIR /agent2

ENTRYPOINT ["/agent2/entrypoint.sh"]
