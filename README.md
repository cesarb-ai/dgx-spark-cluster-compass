# DGX Spark cluster compass

A **human-readable map** for people who are new to clustering two (or more) **NVIDIA DGX Spark** units. This is not an official NVIDIA project. It exists because connecting Sparks with a high-speed cable is **not** plug-and-play: you must succeed at several independent layers before tensor-parallel inference “feels like one brain.”

## Who this is for

- You bought multiple Sparks and expected the interconnect to “just work.”
- You are comfortable on the command line but have not clustered GPUs before.
- You want to **know where failures actually live** (network vs. SSH vs. Ray vs. NCCL vs. vLLM vs. weights on disk).

## How to use this repo

1. Read [**Clustering stack (layers and handshakes)**](docs/clustering-stack.md) once. It explains what must succeed, in order, and includes diagrams.
2. Keep [**Operational playbook**](docs/playbook-commands.md) handy when you launch or recover from a bad state.
3. When something breaks, start with [**Troubleshooting and pitfalls**](docs/troubleshooting-and-pitfalls.md) and map the symptom back to a layer.
4. Use [**References**](docs/references.md) for authoritative upstream docs (NVIDIA playbook, community Docker/Ray/vLLM stack).

## Mental model in one sentence

**Clustering** here means: physical link → correct IPs → SSH and orchestration (often Ray) → **NCCL** over RDMA/Ethernet for GPU collectives → **vLLM** with **tensor parallelism (TP)** split across nodes → a single API that uses **all** GPUs as one logical model—**if** every layer above agrees on addresses, ports, devices, and file paths.

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

## Contributing

If you hit a new failure mode and found the fix, consider adding a short entry to `docs/troubleshooting-and-pitfalls.md` or a command snippet to `docs/playbook-commands.md` so the next person spends fewer weekends on the same wall.
