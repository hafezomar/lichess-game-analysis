# Lichess Game Analysis

This project analyzes online chess games from a 200,000-game Lichess dataset. The goal is to understand how time controls, rating differences, game termination types, and selected engine-evaluation features relate to chess outcomes.

The project is built as a focused data analysis workflow: dataset feasibility, SQL-based metadata analysis, engine-evaluation feature engineering, and final visual storytelling. The strongest findings came from the metadata analysis, while the engine-evaluation work added useful feature engineering practice and important interpretation limits.

## Project Motivation

I chose this dataset because it contains both simple game-level metadata and deeper chess-specific information such as move history, clock values, and engine evaluations. This made it a good project for practicing data cleaning, SQL analysis, feature engineering, visualization, and careful interpretation.

Since I am not highly experienced in chess, I was careful not to overinterpret chess-specific variables too early. I focused mainly on patterns that could be supported directly from the data: game category, result, termination type, rating difference, rating favorite, and sign-independent engine-evaluation features.

This is a smaller and more focused project compared to my Brazilian e-commerce analysis project. I wanted this to be a fun mini project, but still useful for improving an important skill: analytical judgment.

Instead of only finding surface-level “what” results, such as which category is most common or which side wins more often, I wanted to practice going deeper into the “how” and “why” behind the patterns. For example, if faster games end differently from slower games, I wanted to understand whether that was connected to time pressure, rating gaps, termination type, or other game-level factors.

The goal was not just to produce charts, but to build stronger reasoning around the insights.

## Dataset

The dataset used in this project is the Kaggle dataset **200k Lichess Data** by mexwell.

Dataset link: https://www.kaggle.com/datasets/mexwell/200k-lichess-data

The dataset contains 200,000 rated Lichess games from May 2019 across Bullet, Blitz, Rapid, and Classical categories. It includes game metadata, move history, clock information, and engine evaluations after moves.

The raw dataset is not included in this repository because it is too large for normal GitHub tracking. To reproduce the project, download the dataset from Kaggle and place the raw CSV file inside:

```text
data/raw/
```

Processed files are also excluded from GitHub because they are generated locally from the raw dataset.

## Project Structure

```text
lichess-game-analysis/
├── data/
│   ├── raw/                         # Raw Kaggle dataset, not tracked by Git
│   └── processed/                   # Processed files and SQLite databases, not tracked by Git
├── notebooks/
│   ├── 00_dataset_feasibility.ipynb
│   ├── 01_sql_game_analysis.ipynb
│   ├── 02_engine_evaluation_analysis.ipynb
│   └── 03_visualizations_and_insights.ipynb
├── reports/
│   └── figures/                     # Exported visualizations
├── sql/
│   ├── game_analysis.sql
│   └── engine_eval_analysis.sql
├── README.md
├── requirements.txt
├── .gitignore
└── LICENSE
```

## Notebook Summary

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

The abandoned games are kept in the processed dataset for completeness, but they are excluded or handled separately in analysis that depends on knowing the winner.

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

Game category strongly affects **how games end**, especially through time forfeits. Bullet games had the clearest time-pressure pattern, with nearly half ending by time forfeit. However, rating-gap size was the clearest metadata signal for whether the favorite won. Time-forfeit endings did not appear to meaningfully weaken rating advantage once rating gap was considered.

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

This notebook turns the strongest supported outputs into a focused set of visualizations and written insights.

The goal of this notebook is not to create many charts for decoration. Instead, it focuses on six visuals that either support a strong finding or explain an important limitation:

* Time-forfeit rate by game category
* Favorite win rate by rating-gap bucket
* Favorite win rate by rating-gap bucket and category
* Average maximum evaluation swing by game category
* Final evaluation sign split by termination type
* Evaluation missingness by ply

Main visualization-level finding:

The final visuals show that metadata produced the strongest project story. Bullet games were much more affected by time pressure, and rating gap was the clearest signal for favorite reliability. The engine-evaluation visuals were still useful, but mainly because they showed limits: broad average eval swings were nearly flat across categories, final eval sign was not safe for winner-direction claims, and later ply evaluation columns became mostly missing.

## Key Findings

### 1. Bullet games are heavily shaped by time pressure

Bullet games had a much higher time-forfeit rate than Blitz, Rapid, or Classical games. Nearly half of Bullet games ended by time forfeit, making time pressure one of the clearest patterns in the dataset.

At the same time, time-forfeit wins were fairly balanced between White and Black. This suggests that faster formats increase the importance of the clock without clearly favoring one color.

### 2. Rating gap is the clearest metadata signal for favorite reliability

Rating favorites became more reliable as the rating gap increased. Small favorites were only modestly more likely to win, while large rating favorites won much more often.

This pattern remained visible across game categories, which made rating gap a stronger and more consistent metadata signal than category alone.

### 3. Broad engine-evaluation volatility features were weaker than expected

The engine-evaluation features were technically useful to engineer, but they did not reveal a dramatic separation between categories, favorite wins, and upsets. Average maximum evaluation swing was nearly identical across Bullet, Blitz, Rapid, and Classical games.

This does not mean engine evaluations are useless. It means broad game-level averages are probably too blunt to capture turning points or tactical swings properly. A deeper analysis would likely need a move-level structure.

### 4. Evaluation-sign interpretation was not safe enough for directional claims

A sanity check showed that the final available evaluation sign was almost evenly split across normal and time-forfeit games. The sign also did not clearly align with the game winner in a simple White/Black perspective check.

Because of that, this project avoids claims like “the winner was ahead” or “the loser was behind” based only on raw evaluation sign. That restraint is part of the analysis, not a weakness.

### 5. Late-ply evaluation analysis is limited by missingness

Evaluation coverage drops sharply as ply number increases. Early evaluation columns are available for almost every game, but later columns become mostly missing because many games end before reaching those ply numbers.

This limits how far late-game evaluation analysis can be pushed without a more careful move-level dataset or sampling strategy.

## Main Lesson

The biggest lesson from this project is that feature engineering is hypothesis testing, not decoration.

Some features produced strong insights, especially the metadata features around time control and rating gap. Other features were harder to engineer but less useful analytically, especially broad engine-evaluation volatility summaries. That still made the project stronger because it separated what the data clearly supported from what required deeper validation.

## Possible Future Work

A deeper version of this project could include:

* Reshaping engine-evaluation columns into a move-level format
* Verifying the engine-evaluation sign convention using documentation or known game examples
* Detecting individual turning points instead of relying on broad average volatility
* Comparing evaluation swings by game phase
* Studying whether time-forfeit losses happen from objectively winning, losing, or equal positions after eval semantics are verified
* Building a small interactive dashboard for the main metadata findings

## Tools Used

* Python
* Pandas
* NumPy
* Matplotlib
* Seaborn
* Jupyter Notebook
* SQLite
* Git/GitHub

## License

This project is licensed under the MIT License.

The dataset itself is not owned by me and is subject to its original Kaggle dataset license.

Thank you for taking your time to check out this mini project. :)
