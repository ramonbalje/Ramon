"""Diagnose the local setup for notebooks/MonthlyReport.ipynb.

Checks the interpreter, the pip dependencies, the location of the internal `ao`
package and the report data files, then prints the exact AO_CODE_PATHS line to
paste into .env.

Usage:
    python tools/check_env.py
    python tools/check_env.py --search C:\\Users\\me\\code --search "Z:\\Public"

Exit code is 0 when everything needed to run the notebook is present, 1
otherwise.
"""

from __future__ import annotations

import argparse
import importlib
import os
import sys
from pathlib import Path

OK = "[ok]     "
BAD = "[MISSING]"
WARN = "[warn]   "

REPO_ROOT = Path(__file__).resolve().parent.parent

# (import name, pip name) for everything the notebook imports directly.
REQUIRED = [
    ("pandas", "pandas"),
    ("numpy", "numpy"),
    ("matplotlib", "matplotlib"),
    ("tqdm", "tqdm"),
    ("openpyxl", "openpyxl"),
    ("pyarrow", "pyarrow"),
    ("pkg_resources", "setuptools"),
    ("dotenv", "python-dotenv"),
    ("ipykernel", "ipykernel"),
]

# Only needed if you also run the Prof Trade SQL script.
OPTIONAL = [
    ("sqlalchemy", "sqlalchemy"),
    ("psycopg2", "psycopg2-binary"),
]

DATA_FILES = [
    ("mm_stats_data.xlsx", True),
    ("prof_trades_data.csv", False),
    ("screen_trades_data.csv", False),
]

# Directories never worth walking into while hunting for `ao`.
SKIP_DIRS = {
    ".git", ".hg", ".svn", "__pycache__", ".ipynb_checkpoints",
    "node_modules", ".venv", "venv", "env", "site-packages",
    ".mypy_cache", ".pytest_cache", ".tox", "build", "dist",
}

MAX_DEPTH = 4


def dist_version(import_name: str, pip_name: str) -> str:
    """Version of an installed dependency, via the module or its metadata."""
    module = sys.modules.get(import_name)
    version = getattr(module, "__version__", "") if module else ""
    if version:
        return str(version)
    try:
        from importlib.metadata import PackageNotFoundError, version as metadata_version

        return metadata_version(pip_name)
    except (ImportError, PackageNotFoundError):
        return ""


def header(title: str) -> None:
    print(f"\n{title}")
    print("-" * len(title))


def load_dotenv_if_present() -> Path | None:
    """Load .env the same way the notebook's bootstrap cell does."""
    try:
        from dotenv import load_dotenv
    except ImportError:
        return None
    for candidate in [REPO_ROOT, Path.cwd(), *Path.cwd().parents]:
        env_file = candidate / ".env"
        if env_file.is_file():
            load_dotenv(env_file)
            return env_file
    return None


def check_interpreter() -> list[str]:
    header("Interpreter")
    problems: list[str] = []
    print(f"  python     {sys.version.split()[0]}")
    print(f"  executable {sys.executable}")

    in_venv = sys.prefix != sys.base_prefix
    if in_venv:
        print(f"{OK} running inside a virtual environment ({sys.prefix})")
    else:
        print(f"{WARN} not running inside a virtual environment.")
        print("          Activate .venv first, or pick the .venv kernel in VS Code.")

    if sys.version_info < (3, 10):
        problems.append(f"Python {sys.version.split()[0]} is older than 3.10")
        print(f"{BAD} the notebook was last run on 3.12; 3.10+ recommended")
    return problems


def check_packages() -> list[str]:
    header("Dependencies")
    problems: list[str] = []

    for import_name, pip_name in REQUIRED:
        try:
            importlib.import_module(import_name)
        except ImportError:
            print(f"{BAD} {pip_name}")
            problems.append(f"{pip_name} is not installed")
            continue
        print(f"{OK} {pip_name} {dist_version(import_name, pip_name)}".rstrip())

    try:
        import pandas as pd

        if pd.__version__.split(".")[0] not in {"2"}:
            print(
                f"{WARN} pandas {pd.__version__} is outside the 2.x range the "
                "notebook was written for"
            )
    except ImportError:
        pass

    print()
    for import_name, pip_name in OPTIONAL:
        try:
            importlib.import_module(import_name)
        except ImportError:
            print(f"{WARN} {pip_name} not installed (only needed for the SQL script)")
            continue
        print(f"{OK} {pip_name} {dist_version(import_name, pip_name)}".rstrip())

    if problems:
        print(f"\n  Fix with: pip install -r {REPO_ROOT / 'requirements.txt'}")
    return problems


def iter_dirs(root: Path, max_depth: int = MAX_DEPTH):
    """Yield directories under root, depth-limited, skipping noise."""
    if not root.is_dir():
        return
    stack = [(root, 0)]
    while stack:
        current, depth = stack.pop()
        if depth >= max_depth:
            continue
        try:
            entries = list(current.iterdir())
        except (PermissionError, OSError):
            continue
        for entry in entries:
            try:
                if not entry.is_dir():
                    continue
            except OSError:
                continue
            if entry.name in SKIP_DIRS:
                continue
            yield entry
            stack.append((entry, depth + 1))


def looks_like_ao(candidate: Path) -> bool:
    """True if `candidate` is an importable `ao` package directory."""
    if candidate.name != "ao":
        return False
    if (candidate / "__init__.py").is_file():
        return True
    # PEP 420 namespace package: no __init__.py, but has real subpackages.
    return any(child.is_dir() and not child.name.startswith(".") for child in candidate.iterdir())


