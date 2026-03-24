#!/usr/bin/env bash
set -euo pipefail

# Start JupyterLab on a Spark host from a known venv.
# Usage:
#   ./scripts/start-remote-jupyter.sh
#   ./scripts/start-remote-jupyter.sh <venv_path> <port> [notebook_dir]

VENV_PATH="${1:-$HOME/ai_env}"
PORT="${2:-8888}"
HOST="${JUPYTER_BIND_IP:-127.0.0.1}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
NOTEBOOK_DIR="${3:-$REPO_ROOT/wizard}"

if [[ ! -f "$VENV_PATH/bin/activate" ]]; then
  echo "Venv not found at: $VENV_PATH"
  echo "Pass a venv path as first arg, e.g.:"
  echo "  ./scripts/start-remote-jupyter.sh \$HOME/ai_env 8888"
  exit 1
fi

if [[ ! -d "$NOTEBOOK_DIR" ]]; then
  echo "Notebook directory not found: $NOTEBOOK_DIR"
  echo "Pass a valid directory as third arg."
  exit 1
fi

# shellcheck disable=SC1090
source "$VENV_PATH/bin/activate"

if ! python -m jupyter --version >/dev/null 2>&1; then
  echo "Jupyter is not installed in this venv: $VENV_PATH"
  echo "Install with:"
  echo "  pip install jupyterlab"
  exit 1
fi

echo "Using python: $(which python)"
echo "Notebook dir: $NOTEBOOK_DIR"
echo "Starting JupyterLab on ${HOST}:${PORT} (no browser)..."
echo "From laptop, tunnel with:"
echo "  ssh -N -L ${PORT}:127.0.0.1:${PORT} <user>@<spark-lan-ip>"
echo "Then open:"
echo "  http://127.0.0.1:${PORT}"
echo

exec python -m jupyter lab --no-browser --ip="$HOST" --port="$PORT" --notebook-dir="$NOTEBOOK_DIR"
