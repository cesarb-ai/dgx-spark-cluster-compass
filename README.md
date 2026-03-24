# DGX Spark cluster compass

> **Disclaimer:** This repository is **not** affiliated with NVIDIA. It is community documentation from someone who burned a multi-day weekend (and several weeknights) proving that two Sparks plus a 200G cable are **not** plug-and-play—and mapping where the stack actually breaks. NVIDIA’s playbooks and containers remain the source of truth; this repo is a **compass** so you spend less time lost between layers.

**Why this exists:** I bought a second DGX Spark, connected the cluster cable, assumed the software path would be obvious, and instead walked every layer from L3 to NCCL to vLLM until it finally held. If this saves you even one Saturday of dead ends, it did its job.

If it helped you, **consider starring the repo** so the next person finds it faster.

A **human-readable map** for people who are new to clustering two (or more) **NVIDIA DGX Spark** units. Connecting Sparks with a high-speed link is **not** plug-and-play: you must succeed at several independent layers before tensor-parallel inference “feels like one brain.”

## Quickstart (5 minutes)

If you only want the fastest path to "is my cluster healthy?":

1. Open [`wizard/README.md`](wizard/README.md).
2. On the head Spark, install notebook deps:
   ```bash
   pip install -r wizard/requirements-wizard.txt
   ```
3. Run notebooks in order: `01` -> `07` (or run [`08_full_stack_console.ipynb`](wizard/08_full_stack_console.ipynb) for one consolidated gate check).
4. If anything fails, jump to [**Troubleshooting and pitfalls**](docs/troubleshooting-and-pitfalls.md) and map the symptom to the layer.

Recommended first read for mental model: [**Clustering stack (layers and handshakes)**](docs/clustering-stack.md).

## Fast track — interactive wizards

**Milestone notebooks (recommended order):** see **[`wizard/README.md`](wizard/README.md)** for the full table. Short version:

| Step | Notebook |
|------|----------|
| 01 | First Spark: power, Cat6 to router, SSH |
| 02 | Second Spark on LAN, SSH to both |
| 03 | QSFP / 200G-class link up, MTU, `ibdev2netdev` |
| 04 | Cluster L3 (`10.0.0.x`), ping, routes |
| 05 | NVIDIA playbook + eugr (why not ad-hoc Compose) |
| 06 | NCCL / RoCE / GID |
| 07 | vLLM + `launch-cluster.sh` + health |
| 08 | **All gates in one file** — [`08_full_stack_console.ipynb`](wizard/08_full_stack_console.ipynb) |

The old name [`setup_guide.ipynb`](wizard/setup_guide.ipynb) only **redirects** to the list above.

Install Jupyter deps on the **head Spark**: [`wizard/requirements-wizard.txt`](wizard/requirements-wizard.txt).

## At a glance (stack)

```mermaid
flowchart LR
  subgraph physical [Physical]
    L[200G link up]
  end
  subgraph net [Network]
    IP[10.0.0.x /24]
  end
  subgraph soft [Software]
    S[SSH + Docker]
    R[Ray / executor]
    N[NCCL / RoCE]
    V[vLLM TP]
  end
  L --> IP --> S --> R --> N --> V
```

## Who this is for

- You bought multiple Sparks and expected the interconnect to “just work.”
- You are comfortable on the command line but have not clustered GPUs before.
- You want to **know where failures actually live** (network vs. SSH vs. Ray vs. NCCL vs. vLLM vs. weights on disk).

## How to use this repo

0. **Optional but recommended:** open [`wizard/README.md`](wizard/README.md) and run notebooks **`01`–`07`** on the head (or **`08`** for one combined console).
1. Read [**Clustering stack (layers and handshakes)**](docs/clustering-stack.md) once. It explains what must succeed, in order, and includes diagrams.
2. Keep [**Operational playbook**](docs/playbook-commands.md) handy when you launch or recover from a bad state.
3. When something breaks, start with [**Troubleshooting and pitfalls**](docs/troubleshooting-and-pitfalls.md) and map the symptom back to a layer.
4. Use [**References**](docs/references.md) for authoritative upstream docs (NVIDIA playbook, community Docker/Ray/vLLM stack).

## Mental model in one sentence

**Clustering** here means: physical link → correct IPs → SSH and orchestration (often Ray) → **NCCL** over RDMA/Ethernet for GPU collectives → **vLLM** with **tensor parallelism (TP)** split across nodes → a single API that uses **all** GPUs as one logical model—**if** every layer above agrees on addresses, ports, devices, and file paths.

### Physical prerequisites (before any script matters)

- **Interconnect:** Cluster cable seated; link **up** at the speed you expect (e.g. 200G-class fabric—not “I have a cable” but “the NICs agree the link is healthy”).
- **Cluster subnet:** Dedicated L3 for Spark-to-Spark traffic (example pattern: **`10.0.0.0/24`**, head `10.0.0.1`, worker `10.0.0.2`) with **bidirectional** `ping`.
- **Symmetric GPUs:** Before multi-node TP, both nodes should show **clean, comparable free VRAM** (`nvidia-smi`). Asymmetric “mystery” usage on one node will break planners and collectives long before “the model” is wrong.

## “One brain” vs. “two models”

These sound similar but impose different constraints:

- **One logical model across both Sparks (TP = 2)**  
  One vLLM (or equivalent) **server**; the model is **sharded** across two GPUs. You usually need a **full copy of the weights on each node** (or shared storage), and NCCL must be healthy. This is what most “connect the cable for more VRAM” guides are aiming at.

- **Two different models at the same time**  
  Two **separate** serving processes (different ports or orchestrators), each owning its GPUs. Cluster networking still matters if processes coordinate, but you are not doing one tensor-parallel group across both GPUs unless you explicitly configure that.

This compass focuses on **making the stack legible** so you can get the first case reliable; the second case is mostly **capacity planning** (VRAM per model) plus **process layout**, once each GPU is trustworthy in isolation.

## Upstream projects you will actually use

| Resource | Role |
|----------|------|
| [NVIDIA DGX Spark Playbooks — Connect two Sparks](https://github.com/NVIDIA/dgx-spark-playbooks/tree/main/nvidia/connect-two-sparks) | Baseline physical + OS + SSH + network expectations. |
| [eugr/spark-vllm-docker](https://github.com/eugr/spark-vllm-docker) | Dockerized vLLM + `launch-cluster.sh`, Ray, NCCL-oriented env, recipes. |

This compass **does not replace** those repos; it **orients** you inside them.

## From compass to application

- **[`examples/langgraph-connection.py`](examples/langgraph-connection.py)** — minimal **LangGraph** + `ChatOpenAI` pointed at `http://<head>:8000/v1` (OpenAI-compatible vLLM). Install deps with [`examples/requirements-langgraph.txt`](examples/requirements-langgraph.txt).

## Search terms

- DGX Spark cluster setup
- DGX Spark multi-node vLLM
- vLLM tensor parallel across nodes
- NCCL RoCE troubleshooting
- Ray distributed inference on DGX Spark
- Connect two DGX Sparks 200G

## Contributing

If you hit a new failure mode and found the fix, consider adding a short entry to `docs/troubleshooting-and-pitfalls.md` or a command snippet to `docs/playbook-commands.md` so the next person spends fewer weekends on the same wall.
