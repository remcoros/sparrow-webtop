# Sparrow Webtop container

This image provides a full featured web native Linux desktop experience for [Sparrow wallet](https://sparrowwallet.com/).

Users can access their Sparrow wallet through a web browser, with a responsive and user-friendly interface.

# How to use

Make sure to mount '/config' to a local directory on the host machine for persistent storage (/opt/sparrow-webtop-data in below example).

    IMPORTANT: Make sure to set a good password!

Example docker command:

```shell
docker run -d \
    --name sparrow-webtop \
    # CHANGE THIS USERNAME/PASSWORD!!
    -e CUSTOM_USER=webtop \
    -e PASSWORD=password \
    -p 3000:3000 \
    -p 3001:3001 \
    -e PUID=1000 \
    -e PGID=1000 \
    -v /opt/sparrow-webtop-data:/config \
    --shm-size="1gb" \
    --restart unless-stopped \
    ghcr.io/remcoros/sparrow-webtop \
```
# Start9 / StartOS

A version for [StartOS](https://startos.com/) can be found here: [sparrow-webtop-startos](https://github.com/remcoros/sparrow-webtop-startos)

# License

[GPL](LICENSE)
