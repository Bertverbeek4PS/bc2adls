---
description: Creates weekly summary of issue activity including trends, charts, and insights every Monday
timeout-minutes: 20
strict: true
on:
  schedule:
    - cron: "0 15 * * 1"  # Weekly on Mondays at 3 PM UTC
  workflow_dispatch:
permissions:
  issues: read
tracker-id: weekly-issue-summary
engine: copilot
network:
  allowed:
    - defaults
    - python
    - node
sandbox:
  agent: awf
tools:
  edit:
  bash:
    - "*"
  github:
    lockdown: true
    toolsets:
      - issues
safe-outputs:
  upload-asset:
  create-discussion:
    title-prefix: "[Weekly Summary] "
    category: "audits"
    close-older-discussions: true
imports:
  - shared/mood.md
  - shared/reporting.md
  - shared/trends.md
---

# Weekly Issue Summary

## 📊 Trend Charts Requirement

**IMPORTANT**: Generate exactly 2 trend charts that showcase issue activity patterns over time.

### Chart Generation Process

**Phase 1: Data Collection**

Collect data for the past 30 days using GitHub API for the **bc2adls** repository:

1. **Issue Activity Data**:
   - Count of issues opened per day
   - Count of issues closed per day
   - Running count of open issues

2. **Issue Resolution Data**:
   - Average time to close issues (in days)
   - Distribution of issue lifespans

**Phase 2: Data Preparation**

Create CSV files in `/tmp/gh-aw/python/data/`:
- `issue_activity.csv` - Daily opened/closed counts and open count
- `issue_resolution.csv` - Resolution time statistics

**Phase 3: Chart Generation**

Generate exactly **2 high-quality trend charts**:

**Chart 1: Issue Activity Trends**
- Multi-line chart: issues opened/closed per week, running total of open issues
- X-axis: Last 12 weeks, Y-axis: Count
- Save as: `/tmp/gh-aw/python/charts/issue_activity_trends.png`

**Chart 2: Issue Resolution Time Trends**
- Line chart: average + median time to close (in days), 7-day moving average
- X-axis: Last 30 days, Y-axis: Days to resolution
- Save as: `/tmp/gh-aw/python/charts/issue_resolution_trends.png`

**Chart Quality Requirements**:
- DPI: 300 minimum, Figure size: 12x7 inches
- Use seaborn styling with professional color palette
- Include grid lines, clear labels and legend
- Title with context

**Phase 4: Upload & Embed Charts**

Upload both charts using `upload asset` tool, then embed URLs in the discussion.

---

## 📝 Report Formatting Guidelines

Use h3 (###) or lower for all headers. The discussion title serves as h1.

Your report structure:
1. **### Weekly Overview** (always visible): 1-2 paragraph summary of the week's issue activity
2. **### 📈 Issue Activity Trends**: Chart 1 + 2-3 sentence analysis
3. **### Key Trends** (always visible): Notable patterns, common issue types, emerging topics
4. **### Summary Statistics** (always visible): Total counts, comparison to previous week, breakdown by label
5. **### Detailed Issue Breakdown** (in `<details>` tags): Full list of issues with titles, numbers, authors, labels
6. **### Recommendations** (always visible): Actionable suggestions for the upcoming week

---

## Weekly Analysis

Analyze all issues opened in the **bc2adls** repository (${{ github.repository }}) over the last 7 days.

Create a comprehensive summary that includes:
- Total number of issues opened and closed
- List of issue titles with their numbers, authors, and labels
- Any notable patterns (BC-related bugs, Azure/Fabric feature requests, docs needs, etc.)
- Backlog health (growing or shrinking?)
- Issues needing attention (unlabeled, unanswered, stale)

Follow the **Report Formatting Guidelines** above to structure your report with:
- h3 (###) for main section headers
- Detailed issue lists wrapped in `<details>` tags
- Critical information (overview, trends, statistics, recommendations) always visible
