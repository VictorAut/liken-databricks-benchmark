# liken-databricks-benchmark

## Tooling

All tooling is pinned in `mise.toml` and orchestrated with `task`. Run
tasks through mise (a mise-activated shell or `mise exec`) so the pinned
versions are on PATH.

    mise install && task install
