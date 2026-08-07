# BTM date change → export → copy into master workbook

VBA macro to automate: changing the date on an open Bloomberg Terminal BTM
screen, triggering its export to Excel, and copying that data into a master
workbook.

## Setup

1. Open your master Excel workbook (the one you want the data copied into).
2. Add a sheet named `Data` (or change `TARGET_SHEET_NAME` in the macro).
3. Open the VBA editor (Alt+F11) → Insert → Module, and paste in the contents
   of `BTM_Export_Automation.bas`.
4. In Excel, enable macros / trust access to the VBA project if prompted
   (File → Options → Trust Center → Trust Center Settings → Macro Settings).
5. Run `RunFullBTMWorkflow` from the VBA editor (F5) or bind it to a button/
   keyboard shortcut on the master workbook.

## Calibration required

Two things in the script are placeholders because they depend on your exact
BTM screen and export setup, which can't be observed remotely:

- **`SetBTMDate`** — sends `{TAB 3}` to reach the date field, then types the
  new date and presses Enter. Watch how many Tabs (or clicks) it actually
  takes on your screen to land in the date field, and adjust the Tab count
  (or replace with the exact keystroke sequence you use).
- **`ExportCurrentScreenToExcel`** — currently just prompts you to trigger
  the export manually (click the Excel icon / right-click → Export) and
  click OK. If your BTM screen has a keyboard shortcut for export, replace
  the `MsgBox` with a `SendKeys` call using that shortcut.

## Two import paths, pick the one that matches your Bloomberg setup

- **`ImportLatestBloombergExport`** (used by default) — assumes Bloomberg's
  export opens a *new, unsaved Excel workbook* in the same Excel instance.
  It scans open workbooks for one that looks like a fresh export and copies
  its `UsedRange` into the master workbook.
- **`ImportFromExportFolder(folderPath)`** — use this instead if your
  export actually writes a file to disk (e.g. Desktop or a dedicated
  exports folder). It picks the most recently modified `.xls`/`.xlsx` file
  in that folder and copies its data in.

If neither exactly matches what you see when you click export, tell me what
does happen (new workbook opens vs. file saved, folder location, etc.) and
I can tighten the script.

## Notes / limitations

- This relies on `SendKeys` and window activation (`AppActivate`), which is
  inherently fragile UI automation — it requires the Bloomberg Terminal
  window to actually have focus and the field layout to match what's coded.
  Don't run other keyboard/mouse actions while it executes.
- `Application.Wait` pauses are conservative starting points; increase them
  if your terminal or export is slower to respond.
