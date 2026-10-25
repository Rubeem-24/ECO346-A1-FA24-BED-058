from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

PROJECT_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_DIR / "data"
FIGURE_DIR = PROJECT_DIR / "figures"
TABLE_DIR = PROJECT_DIR / "tables"

FIGURE_DIR.mkdir(exist_ok=True)
TABLE_DIR.mkdir(exist_ok=True)

people_data = pd.read_csv(DATA_DIR / "pslm_person_subset.csv")
household_data = pd.read_csv(
    DATA_DIR / "pslm_hh_subset.csv",
    usecols=["hhid", "hhweight", "prov_code", "urban_rural"]
)

merged_data = people_data.merge(
    household_data,
    on="hhid",
    how="left"
)

sample = merged_data.loc[
    (merged_data["prov_code"] == 3)
    & (merged_data["urban_rural"] == 1)
    & merged_data["age"].between(10, 64)
    & merged_data["literate"].notna()
].copy()

sample["band_start"] = (sample["age"] // 5) * 5
sample["mid"] = sample["band_start"] + 2

records = []

for start, group in sample.groupby("band_start"):
    record = {
        "band": f"{start}-{start + 4}",
        "mid": start + 2
    }

    for sex_code, label in [(2, "women"), (1, "men")]:
        group_sex = group.loc[group["sex"] == sex_code]

        record[f"n_{label}"] = len(group_sex)

        if len(group_sex) > 0:
            record[f"rate_{label}"] = (
                100 * np.average(
                    group_sex["literate"],
                    weights=group_sex["hhweight"]
                )
            )
        else:
            record[f"rate_{label}"] = np.nan

    record["gap"] = record["rate_men"] - record["rate_women"]
    records.append(record)

columns = [
    "band", "mid", "n_women", "rate_women",
    "n_men", "rate_men", "gap"
]

results = pd.DataFrame(records, columns=columns)

export_results = results.copy()
rate_columns = ["rate_women", "rate_men", "gap"]

export_results[rate_columns] = export_results[rate_columns].round(1)

export_results.to_csv(
    TABLE_DIR / "band_table_python.csv",
    index=False
)

print(export_results.to_string(index=False))


def display_rate(age_band, column):
    selected = results.loc[results["band"] == age_band, column]
    return f"{selected.iloc[0]:.1f}"


print("Women 15-19 (Python):", display_rate("15-19", "rate_women"))
print(
    "Women 55-59:", display_rate("55-59", "rate_women"),
    "Men 15-19:", display_rate("15-19", "rate_men"),
    "Men 55-59:", display_rate("55-59", "rate_men")
)

largest_difference = results.loc[results["gap"].idxmax()]

print(
    "Largest gap:",
    largest_difference["band"],
    f"{largest_difference['gap']:.1f}",
    "points"
)

r_file = TABLE_DIR / "band_table_R.csv"

if r_file.exists():
    r_results = pd.read_csv(r_file)

    differences = [
        (r_results[column] - export_results[column]).abs().max()
        for column in ["rate_women", "rate_men"]
    ]

    max_difference = max(differences)

    matching_counts = (
        (r_results["n_women"] == export_results["n_women"]).all()
        and (r_results["n_men"] == export_results["n_men"]).all()
    )

    print(
        f"R vs Python: max abs difference in rates = "
        f"{max_difference:.4f}; same n: {matching_counts}"
    )
else:
    print(
        "tables/band_table_R.csv not found: "
        "run scripts/03_literacy.R first to compare."
    )

gender_colors = {
    "Women": "#b5532a",
    "Men": "#1f4e79"
}

fig, ax = plt.subplots(figsize=(9, 5.8))

for gender, suffix in [("Women", "women"), ("Men", "men")]:
    positions = results["mid"]
    rates = results[f"rate_{suffix}"]
    small_sample = results[f"n_{suffix}"] < 30
    color = gender_colors[gender]

    ax.plot(positions, rates, color=color, linewidth=2, zorder=2)

    ax.scatter(
        positions[~small_sample],
        rates[~small_sample],
        s=55,
        color=color,
        zorder=3
    )

    ax.scatter(
        positions[small_sample],
        rates[small_sample],
        s=55,
        facecolors="white",
        edgecolors=color,
        linewidths=1.6,
        zorder=3
    )

    ax.text(
        positions.iloc[-1] + 1,
        rates.iloc[-1],
        gender,
        color=color,
        fontweight="bold",
        fontsize=12,
        va="center"
    )

gap_x = largest_difference["mid"]
women_rate = largest_difference["rate_women"]
men_rate = largest_difference["rate_men"]
gap_center = (women_rate + men_rate) / 2

ax.annotate(
    "",
    xy=(gap_x, men_rate),
    xytext=(gap_x, women_rate),
    arrowprops={"arrowstyle": "<->", "color": "0.3"}
)

ax.text(
    gap_x + 1,
    gap_center,
    f"Largest gap, ages {largest_difference['band']}:\n"
    f"{largest_difference['gap']:.1f} points",
    fontsize=10.5,
    va="center",
    color="0.15"
)

ax.set_ylim(-5, 105)
ax.set_xlim(10, 70)
ax.set_xticks(range(12, 63, 5))
ax.set_xticklabels([
    f"{age}-{age + 4}" for age in range(10, 61, 5)
])
ax.set_yticks(range(0, 101, 20))
ax.set_yticklabels([f"{value}%" for value in range(0, 101, 20)])

ax.set_xlabel("Age band (years)")
ax.set_ylabel("Literate (weighted %)")

ax.grid(axis="both", color="0.88", linewidth=0.8)
ax.set_axisbelow(True)

for spine in ax.spines.values():
    spine.set_visible(False)

ax.tick_params(length=0)

fig.suptitle(
    "In rural Sindh, men are at least 22 percentage points more literate\n"
    "than women in every age band",
    x=0.01,
    ha="left",
    fontweight="bold",
    fontsize=13
)

any_small_group = (
    (results["n_women"] < 30) | (results["n_men"] < 30)
).any()

caption = (
    "Source: PSLM 2019-20, person file merged with household file. "
    "Sample: persons aged 10-64 in rural Sindh "
    f"with non-missing literacy (n = {len(sample):,}).\n"
    "Weighted by hhweight; each marker is a five-year band plotted at its midpoint.\n"
    "Hollow markers: cells with fewer than 30 observations"
    + ("." if any_small_group else " (none in this sample).")
)

fig.text(
    0.01, 0.01, caption,
    fontsize=8.5,
    color="0.3",
    ha="left",
    va="bottom"
)

fig.subplots_adjust(
    left=0.08,
    right=0.97,
    top=0.85,
    bottom=0.22
)

fig.savefig(FIGURE_DIR / "literacy_by_age_python.svg")