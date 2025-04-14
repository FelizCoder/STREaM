# %%
import os

import pandas as pd

folder_path = os.path.join(os.path.dirname(__file__), 'output')

# Get all CSV files in the directory
csv_files = [f for f in os.listdir(folder_path) if f.endswith('statistics.csv') and f != 'all_statistics.csv']

# Create list to store DataFrames
dfs = []

# Read each CSV file
for file in csv_files:
    house_id = file.split('_')[1]
    df = pd.read_csv(os.path.join(folder_path, file))
    df['HouseId'] = house_id
    dfs.append(df)

# Concatenate all DataFrames
all_houses = pd.concat(dfs, ignore_index=True)

# Save combined DataFrame
all_houses.to_csv(os.path.join(folder_path, 'all_statistics.csv'), index=False)