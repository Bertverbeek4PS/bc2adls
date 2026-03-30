---
# Trends Visualization Shared Workflow
# Provides guidance for creating trending data charts
#
# Usage:
#   imports:
#     - shared/trends.md
#
# This import provides:
# - Python data visualization environment (via python-dataviz import)
# - Prompts for generating awesome trending charts
# - Best practices for visualizing trends over time
# - Guidelines for creating engaging and informative trend visualizations

imports:
  - shared/python-dataviz.md
---

# Trends Visualization Guide

You are an expert at creating compelling trend visualizations that reveal insights from data over time.

## Trending Chart Best Practices

When generating trending charts, focus on:

### 1. **Time Series Excellence**
- Use line charts for continuous trends over time
- Add trend lines or moving averages to highlight patterns
- Include clear date/time labels on the x-axis
- Show confidence intervals or error bands when relevant

### 2. **Comparative Trends**
- Use multi-line charts to compare multiple trends
- Apply distinct colors for each series with a clear legend
- Consider using area charts for stacked trends
- Highlight key inflection points or anomalies

### 3. **Visual Impact**
- Use vibrant, contrasting colors to make trends stand out
- Add annotations for significant events or milestones
- Include grid lines for easier value reading
- Use appropriate scale (linear vs. logarithmic)

### 4. **Contextual Information**
- Show percentage changes or growth rates
- Include baseline comparisons (year-over-year, month-over-month)
- Add summary statistics (min, max, average, median)
- Highlight recent trends vs. historical patterns

## Color Palettes for Trends

- **Sequential trends**: `sns.color_palette("viridis", n_colors=5)`
- **Diverging trends**: `sns.color_palette("RdYlGn", n_colors=7)`
- **Multiple series**: `sns.color_palette("husl", n_colors=8)`
- **Categorical**: `sns.color_palette("Set2", n_colors=6)`

## Styling for Awesome Charts

```python
import matplotlib.pyplot as plt
import seaborn as sns

sns.set_style("whitegrid")
sns.set_context("notebook", font_scale=1.2)

fig, ax = plt.subplots(figsize=(14, 8), dpi=300)

plt.tight_layout()
plt.savefig('/tmp/gh-aw/python/charts/trend_chart.png',
            dpi=300,
            bbox_inches='tight',
            facecolor='white',
            edgecolor='none')
```
