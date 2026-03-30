---
# Python Data Visualization Setup
# Shared configuration for Python-based data visualization workflows

tools:
  cache-memory: true
  bash:
    - "*"

network:
  allowed:
    - defaults
    - python

safe-outputs:
  upload-asset:

steps:
  - name: Setup Python environment
    run: |
      mkdir -p /tmp/gh-aw/python
      mkdir -p /tmp/gh-aw/python/data
      mkdir -p /tmp/gh-aw/python/charts
      mkdir -p /tmp/gh-aw/python/artifacts
      echo "Python environment setup complete"

  - name: Install Python scientific libraries
    run: |
      pip install --user --quiet numpy pandas matplotlib seaborn scipy
      python3 -c "import numpy; print(f'NumPy {numpy.__version__} installed')"
      python3 -c "import pandas; print(f'Pandas {pandas.__version__} installed')"
      python3 -c "import matplotlib; print(f'Matplotlib {matplotlib.__version__} installed')"
      python3 -c "import seaborn; print(f'Seaborn {seaborn.__version__} installed')"
      echo "All scientific libraries installed successfully"

  - name: Upload generated charts
    if: always()
    uses: actions/upload-artifact@v6
    with:
      name: data-charts
      path: /tmp/gh-aw/python/charts/*.png
      if-no-files-found: warn
      retention-days: 30

  - name: Upload source files and data
    if: always()
    uses: actions/upload-artifact@v6
    with:
      name: python-source-and-data
      path: |
        /tmp/gh-aw/python/*.py
        /tmp/gh-aw/python/data/*
      if-no-files-found: warn
      retention-days: 30
---

# Python Data Visualization Guide

Python scientific libraries (NumPy, Pandas, Matplotlib, Seaborn, SciPy) are installed and ready.
Working directory: `/tmp/gh-aw/python/` with subdirectories `data/`, `charts/`, `artifacts/`.

**CRITICAL**: Data must NEVER be inlined in Python code. Always store data in external files and load using pandas.

```python
import matplotlib.pyplot as plt
import seaborn as sns

sns.set_style("whitegrid")
fig, ax = plt.subplots(figsize=(10, 6), dpi=300)

# Load data from external file
data = pd.read_csv('/tmp/gh-aw/python/data/data.csv')

plt.savefig('/tmp/gh-aw/python/charts/chart.png',
            dpi=300, bbox_inches='tight', facecolor='white', edgecolor='none')
```
