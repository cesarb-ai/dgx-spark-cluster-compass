## Contributing

Thanks for helping improve this guide.

### What to contribute

- New failure modes and fixes in `docs/troubleshooting-and-pitfalls.md`
- Operational command snippets in `docs/playbook-commands.md`
- Clarifications for `docs/clustering-stack.md`
- Notebook improvements in `wizard/`

### Contribution flow

1. Fork the repository and create a feature branch.
2. Keep changes focused and scoped to one topic.
3. Update docs and examples in the same PR when behavior changes.
4. Open a pull request with:
   - What failed before
   - What you changed
   - How you verified on real hardware or a reproducible setup

### Style

- Prefer practical, reproducible instructions over theory.
- Include exact commands, expected output, and common failure signals.
- Use clear section headings and short paragraphs.

### Scope note

This repo is a community compass for multi-node DGX Spark + vLLM workflows.
Official NVIDIA playbooks and upstream project docs remain source of truth.
