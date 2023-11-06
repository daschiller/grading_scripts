#!/usr/bin/env python3

# SPDX-License-Identifier: GPL-3.0-only
# Copyright (c) 2022 David Schiller <david.schiller@jku.at>

import argparse
from csv import QUOTE_NONNUMERIC

import pandas as pd

# change this to match your input file
DELIMITER = ","

parser = argparse.ArgumentParser()
parser.add_argument("input_csv")
parser.add_argument("gradebook_csv")
args = parser.parse_args()

input_df = pd.read_csv(args.input_csv, delimiter=DELIMITER, keep_default_na=False)
gradebook_df = pd.read_csv(args.gradebook_csv)

for _, row in input_df.iterrows():
    index = gradebook_df.index[gradebook_df["Full name"] == row["name"]]
    name = gradebook_df.loc[index, "Full name"].to_string(index=False).strip()
    if not index.empty:
        try:
            if not pd.isna(gradebook_df.loc[index, "Grade"]).bool():
                print(f"Modifying existing grade for {name}")
            gradebook_df.loc[index, "Grade"] = float(row["points"])
        except ValueError:
            gradebook_df.loc[index, "Grade"] = 0.0

        if not pd.isna(gradebook_df.loc[index, "Feedback comments"]).bool():
            print(f"Modifying existing feedback for {name}")
        gradebook_df.loc[index, "Feedback comments"] = row["feedback"].replace(
            "\n", "<br>"
        )
    else:
        print(f"'{row['name']}' couldn't be matched!")

gradebook_df.to_csv("upload.csv", index=False, quoting=QUOTE_NONNUMERIC)
