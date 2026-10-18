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

from weasyprint import HTML, CSS
html = DOCS / "MIE402_Lab4_Analysis_Workflow_Fall2026.html"
pdf = DOCS / "MIE402_Lab4_Free_Response_Instructions_Fall2026.pdf"
css = CSS(string="""@page {size: Letter; margin: 0.75in 0.78in; }
body {background:white !important; color:#16283b !important; font-family:Arial,sans-serif; font-size:10.5pt; line-height:1.42}
main {max-width:none !important; margin:0 !important; padding:0 !important}
h1 {font-size:22pt; line-height:1.18} h2 {font-size:14pt; margin:16pt 0 6pt; break-after:avoid}
p, li, td {orphans:2; widows:2}
figure, table {break-inside:avoid}
img {max-height:2.05in; width:auto}
.equation {font-size:12.5pt !important; overflow:visible !important}
a {color:#184d78} td,th {font-size:9.3pt}
""")
HTML(filename=str(html), base_url=str(DOCS)).write_pdf(str(pdf), stylesheets=[css])
import fitz
doc=fitz.open(pdf)
assert len(doc)>=2 and len(doc)<20, f"Unexpected PDF page count: {len(doc)}"
assert all(len(p.get_text().strip())>50 for p in doc)
assert "seven" in " ".join(p.get_text() for p in doc).lower()
print(f"Rebuilt Lab 4 instructions PDF: {len(doc)} pages, {pdf.stat().st_size} bytes")
