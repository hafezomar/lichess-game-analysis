# Lichess Game Analysis

This project analyzes online chess games from a 200,000-game Lichess dataset. The goal is to understand how time controls, rating differences, game termination types, and selected engine-evaluation features relate to chess outcomes.

The project is currently in progress. The first notebook focuses on dataset feasibility, cleaning, and game-level feature preparation. The second notebook uses SQL to analyze metadata-level patterns around time controls, termination types, rating favorites, and rating gaps. The third notebook explores engine-evaluation columns through feature engineering, SQL summaries, and careful limitations. The next notebook will focus on final visualizations and written insights.

## Project Motivation

I chose this dataset because it contains both simple game-level metadata and deeper chess-specific information such as move history, clock values, and engine evaluations. This makes it a good project for practicing data cleaning, SQL analysis, feature engineering, and careful interpretation.

Since I'm not highly experienced in chess, I'm being careful not to overinterpret chess-specific variables too early. For now, I'm focusing on patterns that are understandable from the data itself, such as game category, result, termination type, rating difference, rating favorite, and carefully engineered evaluation features.

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
│   └── processed/                   # Processed files and SQLite databases, not tracked by Git
├── notebooks/
│   ├── 00_dataset_feasibility.ipynb
│   ├── 01_sql_game_analysis.ipynb
│   ├── 02_engine_evaluation_analysis.ipynb
│   └── 03_visualizations_insights.ipynb   # Planned visualization/storytelling notebook
├── reports/
│   └── figures/
├── sql/
│   └── game_analysis.sql
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
* Do game categories have different rating-gap compositions?
* Does time-forfeit pressure make rating advantage less reliable?
* Which metadata signal appears strongest for favorite reliability: rating gap, category, or termination type?

Main metadata-level finding:

Game category strongly affects **how games end**, especially through time forfeits. However, rating-gap size is the clearest metadata driver of whether the favorite wins. Time-forfeit endings do not appear to meaningfully weaken rating advantage once rating gap is considered.

### 02_engine_evaluation_analysis.ipynb

This notebook explores the engine-evaluation columns from the raw dataset.

The raw dataset contains many evaluation columns such as `Eval_ply_1`, `Eval_ply_2`, and so on. These columns require careful handling because the values include both ordinary numeric evaluations and forced-mate notation such as `#1` and `#-2`.

Main steps completed:

* Loaded clean game-level metadata from Notebook 00
* Loaded available raw evaluation and clock columns from the original CSV
* Preserved all 200,000 cleaned games by left-joining raw evaluation columns onto the metadata table
* Read evaluation and clock columns as strings first to avoid unsafe dtype assumptions
* Identified forced-mate notation and measured its share among non-missing evaluation entries
* Converted ordinary numeric evaluations separately from mate notation
* Engineered game-level features such as maximum evaluation swing, evaluation volatility, final available numeric evaluation, and mate-related indicators
* Exported engineered features for SQL and visualization work
* Loaded engineered features into SQLite
* Compared evaluation-volatility patterns across favorite outcomes, rating-gap buckets, game categories, and extreme swing groups
* Ran a sanity check on evaluation-sign interpretation before making directional claims

Main evaluation-level finding:

Broad engine-evaluation volatility features did **not** meaningfully separate favorite wins from upsets, rating-gap buckets, or game categories. Even extreme swing rates were surprisingly similar across the main groups. This was frustrating, but useful: it showed that technically interesting features are not automatically analytically useful.

A major limitation is that the sign of the raw evaluation values did not clearly align with the game winner in a simple White/Black perspective check. Because of that, this notebook avoids directional claims such as “the winner was ahead” or “the loser was behind” based only on the sign of the evaluation. The analysis focuses on sign-independent features such as swing magnitude, volatility, absolute evaluation magnitude, and mate-notation indicators.

The main lesson from this notebook is that feature engineering is hypothesis testing, not decoration. If a feature does not explain the outcome clearly, that is still an important result.

### 03_visualizations_insights.ipynb

This notebook is planned for turning the strongest supported outputs into clear visualizations and written insights.

The goal of this notebook is not to create many charts for decoration. Instead, it will focus on communicating the strongest findings from the project clearly and honestly.

Planned work includes:

* Visualizing time-forfeit rates across game categories
* Visualizing rating-favorite performance across rating-gap buckets
* Visualizing rating-gap composition by game category
* Visualizing the strongest metadata-level findings from Notebook 01
* Including selected evaluation-feature visuals only where they add real value
* Writing concise insight summaries under each major chart
* Separating strong findings from limitations and assumptions

This notebook will act as the final storytelling layer of the project.

## Findings So Far

The strongest finding so far is that faster time controls change how games end. Bullet games have a much higher time-forfeit rate than Blitz, Rapid, or Classical games.

At the same time, time-forfeit wins appear to be fairly balanced between White and Black. This suggests that faster formats increase the importance of the clock without strongly favoring one color.

The second major finding is that rating-gap size is the strongest metadata signal for favorite reliability. Small favorites are only modestly more likely to win, while large rating favorites are much more reliable.

The engine-evaluation notebook added an important limitation: broad volatility features were carefully engineered, but they did not clearly explain favorite wins, upsets, or category differences. This made the metadata-level findings from Notebook 01 stand out as stronger and easier to interpret.

## Next Steps

Planned next steps:

* Create the final visualization and insights notebook
* Focus visualizations on the strongest supported findings from Notebook 01
* Add only the evaluation-feature visuals that communicate a real point
* Write concise explanations under each chart
* Clearly separate findings, limitations, and assumptions
* Polish the README after the visualization notebook is complete

## Tools Used

* Python
* Pandas
* NumPy
* Jupyter Notebook
* SQLite
* Git/GitHub

## License

This project is licensed under the MIT License.

The dataset itself is not owned by me and is subject to its original Kaggle dataset license.

Thank you for taking your time to check out this mini project. :)
