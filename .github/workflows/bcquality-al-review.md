---
name: BCQuality AL Review
description: Advisory AL code review of pull requests using the Microsoft BCQuality knowledge base.
on:
  pull_request:
    paths:
      - "**/*.al"

permissions:
  contents: read
  pull-requests: read
  copilot-requests: write

engine: copilot
network: defaults
timeout-minutes: 25
# Custom top-level steps below suppress gh-aw's default agent-job checkout, so the workflow
# repository is checked out explicitly as the first step. Without it the workspace root has
# no .git and gh-aw's "Configure Git credentials" step fails with exit 128.
# The public Microsoft BCQuality knowledge base is then checked out into ./.bcquality so the
# review reads it from disk rather than the network. It is a public repo, so the default
# GITHUB_TOKEN is sufficient — no PAT or GitHub App token required.
steps:
  - name: Checkout repository
    uses: actions/checkout@v7.0.1
    with:
      fetch-depth: 0
      persist-credentials: false
  - name: Checkout BCQuality knowledge base
    uses: actions/checkout@v7.0.1
    with:
      repository: microsoft/BCQuality
      ref: main
      path: .bcquality
      persist-credentials: false
  - name: Build BCQuality knowledge index (best effort)
    working-directory: .bcquality
    continue-on-error: true
    shell: pwsh
    run: ./tools/Build-KnowledgeIndex.ps1
tools:
  github:
    mode: gh-proxy
    toolsets: [pull_requests]
  bash:
    - "cat:*"
    - "ls:*"
    - "grep:*"
    - "find:*"
    - "head:*"
    - "tail:*"
    - "wc:*"
safe-outputs:
  add-comment:
    max: 1
    hide-older-comments: true
    github-token: ${{ secrets.GH_AW_WRITE_TOKEN }}
---

<steps>
  <step name="Checkout BCQuality knowledge base">
    <uses>actions/checkout@v5</uses>
    <with>
      <repository>microsoft/BCQuality</repository>
      <ref>main</ref>
      <path>.bcquality</path>
    </with>
  </step>

  <step name="Build BCQuality knowledge index (best effort)">
    <continue-on-error>true</continue-on-error>
    <shell>pwsh</shell>
    <working-directory>.bcquality</working-directory>
    <run>
./tools/Build-KnowledgeIndex.ps1
    </run>
  </step>

  <step name="Ensure working directory is repository root">
    <shell>bash</shell>
    <working-directory>${{ github.workspace }}</working-directory>
    <run>
set -euo pipefail
cd "$GITHUB_WORKSPACE"
if [ ! -d .git ]; then
  echo "::error::.git directory not found in GITHUB_WORKSPACE=$GITHUB_WORKSPACE"
  pwd
  ls -la
  exit 1
fi
git rev-parse --is-inside-work-tree
    </run>
  </step>

  <step name="Review AL changes against BCQuality guidance">
    <prompt>
You are reviewing AL code changes in this pull request.

Use the checked-out BCQuality knowledge base at `.bcquality/` as your primary reference.
Focus on:
- correctness and safety
- Business Central AL best practices
- maintainability and readability
- testability and upgrade safety

Requirements:
1) Inspect only files changed in this PR (especially `.al` files).
2) Provide concise findings with:
   - severity (high/medium/low)
   - file path and line(s) where possible
   - rationale
   - concrete suggested fix
3) If no issues are found, clearly say so.
4) Keep feedback actionable and brief.

When done, post one consolidated review comment via safe outputs.
    </prompt>
  </step>
</steps>

<safe-outputs>
  <add-comment hide-older-comments="true" max="1" />
  <noop max="1" />
</safe-outputs>