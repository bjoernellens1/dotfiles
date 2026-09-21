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
decode, 700–1,200 t/s prefill with 99 % prompt-cache hits; `HALOGEN_MAX_TOK=16384` (32768 is marginally faster prefill but costs
2 GB more scratch that the page cache needs more); `HALOGEN_HOST_RESERVE_GIB=32` (default 20)
keeps room for the 47.7 GiB n-gram table, which is read through the page cache — with the
default the table thrashed the NVMe at 6–8 GB/s and decode fell to 6–12 t/s; keep `HALOGEN_KV_POOL_POSITIONS` at 262144 on a 128 GB box that also
runs a desktop — 393216 left 3.6 GiB of host memory and the engine froze 60–120 s every few
minutes in kernel memory compaction (see "Host tuning" below); `HALOGEN_MAX_TOKENS_DEFAULT`
16384 is the recommended agentic budget. Clients: OpenAI-compatible `/v1` with native tools and
streaming — see [mul-cps/academicai-opencode](https://github.com/mul-cps/academicai-opencode)
for the OpenCode hybrid profile that pairs it with API models.

## Host tuning (avoids the compaction freezes)

Symptom: `journalctl --user -u halogen-flash` shows `the engine has not answered PING for 45s:
the kernel is compacting host memory`, GPU utilisation drops to 0 for 1–2 min while OpenCode is
busy. Cause: the engine pins ~68 GiB with 2 MiB pages and streams the 51B n-gram table through the
page cache; with little free memory every allocation waits for direct compaction. Fix (root):

```sh
# THP: never block a page fault on direct compaction; kcompactd does it in the background
echo 'w /sys/kernel/mm/transparent_hugepage/defrag - - - - defer' | sudo tee /etc/tmpfiles.d/thp-defrag.conf
echo defer | sudo tee /sys/kernel/mm/transparent_hugepage/defrag
# keep ~2 GiB free so contiguous blocks exist; compact proactively
printf 'vm.min_free_kbytes = 2097152
vm.compaction_proactiveness = 40
vm.swappiness = 1
' | sudo tee /etc/sysctl.d/90-halogen.conf
sudo sysctl --system >/dev/null
```

and don't run other multi-GB tenants (VMs) alongside the model: `virsh shutdown win11`.

## Builds tried (2026-09-21)

- **native `qwen38-flash-next-w4b.hgn` + quality overlay — keep.** 68 GB file-mapped weights, 47.7 GiB table paged.
- bartowski `IQ4_XS` GGUF — **rejected**: same 47.7 GiB table, trunk repacked into 68.3 GiB *anonymous* RAM
  (worse for the page cache than file-mapped weights), halogen warned the budget exceeded free host memory,
  KV-pool reservation stalled >60 s; upstream measures GGUF trunks at −22 % agent-turn decode, no sidecar.
- unsloth `UD-IQ4_XS` / `UD-Q4_K_XL` — not tried: 72–80 GiB resident (8-bit dense layers), −22…−28 % decode.
- vLLM — not viable: FP8 173 GB minimum + 51 GB table in host RAM; gfx1151 unsupported.
