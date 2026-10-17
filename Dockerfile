FROM ubuntu:22.04

ARG NODE_MAJOR=22
ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:99 \
    CI=true

RUN apt-get update -qq \
 && apt-get install -y -qq --no-install-recommends \
      ca-certificates curl git jq lz4 xz-utils unzip file procps sudo gnupg \
      software-properties-common build-essential python3 \
      xvfb x11-utils xdotool ffmpeg \
      libgl1-mesa-dri libglx-mesa0 libegl1 libgles2 mesa-utils \
 && add-apt-repository -y ppa:deadsnakes/ppa \
 && apt-get update -qq \
 && apt-get install -y -qq --no-install-recommends libpython3.8-dev watchman \
 && curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
 && apt-get install -y -qq nodejs \
 && corepack enable \
 && rm -rf /var/lib/apt/lists/*

# The Vega installer refuses to run as root.
RUN useradd -m -s /bin/bash dev \
 && echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev \
 && chmod 440 /etc/sudoers.d/dev

USER dev
WORKDIR /home/dev

# The installer reads its prompts from stdin, so it must run from a file, not a pipe.
RUN curl -fsSL https://sdk-installer.vega.labcollab.net/get_vvm.sh -o /tmp/get_vvm.sh \
 && (yes "" | bash /tmp/get_vvm.sh) \
 && rm /tmp/get_vvm.sh \
 && bash -lc 'source ~/vega/env && vega --version'

COPY --chown=dev:dev bin/ /home/dev/bin/
ENV PATH=/home/dev/bin:$PATH

ENTRYPOINT ["/home/dev/bin/entrypoint"]
CMD ["bash"]
