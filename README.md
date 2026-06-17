# Lichess Game Analysis

This project analyzes online chess games from a 200,000-game Lichess dataset. The goal is to understand how time controls, rating differences, game termination types, and other game-level features relate to chess outcomes.

The project is currently in progress. The first notebook focuses on dataset feasibility, cleaning, and game-level feature preparation. The second notebook uses SQL to analyze metadata-level patterns around time controls, termination types, rating favorites, and rating gaps. The next notebook will explore engine-evaluation features in more detail.


## Project Motivation

I chose this dataset because it contains both simple game-level metadata and deeper chess-specific information such as move history, clock values, and engine evaluations. This makes it a good project for practicing data cleaning, SQL analysis, feature engineering, and careful interpretation.

Since I'm not highly experienced in chess, I'm being careful not to overinterpret chess-specific variables too early. For now, I'm focusing on patterns that are understandable from the data itself, such as game category, result, termination type, rating difference, and rating favorite.

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

Processed files are also excluded from GitHub because they are generated locally from the raw dataset.

## Current Project Structure

```text
lichess-game-analysis/
├── data/
│   ├── raw/                         # Raw Kaggle dataset, not tracked by Git
│   └── processed/                   # Processed files and SQLite database, not tracked by Git
├── notebooks/
│   ├── 00_dataset_feasibility.ipynb
│   ├── 01_sql_game_analysis.ipynb
│   ├── 02_eval_analysis.ipynb       # Planned engine-evaluation analysis
│   └── 03_visualizations_insights.ipynb
├── reports/
│   └── figures/
├── README.md
├── requirements.txt
├── .gitignore
└── LICENSE
```

## Notebook Progress

### 00_dataset_feasibility.ipynb

This notebook checks whether the dataset is suitable for analysis and prepares a clean game-level dataset for later SQL work.

Main steps completed:

* Loaded selected metadata columns from the full 200,000-row raw dataset
* Checked row structure and confirmed that each row represents one chess game
* Inspected raw index artifact columns and created a clean `game_id`
* Checked consistency between `Date` and `UTCDate`
* Converted the game date into a proper datetime column
* Checked missing values in key metadata columns
* Identified a small number of missing rating-difference values
* Checked duplicate records
* Inspected rating ranges and rating-difference outliers
* Created a readable `winner` feature from the raw game result
* Created rating-difference features such as `rating_diff_white_minus_black`, `abs_rating_diff`, and `rating_favorite`
* Identified 5 abandoned games with `Result = '*'`
* Explored early crosstab-based patterns between category, termination type, and winner
* Exported a clean game-level dataset for SQL analysis

The abandoned games are kept in the processed dataset for completeness, but they should be excluded or handled separately in any analysis that depends on knowing the winner.

### 01_sql_game_analysis.ipynb

This notebook analyzes the clean game-level dataset with SQLite.

Main questions covered:

* How do game endings differ across Bullet, Blitz, Rapid, and Classical?
* Are time forfeits more common in faster categories?
* Are time-forfeit wins balanced between White and Black?
* How often does the rating favorite win?
* Does rating-favorite performance differ across game categories?
* Does the size of the rating gap affect how reliable the favorite is?
* Does time-forfeit pressure make rating advantage less reliable?
* Which metadata signal appears strongest for favorite reliability: rating gap, category, or termination type?

Main metadata-level finding:

Game category strongly affects **how games end**, especially through time forfeits. However, rating-gap size is the clearest metadata driver of whether the favorite wins. Time-forfeit endings do not appear to meaningfully weaken rating advantage once rating gap is considered.


### 02_eval_analysis.ipynb

This notebook is planned for later analysis of the engine-evaluation columns.

The raw dataset contains many evaluation columns such as `Eval_ply_1`, `Eval_ply_2`, and so on. These columns are more chess-specific and require more careful interpretation, so they are intentionally deferred until after the game-level SQL analysis is complete.

Possible future questions include:

* How does engine evaluation change across the opening and middle game?
* Can large evaluation swings be used to identify blunders or turning points?
* Do evaluation swings differ across rating groups or time-control categories?
* Are faster games associated with more unstable evaluation patterns?

This part of the project will be treated as a separate extension, not mixed into the initial game-level feasibility and SQL notebooks.

### 03_visualizations_insights.ipynb

This notebook is planned for turning the main SQL and analysis outputs into clear visualizations and written insights.

The goal of this notebook is not to create many charts for decoration. Instead, it will focus on communicating the strongest findings from the project clearly and honestly.

Planned work includes:

* Visualizing time-forfeit rates across game categories
* Visualizing winner distributions by category and termination type
* Visualizing rating-favorite performance
* Visualizing upset patterns across game categories
* Writing concise insight summaries under each major chart
* Separating strong findings from limitations and assumptions

This notebook will act as the final storytelling layer of the project.

## Early Findings

The first useful insight is that faster time controls appear to change how games end. In the full game-level metadata dataset, Bullet games have a much higher time-forfeit rate than Blitz, Rapid, or Classical games.

At the same time, time-forfeit wins appear to be fairly balanced between White and Black. This suggests that faster formats may increase the importance of the clock without strongly favoring one color.

These findings are still preliminary and will be tested more carefully in the SQL analysis notebook before being turned into final visualizations and written insights.

## Next Steps

Planned next steps:

* Start the engine-evaluation analysis notebook
* Load and inspect selected evaluation columns from the raw dataset
* Study evaluation swings across different stages of the game
* Explore whether large evaluation swings can identify possible blunders or turning points
* Compare evaluation patterns across rating gaps and game categories
* Later, create a final visualization and insights notebook


## Tools Used

* Python
* Pandas
* Jupyter Notebook
* SQLite
* Git/GitHub

## License

This project is licensed under the MIT License.

The dataset itself is not owned by me and is subject to its original Kaggle dataset license.

Thank you for taking your time to check out this mini project. :)
