# References

## Official / vendor

- **Connect two Sparks (playbook)**  
  [NVIDIA `dgx-spark-playbooks` — `nvidia/connect-two-sparks`](https://github.com/NVIDIA/dgx-spark-playbooks/tree/main/nvidia/connect-two-sparks)  
  Use this for cabling expectations, stacked vs. other topologies, and first-time cluster networking and SSH hygiene.

- **NVIDIA Spark hub (discoverability)**  
  [NVIDIA Spark — Connect two Sparks](https://build.nvidia.com/spark/connect-two-sparks/stacked-sparks)  
  Often linked from community repos as the “start here” narrative for two-unit setups.

## Community stack used in practice

- **eugr / spark-vllm-docker**  
  [GitHub: `eugr/spark-vllm-docker`](https://github.com/eugr/spark-vllm-docker)  
  Docker image, `launch-cluster.sh`, Ray-backed multi-node vLLM, InfiniBand/RoCE-oriented configuration, `hf-download.sh`, networking notes under `docs/`.

## Concepts worth reading elsewhere (short list)

- **Blackwell / GB10 version alignment** — see [Blackwell / GB10 “version tax”](troubleshooting-and-pitfalls.md#blackwell--gb10-version-tax-cuda-pytorch-containers) in this repo; then confirm pins against **current** NVIDIA Spark documentation for your hardware generation.

- **NCCL** — collective communication library used when one process group spans GPUs (and nodes). Environment variables such as `NCCL_IB_HCA` and `NCCL_IB_GID_INDEX` steer which RDMA port and GID the traffic uses; wrong choices often look like “hang at FlashAttention” or silent startup stalls.
- **Ray** — optional but common **distributed executor** for vLLM in these recipes; it is *orchestration*, not the GPU math itself. You can sometimes bypass Ray (`--no-ray` in some workflows) to isolate whether a failure is Ray vs. NCCL vs. vLLM.
- **Tensor parallelism (TP)** — model shards across GPUs; **TP = number of GPUs** in the simple two-Spark, one-GPU-per-node case. Each participating node typically needs a **full local copy** of weights (or shared storage mounted the same way everywhere).
