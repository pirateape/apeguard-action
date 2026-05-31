# 🔒 ApeGuard GitHub Action

[![CI](https://github.com/pirateape/apeguard-action/actions/workflows/ci.yml/badge.svg)](https://github.com/pirateape/apeguard-action/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Layered security scanning in CI/CD** — Gitleaks (secrets), Semgrep (SAST), Trivy (SCA + container), and Nuclei (DAST). Every finding is mapped to the [Unified Zero Trust Framework (UZTF)](https://github.com/pirateape/unified-zero-trust-framework) with quantitative scoring.

```yaml
- uses: pirateape/apeguard-action@v1
  with:
    scan-path: .
    layers: secrets,sast,sca
    format: sarif
    upload-sarif: true
```

## Features

- **5 scanner layers** — secrets scanning, static analysis, dependency audit, container scan, web DAST
- **Zero Trust scorecard** — every finding maps to one of 8 UZTF pillars (0–800 score)
- **SARIF upload** — results appear in GitHub Security tab
- **Audience reports** — technical, executive, and roadmap formats
- **Minimal setup** — no configuration files needed for basic usage

## Usage

### Quick start — CI gate

```yaml
name: Security Scan
on: [push, pull_request]

jobs:
  security-scan:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write  # for SARIF upload
    steps:
      - uses: actions/checkout@v4
      - uses: pirateape/apeguard-action@v1
        with:
          scan-path: .
          format: sarif
          upload-sarif: true
```

### Full configuration

```yaml
- uses: pirateape/apeguard-action@v1
  with:
    # Directory or repository to scan (default: '.')
    scan-path: ./src

    # Scanner layers to enable (default: 'secrets,sast,sca')
    #   secrets    — Gitleaks (hardcoded secrets, credentials)
    #   sast       — Semgrep (code vulnerabilities, injections)
    #   sca        — Trivy (dependency vulnerabilities, CVEs)
    #   container  — Trivy container (Docker image vulnerabilities)
    #   dast       — Nuclei (web application DAST)
    layers: secrets,sast,sca,container

    # Report format (default: 'sarif')
    #   md     — Markdown report (tech + executive + roadmap)
    #   json   — Structured JSON with scorecard and findings
    #   sarif  — SARIF 2.1 for GitHub Security tab integration
    #   html   — Standalone HTML report with visual scorecard
    format: sarif

    # Upload SARIF to GitHub Security tab (default: 'true')
    upload-sarif: true

    # ApeGuard version (default: 'latest')
    version: 0.1.0

    # Fail workflow on findings (default: 'never')
    #   never    — always pass, report results
    #   high     — fail on high or critical findings
    #   critical — fail only on critical findings
    fail-on: high
```

### Fail-on example

```yaml
- uses: pirateape/apeguard-action@v1
  with:
    layers: secrets,sast,sca
    format: md
    fail-on: high
```

## Outputs

| Output | Description |
|--------|-------------|
| `overall-score` | Overall UZTF score (0–800) |
| `findings-count` | Total number of findings |
| `report-path` | Path to generated report file |

## Example workflow — deploy gate

```yaml
name: Security Gate
on:
  pull_request:
    branches: [main]

jobs:
  security-gate:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
    steps:
      - uses: actions/checkout@v4
      - uses: pirateape/apeguard-action@v1
        id: scan
        with:
          layers: secrets,sast,sca,container
          format: sarif
          upload-sarif: true
          fail-on: high

      - name: Gate check
        if: failure()
        run: |
          echo "❌ Security gate failed — score: ${{ steps.scan.outputs.overall-score }}/800"
          echo "   Findings: ${{ steps.scan.outputs.findings-count }}"
          exit 1
```

## About

**ApeGuard** is an open-source security scanning CLI written in Rust. This action wraps it for seamless CI/CD integration.

- [ApeGuard CLI](https://github.com/pirateape/ape-guard) — the scanner engine
- [Unified Zero Trust Framework](https://github.com/pirateape/unified-zero-trust-framework) — the scoring model
- [Azure-Security](https://github.com/pirateape/Azure-Security) — Azure defense-in-depth library (complementary)

## License

Elastic License 2.0 — see [LICENSE](./LICENSE).
