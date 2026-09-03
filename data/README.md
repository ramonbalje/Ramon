# data/

Working directory for `notebooks/MonthlyReport.ipynb`. `.vscode/settings.json`
sets `jupyter.notebookFileRoot` to this folder, so the notebook resolves all of
its files here.

Put these input files in this folder (they are git-ignored, so they stay local):

| File | Used for |
| --- | --- |
| `mm_stats_data.xlsx` | required — sheets `MS`, `Vega Share`, `Margin Rev` |
| `prof_trades_data.csv` | professional trades cache; re-fetched from `DataProvider` if missing |
| `screen_trades_data.csv` | screen trades cache; re-fetched from `DataProvider` if missing |

The notebook then writes, also here:

- `prof_trades_processed.parquet`, `screen_trades_processed.parquet` — processing caches, rebuilt when the CSVs are newer
- `output_plots/` — PNGs at 300 dpi
- `output_data/` — Excel exports

To keep the data somewhere else (e.g. the `Z:` drive), set
`MONTHLY_REPORT_DATA_DIR` in `.env` instead of moving the files.
