# halogen — Qwen3.8-Flash-Next on Strix Halo, on demand

Podman quadlet + systemd socket activation for [halogen-flash-server](https://github.com/peonist-ai/halogen-flash-server)
(Qwen3.8-Flash-Next, gfx1151). The model is **not** running until something connects to
`127.0.0.1:8731`; it loads in ~10–40 s (prompt cache persisted on disk), and shuts down after
30 min without connections, freeing ~85 GB.

| file | what |
|---|---|
| `halogen-flash.container` | quadlet: container on `:8732`, pinned weights, KV pool, persistent prompt cache, `StopWhenUnneeded` |
| `halogen-flash-proxy.socket` | systemd holds `:8731` |
| `halogen-flash-proxy.service` | `systemd-socket-proxyd --exit-idle-time=30min` → `:8732`; starts the container, and its exit stops it |

Requires: Fedora/Podman with quadlet, ROCm-capable kernel (`/dev/kfd`, `/dev/dri`), 128 GB
unified memory, the checkpoint under `~/halogen-flash-models/` (`qwen38-flash-next-w4b.hgn` +
`tokenizer/`; `HALOGEN_DOWNLOAD=peonist-ai/halogen-qwen3.8-flash-next` in the container
fetches it on first start — see the upstream README).

Install (also done by `../install.sh`):

```sh
mkdir -p ~/.config/containers/systemd ~/.config/systemd/user ~/halogen-flash-models ~/halogen-flash-cache
ln -sfn "$PWD/halogen-flash.container" ~/.config/containers/systemd/
ln -sfn "$PWD/halogen-flash-proxy.socket" "$PWD/halogen-flash-proxy.service" ~/.config/systemd/user/
loginctl enable-linger "$USER"           # survive logout
systemctl --user daemon-reload
systemctl --user enable --now halogen-flash-proxy.socket
curl -s localhost:8731/health | head -c 200     # first call starts the model
```

Useful:

```sh
systemctl --user status halogen-flash            # loaded?
systemctl --user stop halogen-flash-proxy        # unload now
journalctl --user -u halogen-flash -f            # engine log (serve_api: ... t/s)
```

Tuning notes (measured on this box, Sept 2026): weights pinned 65.6 GiB in 1.4 s; 37–45 t/s
decode, 700–1,200 t/s prefill with 99 % prompt-cache hits; `HALOGEN_MAX_TOK=32768` is the fastest
prefill chunk at 262K ctx; `HALOGEN_KV_POOL_POSITIONS` 262144 → 393216 if you run two long
sessions at once (costs a few seconds of memory compaction at start); `HALOGEN_MAX_TOKENS_DEFAULT`
16384 is the recommended agentic budget. Clients: OpenAI-compatible `/v1` with native tools and
streaming — see [mul-cps/academicai-opencode](https://github.com/mul-cps/academicai-opencode)
for the OpenCode hybrid profile that pairs it with API models.
