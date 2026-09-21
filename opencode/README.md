# opencode server — always on, reachable over the tailnet

`opencode-web.service` (user unit, `WantedBy=default.target`; with `loginctl enable-linger` it
starts at boot, before login) runs `opencode web` on `127.0.0.1:3003`: the headless HTTP/OpenAPI
server plus the browser UI. Credentials live in `~/.config/opencode/server.env` (mode 600):

```
OPENCODE_SERVER_USERNAME=you
OPENCODE_SERVER_PASSWORD=long-random-string
```

Install:

```sh
ln -sfn "$PWD/opencode-web.service" ~/.config/systemd/user/opencode-web.service
systemctl --user daemon-reload && systemctl --user enable --now opencode-web.service
loginctl enable-linger "$USER"
```

Remote access, TLS by Tailscale, server stays on loopback (one-time `sudo tailscale set --operator=$USER`):

```sh
tailscale serve --bg --https=8443 http://127.0.0.1:3003      # persisted by tailscaled, survives reboots
```

- Browser: `https://<host>.<tailnet>.ts.net:8443` (basic auth prompt)
- Remote TUI: `OPENCODE_SERVER_PASSWORD=… opencode attach https://<host>.<tailnet>.ts.net:8443 --dir ~/git/project`
- API: `https://<host>…:8443/doc` (OpenAPI)
