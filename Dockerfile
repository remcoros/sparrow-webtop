# Debian Trixie, Selkies 2.1.0 (debiantrixie-3b96e1dd-ls145).
FROM ghcr.io/linuxserver/baseimage-selkies@sha256:df4a9259e7535526005785202bd08b3b066250a64c65877802b2354fd6a975dd AS buildstage

# Build-time Sparrow release settings
ARG ARCH
ARG SPARROW_VERSION=2.5.6
ARG SPARROW_DEBVERSION=2.5.6-1
ARG SPARROW_PGP_SIG=E94618334C674B40

RUN \
  echo "**** install packages ****" && \
  apt-get update && \
  # remove dunst, we use xfce4-notifyd instead
  DEBIAN_FRONTEND=noninteractive \
  apt-get remove -y dunst && \
  # install required packages
  DEBIAN_FRONTEND=noninteractive \
  apt-get install -y --no-install-recommends \
    exo-utils \
    mousepad \
    xfce4-terminal \
    tumbler \
    thunar \
    # from 'recommended packages', solves a few warnings
    thunar-archive-plugin \
    librsvg2-common \
    python3-xdg \
    # dark theme
    hsetroot \
    gnome-themes-extra \
    compton \
    # desktop notifications
    xfce4-notifyd \
    libnotify-bin \
    xclip \
    # other
    wget \
    socat \
    gnupg && \
  # remove unused packages from base image
  DEBIAN_FRONTEND=noninteractive \
  apt-get remove --purge --autoremove -y \
    cmake \
    containerd.io \
    docker-ce \
    docker-ce-cli \
    docker-buildx-plugin \
    docker-compose-plugin \
    firmware-amd-graphics \
    firmware-linux-nonfree \
    firmware-misc-nonfree \
    fonts-noto-color-emoji \
    fonts-noto-core \
    fonts-noto-cjk \
    g++ \
    gcc \
    locales-all \
    make && \
  # remove left-over locales and generate en_US.UTF-8 via locale-gen
  rm -rf $(ls -d /usr/share/locale/* | grep -vw /usr/share/locale/en | grep -v locale.alias) && \
  echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
  locale-gen && \
  update-locale LANG=en_US.UTF-8 && \
  # upgrade remaining packages
  DEBIAN_FRONTEND=noninteractive \
  apt-get upgrade -y && \
  echo "**** xfce tweaks ****" && \
  rm -f /etc/xdg/autostart/xscreensaver.desktop && \
  # branding
  echo "Starting Sparrow on Webtop..." > /etc/s6-overlay/s6-rc.d/init-adduser/branding && \
  # cleanup
  echo "**** cleanup ****" && \
  apt-get autoclean && \
  rm -rf \
    /config/.cache \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*

# Sparrow
RUN \
  echo "**** install Sparrow ****" && \
  # sparrow requires this directory to exist
  mkdir -p /usr/share/desktop-directories/ && \
  # Download and install Sparrow
  wget --quiet https://github.com/sparrowwallet/sparrow/releases/download/${SPARROW_VERSION}/sparrowwallet_${SPARROW_DEBVERSION}_amd64.deb \
               https://github.com/sparrowwallet/sparrow/releases/download/${SPARROW_VERSION}/sparrow-${SPARROW_VERSION}-manifest.txt \
               https://github.com/sparrowwallet/sparrow/releases/download/${SPARROW_VERSION}/sparrow-${SPARROW_VERSION}-manifest.txt.asc \
               https://keybase.io/craigraw/pgp_keys.asc && \
  # verify pgp and sha signatures
  gpg --import pgp_keys.asc && \
  gpg --status-fd 1 --verify sparrow-${SPARROW_VERSION}-manifest.txt.asc | grep -q "GOODSIG ${SPARROW_PGP_SIG} Craig Raw <craig@sparrowwallet.com>" || exit 1 && \
  sha256sum --check sparrow-${SPARROW_VERSION}-manifest.txt --ignore-missing || exit 1 && \
  DEBIAN_FRONTEND=noninteractive \
  apt-get install -y ./sparrowwallet_${SPARROW_DEBVERSION}_amd64.deb && \
  # cleanup
  rm ./sparrow* ./pgp_keys.asc

# Remove the application catalogue, its installer, and startup provisioning.
COPY strip-proot-apps.sh /tmp/strip-proot-apps.sh
RUN sh /tmp/strip-proot-apps.sh && rm -f /tmp/strip-proot-apps.sh

# start from scratch so we create smaller layers in the resulting image
FROM scratch

COPY --from=buildstage / .

# restore runtime metadata inherited from the Selkies base image
ENV \
  # from https://github.com/linuxserver/docker-baseimage-debian/blob/master/Dockerfile
  LANGUAGE="en_US.UTF-8" \
  LANG="en_US.UTF-8" \
  TERM="xterm" \
  S6_CMD_WAIT_FOR_SERVICES_MAXTIME="0" \
  S6_VERBOSITY=1 \
  S6_STAGE2_HOOK=/docker-mods \
  VIRTUAL_ENV=/lsiopy \
  PATH="/lsiopy/bin:$PATH" \
  # from https://github.com/linuxserver/docker-baseimage-selkies/blob/master/Dockerfile
  DISPLAY=:1 \
  PERL5LIB=/usr/local/bin \
  HOME=/config \
  PULSE_RUNTIME_PATH=/defaults \
  SHELL=/bin/bash \
  __GL_SYNC_TO_VBLANK=0 \
  SELKIES_INTERPOSER=/usr/lib/selkies_input_interposer.so \
  SELKIES_WEBCAM_INTERPOSER=/usr/lib/selkies_v4l2_interposer.so \
  SELKIES_ALLOWED_ORIGINS="*" \
  # nginx authenticates the browser; the internal Selkies server is behind it.
  SELKIES_ENABLE_BASIC_AUTH=false \
  SELKIES_RATE_CONTROL_MODE="crf,cbr" \
  NVIDIA_DRIVER_CAPABILITIES=all \
  DISABLE_ZINK=false \
  DISABLE_DRI3=false \
  # Preserve the previous software-video/JPEG choices under their Selkies 2 names.
  SELKIES_ENCODER="h264enc,jpeg" \
  # custom for our image
  START_DOCKER=false \
  GTK_THEME=Adwaita:dark \
  GTK2_RC_FILES=/usr/share/themes/Adwaita-dark/gtk-2.0/gtkrc \
  # Default to change-based encoding at 30 fps; keep both settings adjustable.
  SELKIES_VIDEO_STREAMING_MODE=false \
  SELKIES_FRAMERATE="30,8-120" \
  # The previous WebSocket runtime always resized to the browser, despite its false setting default.
  SELKIES_ENABLE_RESIZE=true \
  SELKIES_ENABLE_RATE_CONTROL=false \
  SELKIES_VIDEO_BITRATE="1000-100000" \
  SELKIES_USE_BROWSER_CURSORS=false \
  SELKIES_ENABLE_BINARY_CLIPBOARD=false \
  SELKIES_AUDIO_ENABLED="false|locked" \
  SELKIES_MICROPHONE_ENABLED="false|locked" \
  # Request the browser camera only when an application opens its scanner.
  SELKIES_WEBCAM_ON_START=demand \
  SELKIES_UI_SIDEBAR_SHOW_APPS=false \
  SELKIES_UI_SIDEBAR_SHOW_GAMEPADS=false \
  SELKIES_GAMEPAD_ENABLED=false \
  NO_GAMEPAD=true \
  PIXELFLUX_WAYLAND=true \
  NO_FULL=1 \
  AUTO_GPU=true \
  TITLE="Sparrow Wallet"

# add local files
COPY /root /
COPY --chmod=755 ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
COPY --chmod=664 icon.png /usr/share/selkies/www/icon.png

# ports and volumes
EXPOSE 3000
EXPOSE 3001
VOLUME /config

ENTRYPOINT ["/usr/local/bin/docker_entrypoint.sh"]
