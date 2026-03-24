# Spark Compass — interactive wizards

This folder is the **hands-on** half of the repo: numbered Jupyter notebooks match **real milestones** (unbox → router → SSH both units → QSFP “fast lane” → cluster IPs → playbooks + eugr → NCCL → vLLM). The prose lives in [`docs/`](../docs/)—especially [`docs/clustering-stack.md`](../docs/clustering-stack.md)—and should be read alongside these notebooks.

## Install (on a Spark, when you reach the step that needs Python checks)

```bash
cd /path/to/dgx-spark-cluster-compass/wizard
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements-wizard.txt
jupyter lab
```

Early notebooks (01–02) are mostly **checklists**; you can complete them from any machine with a browser and SSH. Later notebooks expect to run on the **head** Spark (same place you run `launch-cluster.sh`).

---

## Notebooks (read in order)

| # | File | Milestone you are proving |
|---|------|---------------------------|
| 01 | [`01_first_spark_power_lan_ssh.ipynb`](01_first_spark_power_lan_ssh.ipynb) | First unit: power, **Cat6 to router**, discover IP, **SSH** works. |
| 02 | [`02_second_spark_lan_ssh.ipynb`](02_second_spark_lan_ssh.ipynb) | Second unit: same LAN story; you can SSH to **both** management addresses. |
| 03 | [`03_qsfp_interconnect_link_and_mtu.ipynb`](03_qsfp_interconnect_link_and_mtu.ipynb) | **QSFP / “$200 cable”** milestone: link **UP**, right port, **MTU**, `ibdev2netdev` sanity (L1/L2 data plane). |
| 04 | [`04_l3_cluster_subnet_ping_and_routes.ipynb`](04_l3_cluster_subnet_ping_and_routes.ipynb) | **10.0.0.x** (or your choice): static/cluster IPs, **bidirectional ping**, routes match what scripts will use. |
| 05 | [`05_playbook_eugr_control_plane_orchestration.ipynb`](05_playbook_eugr_control_plane_orchestration.ipynb) | Why **NVIDIA playbook + eugr** beat ad-hoc `docker compose`; passwordless SSH on **cluster** IPs, image sync, Ray / `--no-ray` mental model. |
| 06 | [`06_nccl_roce_gpu_collectives.ipynb`](06_nccl_roce_gpu_collectives.ipynb) | **NCCL / RoCE**: GID index hints, `NCCL_DEBUG=INFO`, “FlashAttention is the victim, not the suspect.” |
| 07 | [`07_vllm_tensor_parallel_launch_and_health.ipynb`](07_vllm_tensor_parallel_launch_and_health.ipynb) | **eugr** `launch-cluster.sh`, materialized weights reminder, optional **health** / `/v1/models` smoke. |
| 08 | [`08_full_stack_console.ipynb`](08_full_stack_console.ipynb) | **All gates in one notebook** (single-file “admin console”; same as the original monolithic wizard). |

**Legacy name:** [`setup_guide.ipynb`](setup_guide.ipynb) only **redirects** to this README (bookmarks from older links).

---

## Planes vs. “green” signals (how logs map to reality)

Clustering is several **planes** that logs **interleave**—easy to blame the wrong one.

| Plane | What it is | You are “green” when… |
|-------|----------------|------------------------|
| **L1–L2** — Physical + link | QSFP/DAC/AOC seated, NIC driver, link state, MTU | `ip link` / `ibdev2netdev` show the **cluster** port **UP**; errors are not “silent down.” |
| **L3** — IP & routing | Addresses on the ConnectX-facing network (e.g. `10.0.0.0/24`) | `ping` **both ways**; `ip route` and script `--nodes` / `-n` agree. |
| **L4** — Control & orchestration | SSH, copying images, Ray head/worker or torch rendezvous | Ray dashboard / logs look sane, or you deliberately use `--no-ray` with matching env. |
| **L4+** — GPU collectives (**NCCL**) | Process group across GPUs; traffic prefers **RoCE** | `NCCL_DEBUG=INFO` shows expected **interface / HCA / GID**; init does not hang forever. |
| **App** — vLLM | Tensor parallel = **one** logical model over **all** GPUs | API listens; tokens stream; weights visible **inside** the container mount. |

**Docker** does not replace any of the above: it packages **userspace** (vLLM, libraries) and still sits on top of **drivers, NICs, L3, NCCL, and correct orchestration**.

**Speed sanity:** Retail QSFP gear is usually marketed in **Gb/s** (gigabits per second), not **GB/s**. A “200G” link is **200 gigabit-class**, not 200 gigabytes per second.

---

## Documentation cross-links

| Topic | Doc |
|-------|-----|
| Deeper layer diagrams | [`docs/clustering-stack.md`](../docs/clustering-stack.md) |
| Copy-paste commands | [`docs/playbook-commands.md`](../docs/playbook-commands.md) |
| Pitfalls (symlinks, laptop vs Spark, Blackwell version tax) | [`docs/troubleshooting-and-pitfalls.md`](../docs/troubleshooting-and-pitfalls.md) |
| Upstream playbooks | [`docs/references.md`](../docs/references.md) |
