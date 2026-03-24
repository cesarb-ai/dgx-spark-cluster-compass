# Troubleshooting and pitfalls

Use this with [Clustering stack](clustering-stack.md): find the **layer**, then apply the **fix**. Symptoms are often misleading.

---

## Blackwell / GB10 “version tax” (CUDA, PyTorch, containers)

Spark systems built around **Blackwell-class GPUs (e.g. GB10)** often land **ahead** of the “stable” toolchain story you see in older blog posts or long-unchanged playbook snippets. In practice you may need **newer CUDA** (for example **CUDA 13.1+** on some images) and **newer PyTorch** builds (**2.9 nightlies** or whatever your **current** NVIDIA Spark software bundle ships with)—not the conservative pins you would use on an Ampere-era workstation.

**Why this matters:** copying year-old “known good” versions from generic ML tutorials is a fast path to **mysterious build failures**, **driver/library skew**, or runtime errors that look like application bugs but are really **ABI mismatch**.

**What to do**

- Treat **NVIDIA’s current Spark / DGX Spark release notes and container tags** as the source of truth for your SKU—not this markdown file.
- Align **host driver**, **container base**, **PyTorch**, and **vLLM wheel** from **one** coherent stack (eugr `spark-vllm-docker`, NVIDIA NGC, or NVIDIA playbook images).
- When something fails after an OS upgrade, ask first: **did the version tax move under me?**

Exact version triples change quarterly; the **pattern** is stable: Blackwell-era hardware pays a **version tax** until your whole stack agrees on one generation.

---

## “It works on one Spark but not two”

**Likely layers:** L1 (IP), L2 (SSH), L5 (NCCL / RoCE steering), L7 (weights not on both nodes).

**Quick checks**

- `ping` both ways on the **cluster** subnet.
- `ssh` head → worker without password prompts.
- Same **materialized** model path on both nodes **inside** the mount.
- NCCL env explicitly pointing at the correct **HCA** and **GID index** if autodetection stalls.

---

## Hang at “FlashAttention” or long silence during init

**FlashAttention is the victim, not the suspect.** The log line is memorable, so everyone blames it—but in multi-node setups the stall is **very often** distributed init, **NCCL**, or a bad RoCE/GID choice while the attention kernel is just the next milestone in the log.

**What to do**

- Confirm GPUs are clean (`nvidia-smi`, `fuser` on `/dev/nvidia*`).
- Turn on **NCCL debug** temporarily (verbose logs) in a controlled repro, not in production.
- Consider `--enforce-eager` or recipe-level toggles **only** after you have a clean NCCL path (otherwise you mask the real issue).

---

## `Cannot find any model weights` with a Hub snapshot path

**Layer:** L3 + L7 (mount + file layout).

**Common cause:** Hugging Face cache with **symlinks** into `blobs/`; some loaders do not follow the layout you think they follow.

**Fix pattern**

1. **Materialize** to a directory with real weight files.
2. **rsync** to peers.
3. Point `MODEL_ID` at the **container** path under `/root/.cache/huggingface/...`.

---

## vLLM V1 memory reservation failures (e.g. “~99 GiB” targets)

**Layer:** L6.

**Interpretation**

- One GPU may not actually have the free memory the planner expects (zombie job, forgotten container, different reservation).
- Asymmetric nodes break **tensor-parallel** assumptions quickly.

**What to do**

- Establish **zero usage** on all GPUs before testing.
- Compare **both** nodes’ `nvidia-smi` side by side.
- Align engine (V0 vs. V1) with what your **image** supports; do not assume an env var works if the binary logs “unknown.”

---

## SymmMem warnings (`Device capability … not supported`)

**Layer:** L6 (engine / feature matrix).

Treat as a signal that the **fast path** you are on may not match your GPU + wheel combo. Fall back per your recipe (image version, `VLLM_USE_V1` if honored, or pinned vLLM).

---

## `shm_broadcast` / shared memory broadcast timeouts

**Layer:** L6 (runtime sync / graphs / compile phases) after weights load.

**What to do**

- Collect **both** nodes’ logs (`docker logs` on head and worker) with matching timestamps.
- Consider eager execution or recipe flags **as experiments**, not as the first knob.

---

## Operational mistakes that burn hours

| Mistake | Reality |
|--------|---------|
| Running `launch-cluster.sh` on the laptop | The laptop does not have Spark NIC names or GPUs; run on the **head** (or equivalent). |
| `scp` with Spark-only paths on the laptop side | Source paths must exist on the machine where `scp` runs. |
| `chmod` / `cd` to Spark paths while on the laptop | Those paths live on the **Spark**. |
| `ls /root/.cache/...` on worker **host** as normal user | Permission denied; use `~/.cache/...` on the host or inspect inside the container. |
| Shell globs like `*.safetensors` over `ssh` + `docker exec` | Globs may expand **locally** or fail oddly; prefer explicit paths or `find` inside the container. |

---

## `Command 'jupyter' not found` or `No module named jupyter`

**Layer:** Tooling / environment (pre-flight).

**Why it happens:** You are on the right Spark host, but not in the same Python environment where Jupyter was installed (or it was never installed in that venv).

**Fix pattern**

1. Activate the intended venv first (example):
   - `source ~/ai_env/bin/activate`
2. Verify interpreter and module:
   - `which python`
   - `python -m jupyter --version`
3. If missing, install in that active venv:
   - `pip install jupyterlab`
4. Start explicitly from that interpreter:
   - `python -m jupyter lab --no-browser --ip=127.0.0.1 --port=8888`
5. From laptop, tunnel in a separate terminal:
   - `ssh -N -L 8888:127.0.0.1:8888 <user>@<spark-lan-ip>`

**Interpretation tip:** SSH success does not imply Jupyter success.  
`channel ... connect failed: Connection refused` means the remote target port is closed (Jupyter not running on that port yet).

---

## Ollama vs. Ray + vLLM

If you tried Ollama first: many “just cluster it” expectations map poorly to **tensor-parallel single-model** serving across two discrete machines. The stack in this compass (Docker + NCCL-aware vLLM + per-node weights) is a different shape of problem than a single-binary local server.

---

## Security note (orthogonal but important)

Exposing SSH or APIs directly to the internet is risky. Patterns like Tailscale, WireGuard, or a small bastion on your LAN are **out of scope** for “make NCCL happy,” but they matter for how you reach the cluster safely from outside your home lab.
