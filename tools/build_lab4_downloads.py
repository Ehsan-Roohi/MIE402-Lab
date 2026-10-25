#!/usr/bin/env python3
"""Rebuild student-facing Lab 4 downloads from current versioned sources.

Preserve unrelated archive members, but replace stale named Lab 4 inputs.
"""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
from io import BytesIO
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "site" / "docs"
MAIN = "MIE402_Lab4_Analyze_Free_Response.m"
README = "MIE402_Lab4_MATLAB_README.txt"
NOTEBOOK = "MIE402_PreLab4_Fall2026_Student.ipynb"

def preserve_and_update(zip_name, replacements, remove_suffix=None):
    target = DOCS / zip_name
    originals = {}
    if target.exists():
        with ZipFile(target) as old:
            for entry in old.infolist():
                if entry.is_dir():
                    continue
                filename = Path(entry.filename).name
                if ".." in Path(entry.filename).parts:
                    raise ValueError(f"Unsafe archive entry {entry.filename}")
                if remove_suffix and filename.lower().endswith(remove_suffix):
                    continue  # no stale copies of student notebook
                if filename in replacements:
                    continue  # replace old script/README with current versions
                originals[entry.filename] = old.read(entry)
    originals.update(replacements)
    with ZipFile(target, "w", ZIP_DEFLATED, compresslevel=8) as result:
        for key in sorted(originals):
            result.writestr(key, originals[key])
    with ZipFile(target) as result:
        assert result.testzip() is None
        for key, value in replacements.items():
            assert result.read(key) == value
    print(f"Rebuilt {zip_name}: {target.stat().st_size} bytes, {len(originals)} entries")

nb_bytes = (DOCS / NOTEBOOK).read_bytes()
nb = json.loads(nb_bytes)
assert nb["nbformat"] == 4
assert any("No programming" in "".join(c.get("source", [])) for c in nb["cells"])
matlab_source = (DOCS / MAIN).read_bytes()
assert b"residual" in matlab_source and b"position" in matlab_source
readme = (DOCS / README).read_bytes()
preserve_and_update("MIE402_Lab4_MATLAB_Files.zip", {MAIN: matlab_source, README: readme})
preserve_and_update("MIE402_PreLab4_Fall2026_Student_Canvas.zip", {
    NOTEBOOK: nb_bytes,
    "README_PreLab4.txt": (
        "MIE 402 Pre-Lab 4 · Fall 2026\n"
        "Open the supplied notebook in Google Colab. Students do not write code.\n"
        "Submit ONE Word/PDF on Canvas before your own Lab 4 section: calculations,\n"
        "predictions, labeled plots, and brief written interpretations.\n"
        "Source of record: https://github.com/Ehsan-Roohi/MIE402-Lab/blob/main/site/docs/"
        + NOTEBOOK + "\n"
    ).encode("utf-8"),
}, remove_suffix=".ipynb")

# The full laboratory manual is authored and visually reviewed separately.
# Do not replace it with the shorter HTML analysis supplement when rebuilding ZIPs.
import fitz
pdf = DOCS / "MIE402_Lab4_Free_Response_Instructions_Fall2026.pdf"
doc = fitz.open(pdf)
text = " ".join(p.get_text() for p in doc)
assert len(doc) >= 10, "The full laboratory manual must not be replaced by the short analysis supplement"
assert "Zero" in text and "spring" in text.lower() and "seven" in text.lower()
print(f"Preserved full Lab 4 instructions PDF: {len(doc)} pages, {pdf.stat().st_size} bytes")
