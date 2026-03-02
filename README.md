# Replication codes for "Does access to Starlink improve criminal capability in the Amazon?" (2026)
## by Borges, Komatsu, Maturano, Nishida, and Menezes Filho

### How to download required datasets:



---

### `starlink_dataframe.R` — build analytical dataset

Builds the municipality-year analytical dataset and all intermediate processed data (DETER, enforcement, Starlink/GEO subscriptions, PM, climate, mortality, MapBiomas transitions, soy potential) and saves `datasets/processed/analysis_dataset.dta`.

**What it does:**

* Loads raw spatial and tabular inputs (IBGE/INPE/ANATEL/MapBiomas/CAMS/CHIRPS/SIM/GAEZ).
* Constructs a 772-municipality panel (2017–2024), computes centroids, distances, and population density.
* Extracts and aggregates: forest-degradation alerts (DETER), environmental enforcement records (IBAMA/ICMBio) with text categorization, Starlink & GEO satellite accesses, particulate matter (CAMS) aggregated to municipal-year, Tmax and precipitation (CHIRPS/CHIRTS), ICD-10 mortality rates, MapBiomas land-cover transitions and forest share, and FAO-GAEZ soy potential.
* Joins all processed pieces into a single analysis dataset and writes a Stata `.dta` file.

**Inputs:**

* `datasets/` folder with raw downloads and shapefiles referenced in the script (further instruction provided in the code).
* Zipped CSV/SHP/NETCDF/TIF original datasets, downloaded from the sources.

**Outputs:**

* Multiple RDS files under `datasets/processed/` (e.g., `munic.RDS`, `deter.RDS`, `police.RDS`, `starlink.RDS`, `geosat.RDS`, `pm_cams.RDS`, `tmax.RDS`, `prcp.RDS`, `deaths.RDS`, `mbtrans.RDS`, `mb_forest.RDS`, `soy_potential.RDS`) and the final `datasets/processed/analysis_dataset.dta`.

**Dependencies:**

* R (4.4.3), packages: `tidyverse`, `sf`, `terra`, `exactextractr`, `tiff`, `readxl`, `stringi`, `haven`, `data.table` (install if missing).

**Notes:**

* **Set working directory** to the repository root (script uses `setwd()`—update or remove to match your local layout).
* **CRS:** uses an Albers SIRGAS2000 projection for area computations; maintained across extractions.
* **Heavy steps:** CAMS PM extraction and MapBiomas transition calculations are computationally intensive — the script warns these can take hours and saves intermediate yearly/state RDS files so work can be resumed.
* **Text categorization:** ICMBio/IBAMA descriptions are normalized and matched via regex lists.
* **Reproducibility:** script writes intermediate RDS files so downstream steps can be rerun without repeating costly raster extractions.


---

### `starlink_results.Rmd` — run analyses and generate figures/tables (R Markdown)

Reproduces all estimation results, figures, and supplementary tables for the paper and renders an HTML report with tables, maps, event-study/placebo checks, heterogeneity plots, and first-stage diagnostics.

**What it does:**

* Loads the pre-built analytical dataset (`datasets/processed/analysis_dataset.dta`) and required processed RDS pieces.
* Constructs model-ready variables (normalizations, year × coverarea instruments, shares, etc.).
* Runs two-stage fixed-effects IV regressions (shift-share instruments) across a suite of outcome variables, clusters SEs by municipality, and stores results for plotting and tables.
* Produces all manuscript figures (maps, coefficient plots with 90/95% CIs, event-study/placebo plots, heterogeneity splits) and supplementary tables (descriptives and first-stage stats).
* Renders a self-contained HTML report.

**Inputs:**

* `datasets/processed/analysis_dataset.dta` (final analytical dataset written by `starlink_dataframe.R`)
* Processed RDS files referenced in the script for maps and panels (e.g., `datasets/processed/starlink.RDS`, `deter` shapefile path inside `/vsizip/...`), plus raw spatial files listed in the header (municipalities shapefile, DETER shapefile, coverage KMLs, etc.).

**Outputs:**

* HTML report created by knitting the R Markdown (includes Figures 1–6, Supplementary Fig/Table outputs).
* Intermediate R objects created during execution (kept in-memory while knitting); the script writes no new processed datasets — it reads the `datasets/processed` outputs created by the data-building script.

**Dependencies:**

* `fixest`, `tidyverse` (dplyr, ggplot2, tibble, etc.), `ggpubr`, `sf`, `haven`, `fastDummies`, `broom`, `ggnewscale`, `terra`/`exactextractr` (for mapping sections). Ensure packages are installed.

**Notes:**

* **Working directory:** The Rmd sets `setwd()` — update or remove this for your environment. Knit from the repository root for the easiest path resolution.
* **Data requirement:** This script expects the analytical dataset and several processed RDS/raw spatial files already present. Run `starlink_dataframe.R` first to produce them (or place matching files in `datasets/processed/`).
* **Maps:** Map panels read shapefiles and KMLs directly (via `/vsizip/...` paths and the `datasets/areas_cobertas.zip`). Confirm that those archives are present; otherwise, the map section will error.

