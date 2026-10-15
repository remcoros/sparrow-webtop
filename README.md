# Sparrow Webtop

Sparrow Webtop runs [Sparrow Wallet](https://sparrowwallet.com/) in a
[Selkies 2 powered](https://github.com/linuxserver/docker-baseimage-selkies/) Linux desktop that is accessible from a web browser.

Images are published for AMD64 and ARM64.

## Docker

Persist `/config`, allocate at least 1 GB of shared memory, and set a strong
password:

```shell
docker run -d \
  --name sparrow-webtop \
  -e CUSTOM_USER=webtop \
  -e PASSWORD=change-this-password \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Etc/UTC \
  -p 3000:3000 \
  -p 3001:3001 \
  -v /opt/sparrow-webtop-data:/config \
  --shm-size=1gb \
  --restart unless-stopped \
  ghcr.io/remcoros/sparrow-webtop:latest
```

Open `https://localhost:3001` or `http://localhost:3000`.

The included [`docker-compose.yml`](docker-compose.yml) provides the same
baseline configuration.

## GPU Acceleration

For Intel or AMD GPUs, pass the host DRI devices:

```shell
--device /dev/dri:/dev/dri
```

The Selkies base image automatically uses a single available render node for
hardware video encoding. GPU rendering is enabled unless `DISABLE_DRI3=true`
and `DISABLE_ZINK=true` are set.

For NVIDIA GPUs, install the NVIDIA Container Toolkit and add:

```shell
--runtime nvidia --gpus all
```

For the complete X11 software-rendering path, set:

```shell
-e PIXELFLUX_WAYLAND=false \
-e AUTO_GPU=false \
-e 'SELKIES_USE_CPU=true|locked' \
-e DISABLE_DRI3=true \
-e DISABLE_ZINK=true \
-e LIBGL_ALWAYS_SOFTWARE=true
```

`LIBGL_ALWAYS_SOFTWARE=true` also disables the cosmetic X11 compositor. Turbo
mode is disabled by default through `SELKIES_VIDEO_STREAMING_MODE=false`, and
`SELKIES_FRAMERATE="30,8-120"` sets the initial frame rate to 30 fps while
retaining the 8–120 fps adjustment range. Both settings remain configurable in
the Selkies sidebar.

## Browser camera and media

The browser camera is forwarded to Sparrow on demand when its QR scanner opens.
Use a browser that supports camera access through a trusted HTTPS origin, or
localhost, and allow the camera permission when prompted. A remote HTTP URL and
Tor Browser cannot provide webcam access. The desktop can still be viewed and
controlled without a camera.

Desktop audio output and microphone forwarding are disabled and locked in the
server settings. Webcam forwarding is independent of these settings.

## Desktop applications

The bundled proot application gallery, its installer and its external catalogue
fetch are removed. The existing terminal, file manager, editor and sudo support
remain available. The desktop follows the browser size by default
(`SELKIES_ENABLE_RESIZE=true`). Streaming defaults to 30 fps with Turbo off.
Scaling and wallet close behavior retain their previous settings.

## StartOS

The StartOS package is maintained separately in
[sparrow-webtop-startos](https://github.com/remcoros/sparrow-webtop-startos).

# License

[GPL](LICENSE)
