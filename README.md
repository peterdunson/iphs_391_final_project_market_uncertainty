# Disagreement Among AI Models as a Metric of Economic Uncertainty

Testing whether **disagreement among frontier LLMs** can serve as a complementary signal of U.S. economic uncertainty, alongside standard benchmarks (VIX, EPU, Citi Economic Surprise).

## Overview
This project constructs an AI-based uncertainty metric from **model disagreement** in daily market sentiment scoring across **five macro dimensions**:
- Equity Markets
- Inflation Trajectory
- Labor Strength
- Consumer Confidence
- Forward Guidance

We quantify:
- **Across-model disagreement** (do models fundamentally differ from each other?)
- **Within-model disagreement** (how sensitive is each model to prompting/operator differences?)

Disagreement is measured using **cosine distance** between 5D sentiment vectors.

## Data
All data lives in `data/`.

### `data/llm_response.csv`
Daily sentiment scores output by each model.

**Data:**
- Date_dec
- Model (e.g., `claude_opus_4_5`, `gpt_5_1`, `gemini_3_pro`)
- Prompter
- Equities
- Inflation
- Labor
- Consumer
- Guidance

### `data/comparison_metrics.csv`
Benchmark uncertainty indices (raw, unscaled values recommended).

**Expected columns (recommended):**
- date
- `VIX`
- `EPU`
- `Citi_Surprise`

## Prompt
The prompt used for daily collection is stored in:

- `prompts/market_sentiment_prompt.md`

Recommended structure:
1. Role/context (macro strategist)
2. Instruction to use last ~24h of market + macro + Fed info
3. Scoring instructions: **-5 to +5** across the 5 dimensions
4. (Optional) A follow-up prompt requesting brief reasoning/sources

## Methods

### 1) Build 5D sentiment vectors
For each response:
\[
x = (equities, inflation, labor, consumer, guidance)
\]

### 2) Cosine distance (disagreement)
Cosine distance captures the **angular difference** between vectors:
- 0 = perfect agreement
- 2 = perfect disagreement

### 3) Across-model disagreement
For each date:
1. Average responses across raters *within each model* to get one vector per model.
2. Compute cosine distance between model vectors.
3. Aggregate pairwise distances (e.g., mean of the 3 pairwise distances) into a single across-model disagreement score.

### 4) Within-model disagreement (prompt sensitivity)
For each (date, model):
1. Compute cosine distances across the raters’ vectors (R1/R2/R3).
2. Aggregate pairwise distances into a single within-model disagreement score.

### 5) Benchmark comparison
We compare disagreement metrics against:
- **VIX** (market-implied volatility)
- **EPU** (policy/news uncertainty)
- **Citi Economic Surprise Index** (macro data surprises)

We compute correlations using **raw, unscaled values**.

## Results Snapshot (from this study)
- Across-model disagreement dropped sharply after the first sampled day, suggesting convergence in the models’ overall narrative.
- Across-model disagreement aligned more with policy/news uncertainty (EPU) than with market-implied volatility (VIX).
- Within-model disagreement differed by model and date, consistent with a model-stability / prompt-sensitivity interpretation.

## Limitations
- Small sample size (only a few December dates with three responses/day) makes correlations fragile.
- Discrete integer scoring (-5 to +5) can create outsized swings in cosine-distance disagreement when the dataset is small.
- Some “disagreement” may reflect differences in cited information inputs/sourcing rather than true economic ambiguity.

## Citation
If you build on this repo, cite:  
*Disagreement Among AI Models as a Metric of Economic Uncertainty* (IPHS 391, Kenyon College, Fall 2025)

