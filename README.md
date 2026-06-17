# Lichess Game Analysis

This project analyzes online chess games from a 200k-game Lichess dataset. The goal is to understand how time controls, rating differences, game termination types, and other game-level features relate to chess outcomes.

This project is currently in progress. The first notebook focuses on dataset feasibility, cleaning, and early inspection before moving into SQL-based analysis.

## Project Motivation

I chose this dataset because it contains both simple game-level metadata and deeper chess-specific information such as move history, clock values, and engine evaluations. This makes it a good project for practicing data cleaning, SQL analysis, feature engineering, and careful interpretation.

Since I'm not highly experienced in chess, I'm being careful not to overinterpret chess-specific variables too early. For now, I'm focusing on patterns that are understandable from the data itself, such as time control, game result, termination type, and rating difference.

This is a smaller and more focused project compared to my Brazilian e-commerce analysis project. I wanted this to be a fun mini project, but still useful for improving an important skill: analytical judgment.

Instead of only finding surface-level “what” results, such as which category is most common or which side wins more often, I want to practice going deeper into the “how” and “why” behind the patterns. For example, if faster games end differently from slower games, I want to understand whether that is connected to time pressure, rating gaps, termination type, or other game-level factors.

The goal is not just to produce charts and visualizations, but to build stronger reasoning around the insights.

## Dataset

The dataset used in this project is the Kaggle dataset **200k Lichess Data** by mexwell.

Dataset link: https://www.kaggle.com/datasets/mexwell/200k-lichess-data

The dataset contains 200,000 rated Lichess games from May 2019 across Bullet, Blitz, Rapid, and Classical categories. It includes game metadata, move history, clock information, and engine evaluations after moves.

The raw dataset is not included in this repository because it is too large for normal GitHub tracking. To reproduce the project, download the dataset from Kaggle and place the raw CSV file inside:

```text
data/raw/
```

## Current Project Structure

```text
lichess-game-analysis/
├── data/
│   ├── raw/              # Raw Kaggle dataset, not tracked by Git
│   └── processed/        # Processed files, not tracked by Git
├── notebooks/
│   └── 00_dataset_feasibility.ipynb
├── reports/
│   └── figures/
├── README.md
├── requirements.txt
├── .gitignore
└── LICENSE
```

## Notebook Progress

### 00_dataset_feasibility.ipynb

This notebook checks whether the dataset is suitable for analysis.

Main steps completed:

* Loaded a selected subset of columns from the large raw CSV
* Checked row structure and confirmed that each row represents one chess game
* Dropped raw index artifact columns
* Checked missing values in key metadata columns
* Checked duplicate records
* Inspected numeric rating ranges and rating-difference outliers
* Created an initial `winner` feature from the game result
* Explored early crosstab-based insights about time controls and game endings

## Early Findings

The first useful insight is that faster time controls appear to change how games end. In the 20,000-game sample, Bullet games had a much higher time-forfeit rate than Blitz, Rapid, or Classical games.

At the same time, time-forfeit wins appeared to be fairly balanced between White and Black. This suggests that faster formats may increase the importance of the clock without strongly favoring one color.

These findings are still preliminary and will be tested more carefully in later analysis.

## Next Steps

Planned next steps:

* Create a cleaned game-level dataset
* Export the cleaned sample into SQLite
* Build a second notebook focused on SQL analysis
* Analyze rating advantage, upset rates, time-forfeit rates, and opening patterns
* Optionally engineer features from clock and engine-evaluation columns

## Tools Used

* Python
* Pandas
* Jupyter Notebook
* SQLite
* Git/GitHub

## License

This project is licensed under the MIT License.

The dataset itself is not owned by me and is subject to its original Kaggle dataset license.
