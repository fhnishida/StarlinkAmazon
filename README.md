# Replication codes for "Does access to Starlink improve criminal capability in the Amazon?" (2026)
### by Borges, Komatsu, Maturano, Nishida, and Menezes Filho


## `starlink_dataframe.R` — build analytical dataset
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
* **Text categorization:** ICMBio/IBAMA descriptions are normalized and matched via regex lists — review `rx` if you adjust categories or languages.
* **Reproducibility:** script writes intermediate RDS files so downstream steps can be rerun without repeating costly raster extractions.

