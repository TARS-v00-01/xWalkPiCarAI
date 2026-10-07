<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [6. xWalk tool](../../../../index.md) / SearXNG Deployment

**6. xWalk tool &middot; Module 15**

<!-- xwalk-page-header:end -->

# SearXNG Deployment

The SearXNG deployment provides an optional, loopback-only SearXNG metasearch container for Jarvis web search on
the target. Jarvis continues to answer from local Ollama when SearXNG is absent or web search is disabled.

## 1. Overview

The compose mapping exposes only `127.0.0.1:8080`. JSON is the only enabled result format, the limiter, image
proxy, and public-instance mode are off, safe search is moderate (`1`), and unnecessary plugins are disabled;
only the tracker URL remover remains active. Expect additional memory, storage, and outbound network use from
the container and selected search engines.

## 2. Source location

`xWalk-rpi5-tool/shell-agent/deploy-tool/searxng` -
source directory

## 3. Directory layout

```text
xWalk-rpi5-tool/shell-agent/deploy-tool/searxng/
    compose.yaml     Podman compose service bound to 127.0.0.1:8080 with a cache volume
    settings.yml     SearXNG settings: JSON format only, limiter and public instance disabled
```

The matching user unit is
`systemd/xwalk-searxng.service`.

## 4. Public interface

```bash
systemctl --user daemon-reload
systemctl --user enable --now xwalk-searxng
systemctl --user status xwalk-searxng --no-pager
journalctl --user -u xwalk-searxng --no-pager
curl 'http://127.0.0.1:8080/search?q=xwalk&format=json'
systemctl --user stop xwalk-searxng
```

The unit is a oneshot service that runs `podman compose up -d` and `podman compose down` against the installed
compose file, with a 180-second start and 30-second stop timeout.

## 5. Configuration

Before starting:

1. copy `compose.yaml` and `settings.yml` to `$HOME/.local/share/xwalk/searxng`;
2. copy the systemd unit to `$HOME/.config/systemd/user`; and
3. create a mode-600 `$HOME/.config/xwalk/searxng.env` containing a reviewed image tag in `SEARXNG_VERSION`
   and a randomly generated private `SEARXNG_SECRET`.

Compose refuses to start when either variable is missing. Set `voice_active_car_gpt_web_search_enabled = false`
in the runtime configuration to remove the runtime dependency entirely.

## 6. Dependencies

- Podman with compose support and user-level systemd.
- The `docker.io/searxng/searxng` image at a reviewed tag.

## 7. Safety and constraints

- Installing Podman or pulling a SearXNG image requires explicit network and, when packages are missing,
  administrator approval. No image is downloaded by the repository during builds or host tests.
- The service never embeds credentials and does not select an uncontrolled public instance.
- Never commit the environment file or its secret.

## 8. Related notes

- [Deployment Tool](../Deployment%20Tool.md)

---

[Previous page](../Deployment%20Tool.md) · [Chapter index](../../../../index.md) · [Next page](../ARM64_CROSS_BUILD.md)
