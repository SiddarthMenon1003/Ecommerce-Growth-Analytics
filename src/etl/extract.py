from pathlib import Path
import pandas as pd


BASE_DIR = Path(__file__).resolve().parents[2]
RAW_DATA_PATH = BASE_DIR / "data" / "raw"


def extract_data():
    datasets = {}

    for file in RAW_DATA_PATH.glob("*.csv"):
        print(f"Loading {file.name}")

        datasets[file.stem] = pd.read_csv(file)

    return datasets


if __name__ == "__main__":
    data = extract_data()

    print("\nDatasets Loaded:")
    for name, df in data.items():
        print(f"{name}: {df.shape}")