def search_roots(extra: list[str]) -> list[Path]:
    roots: list[Path] = []

    def add(path: Path) -> None:
        path = path.expanduser()
        if path not in roots:
            roots.append(path)

    for raw in extra:
        add(Path(raw))

    # Parents of whatever AO_CODE_PATHS already points at
    for raw in os.environ.get("AO_CODE_PATHS", "").split(";"):
        raw = raw.strip()
        if raw:
            add(Path(raw))
            add(Path(raw).parent)

    home = Path.home()
    add(home / "code")
    add(home / "code" / "AOI")
    add(home / "source")
    add(home / "repos")
    add(REPO_ROOT.parent)
    add(Path(r"Z:\Public\Dirk\CodeProjects\OffDesk Assignment"))
    return roots


def check_ao(extra_roots: list[str]) -> list[str]:
    header("Internal `ao` package")
    problems: list[str] = []

    configured_raw = os.environ.get("AO_CODE_PATHS", "")
    if configured_raw:
        print("  AO_CODE_PATHS is set to:")
        for raw in configured_raw.split(";"):
            raw = raw.strip()
            if not raw:
                continue
            path = Path(raw).expanduser()
            marker = OK if path.is_dir() else BAD
            print(f"{marker} {path}")
    else:
        print(f"{WARN} AO_CODE_PATHS is not set; the notebook falls back to the Z: paths")

    roots = search_roots(extra_roots)
    print("\n  Searching for `ao` package directories under:")
    for root in roots:
        suffix = "" if root.is_dir() else "   (not present)"
        print(f"      {root}{suffix}")

    found: list[Path] = []
    for root in roots:
        if not root.is_dir():
            continue
        if looks_like_ao(root):
            found.append(root)
        for directory in iter_dirs(root):
            if looks_like_ao(directory) and directory not in found:
                found.append(directory)

    if not found:
        print(f"\n{BAD} no `ao` package found.")
        print("          Pass the folder holding your clones, e.g.:")
        print("            python tools/check_env.py --search C:\\Users\\you\\code")
        problems.append("could not locate the `ao` package")
        return problems

    parents: list[Path] = []
    print(f"\n  Found {len(found)} `ao` package director{'y' if len(found) == 1 else 'ies'}:")
    for package_dir in found:
        kind = "package" if (package_dir / "__init__.py").is_file() else "namespace package"
        print(f"{OK} {package_dir}  ({kind})")
        if package_dir.parent not in parents:
            parents.append(package_dir.parent)

    print("\n  Paste this into .env (parent directories, not the `ao` folders):\n")
    print("    AO_CODE_PATHS=" + ";".join(str(p) for p in parents))
    print("\n  Order matters if `ao` is split across repos: the notebook's original")
    print("  setup listed quantresearch before ao_common.")

    return problems


def check_import_ao() -> list[str]:
    header("import ao")
    problems: list[str] = []

    for raw in os.environ.get("AO_CODE_PATHS", "").split(";"):
        raw = raw.strip()
        if raw and raw not in sys.path:
            sys.path.insert(0, raw)

    try:
        import ao
    except ImportError as exc:
        print(f"{BAD} import ao failed: {exc}")
        print("          Set AO_CODE_PATHS in .env to the parent directories listed above.")
        return ["`import ao` failed"]

    print(f"{OK} import ao")
    print(f"          __file__ = {getattr(ao, '__file__', None)}")
    path_entries = list(getattr(ao, "__path__", []))
    print(f"          __path__ = {path_entries}")

    try:
        importlib.import_module("ao.quantlib")
        print(f"{OK} import ao.quantlib")
    except ImportError as exc:
        print(f"{BAD} import ao.quantlib failed: {exc}")
        if len(path_entries) < 2:
            print("          `ao` resolved from a single directory. If quantlib lives in")
            print("          the other repo, add it to AO_CODE_PATHS too.")
        problems.append("`import ao.quantlib` failed")
    return problems


def check_data() -> list[str]:
    header("Report data")
    problems: list[str] = []

    configured = os.environ.get("MONTHLY_REPORT_DATA_DIR")
    data_dir = Path(configured).expanduser() if configured else REPO_ROOT / "data"
    source = "MONTHLY_REPORT_DATA_DIR" if configured else "default (<repo>/data)"
    print(f"  data dir: {data_dir}  [{source}]")

    if not data_dir.is_dir():
        print(f"{BAD} directory does not exist")
        return [f"data directory {data_dir} does not exist"]

    for name, required in DATA_FILES:
        path = data_dir / name
        if path.is_file():
            size_mb = path.stat().st_size / 1_048_576
            print(f"{OK} {name} ({size_mb:.1f} MB)")
        elif required:
            print(f"{BAD} {name} - required")
            problems.append(f"{name} is missing from {data_dir}")
        else:
            print(f"{WARN} {name} - absent; will be re-fetched from DataProvider")
    return problems


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--search",
        action="append",
        default=[],
        metavar="DIR",
        help="extra directory to search for the `ao` package (repeatable)",
    )
    args = parser.parse_args()

    print("MonthlyReport environment check")
    print(f"repo: {REPO_ROOT}")
    env_file = load_dotenv_if_present()
    if env_file:
        print(f".env: {env_file}")
    else:
        print(".env: not found (or python-dotenv not installed)")

    problems: list[str] = []
    problems += check_interpreter()
    problems += check_packages()
    problems += check_ao(args.search)
    problems += check_import_ao()
    problems += check_data()

    header("Summary")
    if problems:
        print(f"{len(problems)} problem(s) to fix:")
        for problem in problems:
            print(f"  - {problem}")
        print("\nSee notebooks/README.md for the setup steps.")
        return 1
    print(f"{OK} everything needed to run notebooks/MonthlyReport.ipynb is in place")
    return 0


if __name__ == "__main__":
    sys.exit(main())
