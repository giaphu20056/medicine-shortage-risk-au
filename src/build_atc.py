"""Build ingredient -> ATC level-1 lookup tables for the dashboard filter.
pbs_ingredient_lookup.pbs_drug_names holds several PBS names joined by ' | '; split, then join each name to
pbs_item_drug_map.DRUG_NAME (all items of that name).
Outputs: data/processed/ingredient_atc.csv (1 row per ingredient, display group = most frequent ATC level-1 letter,
ties alphabetical) and data/processed/ingredient_atc_bridge.csv (1 row per ingredient x letter, for the slicer).
The display group is item-count based and includes non-hospital forms (eye, skin): see README caveat."""
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
NAMES = {
    "A": "Alimentary tract and metabolism", "B": "Blood and blood forming organs",
    "C": "Cardiovascular system", "D": "Dermatologicals",
    "G": "Genito-urinary system and sex hormones", "H": "Systemic hormonal preparations",
    "J": "Anti-infectives for systemic use", "L": "Antineoplastic and immunomodulating agents",
    "M": "Musculo-skeletal system", "N": "Nervous system", "P": "Antiparasitic products",
    "R": "Respiratory system", "S": "Sensory organs", "V": "Various",
    "Z": "Non-ATC items (PBS code Z)", "UNK": "Unclassified",
}

m = pd.read_csv(ROOT / "data/raw/pbs_item_drug_map.csv", encoding="latin-1")
lk = pd.read_csv(ROOT / "data/processed/pbs_ingredient_lookup.csv")
ex = lk.assign(name=lk.pbs_drug_names.str.split(r"\s*\|\s*", regex=True)).explode("name")
mm = ex.merge(m, left_on="name", right_on="DRUG_NAME", how="left")
unmatched = sorted(set(mm.loc[mm.ATC5_Code.isna(), "name"]))
mm["letter"] = mm.ATC5_Code.str[0]

rows, bridge = [], []
for key, g in mm.groupby("ingredient_key"):
    c = g.letter.dropna().value_counts()
    if c.empty:
        rows.append((key, "UNK", NAMES["UNK"], "", 0, "no_atc"))
        bridge.append((key, "UNK", NAMES["UNK"], 0))
        continue
    c = c.sort_index().sort_values(ascending=False, kind="stable")
    for letter, n in c.items():
        bridge.append((key, letter, NAMES[letter], int(n)))
    rows.append((key, c.index[0], NAMES[c.index[0]], "|".join(f"{k}:{v}" for k, v in c.items()),
                 int(c.sum()), "multi" if len(c) > 1 else "single"))

out = pd.DataFrame(rows, columns=["ingredient_key", "atc_group", "atc_group_name",
                                  "atc_letters", "n_items", "atc_status"])
br = pd.DataFrame(bridge, columns=["ingredient_key", "atc_group", "atc_group_name", "n_items"])
out.to_csv(ROOT / "data/processed/ingredient_atc.csv", index=False)
br.to_csv(ROOT / "data/processed/ingredient_atc_bridge.csv", index=False)

r = pd.read_csv(ROOT / "data/processed/out_risk_ranking.csv")
j = r.merge(out, on="ingredient_key", how="left")
print("rows", len(out), "| unique keys", out.ingredient_key.nunique(), "| bridge rows", len(br))
print("all keys by status:", out.atc_status.value_counts().to_dict())
print("ranked 489 by status:", j.atc_status.value_counts().to_dict())
print("unmatched names after split:", len(unmatched), unmatched[:10])
print(out[out.ingredient_key.isin(["METOPROLOL", "HYDROCORTISONE", "DEXAMETHASONE"])].to_string(index=False))
