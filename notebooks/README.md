# Running MonthlyReport.ipynb locally in VS Code

`MonthlyReport.ipynb` used to hardcode the `Z:\Public\Dirk\CodeProjects\OffDesk
Assignment\...` network paths and resolve its data files against whatever the
current working directory happened to be. Both now come from `.env`, so the
notebook runs on your own machine without editing any cell.

## One-time setup

**1. Open the repo folder as the VS Code workspace** (`File > Open Folder`,
pick the repo root — not the `notebooks` folder). The committed
`.vscode/settings.json` only applies to that workspace.

**2. Install the recommended extensions** — VS Code will prompt you from
`.vscode/extensions.json`; otherwise install Python, Pylance and Jupyter by hand.

**3. Create the virtual environment and install the dependencies.** The
notebook was last run on Python 3.12; from the repo root in PowerShell:

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
```

`.vscode/settings.json` already points `python.defaultInterpreterPath` at
`.venv\Scripts\python.exe`. On macOS/Linux use `python3.12 -m venv .venv`,
`source .venv/bin/activate`, and change that setting to `.venv/bin/python`.

**4. Point the notebook at the internal `ao` package.** Copy `.env.example` to
`.env` and set `AO_CODE_PATHS` to your local clones of `quantresearch` and
`ao_common` (semicolon-separated):

```
AO_CODE_PATHS=C:\Users\ramon.balje\code\AOI\quantresearch;C:\Users\ramon.balje\code\AOI\ao_common
```

`ao` is not on PyPI and is not installed by `requirements.txt` — the notebook
puts these directories on `sys.path`. If those repos have their own
`requirements.txt`, install it into the same `.venv`. Leaving `AO_CODE_PATHS`
unset falls back to the old `Z:` drive paths.

**5. Put the input data in `data/`.** At minimum `mm_stats_data.xlsx`; see
[`../data/README.md`](../data/README.md). The kernel's working directory is
`<repo>/data`, so that is also where the parquet caches, `output_plots/` and
`output_data/` are written. Keep the data elsewhere by setting
`MONTHLY_REPORT_DATA_DIR` in `.env`.

## Check the setup

`tools/check_env.py` verifies all of the above in one shot — interpreter,
dependencies, where `ao` lives, and whether the data files are in place:

```powershell
python tools\check_env.py
```

If it can't find `ao`, point it at the folder holding your clones and it will
print the exact `AO_CODE_PATHS` line to paste into `.env`:

```powershell
python tools\check_env.py --search C:\Users\ramon.balje\code
```

It exits 0 when everything needed to run the notebook is present, 1 with a
list of what to fix.

## Running it

Open `notebooks/MonthlyReport.ipynb`, click **Select Kernel** in the top right,
choose the `.venv` interpreter, then **Run All**.

The first cell prints exactly what it resolved, so a misconfigured path shows up
immediately instead of failing several cells later:

```
ao code paths:
  [ok ] C:\Users\ramon.balje\code\AOI\quantresearch
  [ok ] C:\Users\ramon.balje\code\AOI\ao_common
data dir: C:\Users\ramon.balje\code\Ramon\data [ok]
```

Adjust the four inputs at the top of the first cell (`USER_START_DATE`,
`USER_END_DATE`, `USER_SECTORS`, `INCLUDE_CURRENT_MONTH`) as before.

## Troubleshooting

| Symptom | Cause |
| --- | --- |
| `ModuleNotFoundError: No module named 'ao'` | `AO_CODE_PATHS` wrong or unset — check the `[MISSING]` markers printed by cell 1. Restart the kernel after editing `.env`; VS Code reads it when the kernel starts. |
| `FileNotFoundError: ...mm_stats_data.xlsx` | File not in `data/` (or `MONTHLY_REPORT_DATA_DIR` points elsewhere). |
| `ImportError: Missing optional dependency 'openpyxl'` / `'pyarrow'` | Dependencies not installed into the interpreter the kernel is using — re-check the kernel picker shows `.venv`. |
| `DataProvider` connection errors | `ENVIRONMENT = 'prod'` needs network access to the prod data provider (VPN / on-site). The trade CSVs are only re-fetched when missing or incomplete, so with them present in `data/` most cells run offline. |
| `TypeError: only list-like objects are allowed to be passed to isin(), you passed a [NoneType]` | `USER_SECTORS` is not one of the `DESK_GROUPS` keys. The notebook ships with `USER_SECTORS = "SSO"`, which is not a valid key — the closest match is `"SSO (excl. Sectors A + B)"`. |
