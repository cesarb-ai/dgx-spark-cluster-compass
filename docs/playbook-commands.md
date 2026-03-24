# Operational playbook

Commands below are **patterns** distilled from real multi-Spark vLLM bring-up. Replace IPs, interface names, usernames, and model paths with yours. Prefer running cluster scripts from the **head Spark** (not a laptop).

---

## 1. Naming used in examples

| Item | Example |
|------|---------|
| Cluster subnet | `10.0.0.0/24` |
| Head | `10.0.0.1` |
| Worker | `10.0.0.2` |
| Ethernet interface | `enp1s0f0np0` |
| RoCE / IB device | `rocep1s0f0` |

---

## 2. Laptop → Spark (copy scripts or repo)

From your development machine (paths exist **here**):

```bash
scp /path/on/laptop/spark-vllm-docker/examples/smoke-two-spark-ray.sh \
  your-user@HEAD_LAN_IP:~/spark-vllm-docker/examples/
```

Alternatively: `git pull` on the Spark if the repo is already cloned there.

---

## 3. Head — stop cluster, then smoke with materialized model

Inside `spark-vllm-docker` on the **head**:

```bash
cd ~/spark-vllm-docker

./launch-cluster.sh -n 10.0.0.1,10.0.0.2 --eth-if enp1s0f0np0 --ib-if rocep1s0f0 stop

./launch-cluster.sh -n 10.0.0.1,10.0.0.2 \
  --eth-if enp1s0f0np0 --ib-if rocep1s0f0 \
  -e MODEL_ID=/root/.cache/huggingface/materialized/Qwen-Qwen2.5-7B-Instruct \
  --no-ray \
  --launch-script examples/smoke-two-spark-ray.sh
```

Notes:

- `--launch-script` resolution is relative to the repo; avoid duplicated `examples/examples/...` paths if your wrapper script uses `SCRIPT_DIR`.
- `--no-ray` is useful to **isolate** whether a failure is Ray-specific; production recipes often use Ray.

---

## 4. Materialize weights and copy to worker

On head (host paths; container sees them under `/root/.cache/huggingface` when mounted):

- Prefer **`hf download ...`** to a **local dir** (newer `hf` versions behave differently around symlinks), **or**
- A small venv script using `snapshot_download(..., local_dir_use_symlinks=False)` when the CLI is awkward (PEP 668 may block system-wide `pip install --user`).

Then on worker:

```bash
ssh worker "mkdir -p ~/.cache/huggingface/materialized"
```

Sync:

```bash
rsync -av --progress \
  ~/.cache/huggingface/materialized/Qwen-Qwen2.5-7B-Instruct/ \
  your-user@10.0.0.2:~/.cache/huggingface/materialized/Qwen-Qwen2.5-7B-Instruct/
```

Launch with `MODEL_ID=/root/.cache/huggingface/materialized/...` so vLLM inside Docker reads the bind-mounted tree.

---

## 5. Sanity check API

On the node that exposes the service (often head):

```bash
curl -sS http://127.0.0.1:8000/v1/models | head
```

---

## 6. GPU hygiene when “mysterious” VRAM is gone

On **each** node, before a clean run:

```bash
nvidia-smi
# If something is still holding devices:
sudo fuser -v /dev/nvidia*
# Stop stray containers / kill offending PIDs deliberately, then re-check nvidia-smi
```

Goal: **symmetric**, predictable free memory on every GPU participating in TP.

---

## 7. NCCL steering (when hangs look like “FlashAttention forever”)

Set explicitly in the environment used by the container (exact values depend on your fabric):

```bash
export NCCL_IB_HCA=rocep1s0f0
export NCCL_IB_GID_INDEX=3
```

If you change these, change **one variable at a time** and keep notes—GID index is especially site-specific.

---

## 8. vLLM engine selection (image-dependent)

Some images log `VLLM_USE_V1` as unknown; others honor it. Treat engine flags as **version-coupled**: read the image’s startup logs and match the recipe (eugr repo / your fork) to that version.

When V1 features clash with memory profiling or SymmMem warnings, teams often fall back to **stable V0-style** paths **if** their wheel supports it.
