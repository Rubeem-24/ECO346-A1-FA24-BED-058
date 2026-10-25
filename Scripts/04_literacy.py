"""04_second_language.py -- Question 5: the Question 3 band table and figure in Python.
Variant 2 = Sindh rural (prov_code 3, urban_rural 1).
Run from the repository root:  python scripts/04_second_language.py
"""
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
(ROOT / "figures").mkdir(exist_ok=True)
(ROOT / "tables").mkdir(exist_ok=True)

# --- data: same merge as the R scripts ---
pp = pd.read_csv(ROOT / "data" / "pslm_person_subset.csv")
hh = pd.read_csv(ROOT / "data" / "pslm_hh_subset.csv",
                 usecols=["hhid", "hhweight", "prov_code", "urban_rural"])
d = pp.merge(hh, on="hhid", how="left")

lit = d[(d.prov_code == 3) & (d.urban_rural == 1) &
        d.age.between(10, 64) & d.literate.notna()].copy()

# five-year bands by floor division (not pd.cut, whose default closes intervals on the right)
lit["band_start"] = (lit.age // 5) * 5
lit["mid"] = lit.band_start + 2

# --- band table: unweighted n and weighted literacy rate (percent) per band and sex ---
rows = []
for b, g in lit.groupby("band_start"):
    row = {"band": f"{b}-{b + 4}", "mid": b + 2}
    for sex, name in [(2, "women"), (1, "men")]:
        h = g[g.sex == sex]
        row[f"n_{name}"] = len(h)
        row[f"rate_{name}"] = 100 * np.average(h.literate, weights=h.hhweight)
    row["gap"] = row["rate_men"] - row["rate_women"]
    rows.append(row)
table = pd.DataFrame(rows)[["band", "mid", "n_women", "rate_women", "n_men", "rate_men", "gap"]]
out = table.copy()
out[["rate_women", "rate_men", "gap"]] = out[["rate_women", "rate_men", "gap"]].round(1)
out.to_csv(ROOT / "tables" / "band_table_python.csv", index=False)
print(out.to_string(index=False))

# --- numbers for the Google Form ---
def rate(band, col):
    return f"{table.loc[table.band == band, col].iloc[0]:.1f}"
print("Women 15-19 (Python):", rate("15-19", "rate_women"))
print("Women 55-59:", rate("55-59", "rate_women"), " Men 15-19:", rate("15-19", "rate_men"),
      " Men 55-59:", rate("55-59", "rate_men"))
gap_row = table.loc[table.gap.idxmax()]
print("Largest gap:", gap_row.band, f"{gap_row.gap:.1f}", "points")

# --- compare with the R table (written by 03_literacy.R) to one decimal place ---
r_path = ROOT / "tables" / "band_table_R.csv"
if r_path.exists():
    r = pd.read_csv(r_path)
    diff = max((r[c] - out[c]).abs().max() for c in ["rate_women", "rate_men"])
    same_n = (r.n_women == out.n_women).all() and (r.n_men == out.n_men).all()
    print(f"R vs Python: max abs difference in rates = {diff:.4f}; same n: {same_n}")
else:
    print("tables/band_table_R.csv not found: run scripts/03_literacy.R first to compare.")

# --- the figure, matched to the R version ---
colours = {"Women": "#b5532a", "Men": "#1f4e79"}
fig, ax = plt.subplots(figsize=(9, 5.8))
for name, col in [("Women", "women"), ("Men", "men")]:
    x, y = table["mid"], table[f"rate_{col}"]
    thin = table[f"n_{col}"] < 30                      # thin cell: fewer than 30 observations
    ax.plot(x, y, color=colours[name], lw=2, zorder=2)
    ax.scatter(x[~thin], y[~thin], s=55, color=colours[name], zorder=3)
    ax.scatter(x[thin], y[thin], s=55, facecolor="white", edgecolor=colours[name], lw=1.6, zorder=3)
    ax.text(x.iloc[-1] + 1, y.iloc[-1], name, color=colours[name], fontweight="bold",
            fontsize=12, va="center")                  # direct label at the end of the series

# largest-gap annotation
ax.annotate("", xy=(gap_row.mid, gap_row.rate_men), xytext=(gap_row.mid, gap_row.rate_women),
            arrowprops=dict(arrowstyle="<->", color="0.3"))
ax.text(gap_row.mid + 1, (gap_row.rate_men + gap_row.rate_women) / 2,
        f"Largest gap, ages {gap_row.band}:\n{gap_row.gap:.1f} points", fontsize=10.5, va="center", color="0.15")

# ggplot2 pads a scale's limits by 5% on each side; matplotlib's set_ylim does not.
# Set the padded limits by hand so that the two figures match.
ax.set_ylim(-5, 105)
ax.set_xlim(10, 70)
ax.set_xticks(range(12, 63, 5))
ax.set_xticklabels([f"{s}-{s + 4}" for s in range(10, 61, 5)])
ax.set_yticks(range(0, 101, 20))
ax.set_yticklabels([f"{v}%" for v in range(0, 101, 20)])
ax.set_xlabel("Age band (years)")
ax.set_ylabel("Literate (weighted %)")
ax.grid(axis="y", color="0.88", lw=0.8)
ax.grid(axis="x", color="0.88", lw=0.8)
ax.set_axisbelow(True)
for s in ["top", "right", "left", "bottom"]:
    ax.spines[s].set_visible(False)
ax.tick_params(length=0)
fig.suptitle("In rural Sindh, men are at least 22 percentage points more literate\nthan women in every age band",
             x=0.01, ha="left", fontweight="bold", fontsize=13)
thin_any = ((table.n_women < 30) | (table.n_men < 30)).any()
fig.text(0.01, 0.01,
         "Source: PSLM 2019-20, person file merged with household file. Sample: persons aged 10-64 in rural Sindh "
         f"with non-missing literacy (n = {len(lit):,}).\nWeighted by hhweight; each marker is a five-year band plotted at its midpoint.\n"
         "Hollow markers: cells with fewer than 30 observations"
         + ("." if thin_any else " (none in this sample)."),
         fontsize=8.5, color="0.3", ha="left", va="bottom")
fig.subplots_adjust(left=0.08, right=0.97, top=0.85, bottom=0.22)
fig.savefig(ROOT / "figures" / "literacy_by_age_python.svg")