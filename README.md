# Replication codes for "Does access to Starlink improve criminal capability in the Amazon?" (2026)
### by Borges, Komatsu, Maturano, Nishida, and Menezes Filho

---

### How to download required datasets

> **Important:** Download all files below and place them in the repository `datasets/` folder. Keep original filenames whenever possible, as the script expects specific names.


#### 1. Amazon Municipalities (Legal Amazon shapefile)

- **Source:** Terrabrasilis / INPE
- **Download:** [https://terrabrasilis.dpi.inpe.br/download/dataset/legal-amz-aux/vector/municipalities_legal_amazon.zip](https://terrabrasilis.dpi.inpe.br/download/dataset/legal-amz-aux/vector/municipalities_legal_amazon.zip)
- **How to download:** Open the link → download `municipalities_legal_amazon.zip`.



#### 2. Municipal Population (IBGE – SIDRA Table 4714)

- **Source:** IBGE SIDRA
- **Download:** [https://sidra.ibge.gov.br/tabela/4714](https://sidra.ibge.gov.br/tabela/4714)
- **How to download:**
Open link → select year **2022** → click **Download** → choose **CSV (US)** → check **“Exibir códigos de territórios”** → save as `tabela4714.csv`.



#### 3. South America Coastline (Linha de Costa – ANA)

- **Source:** SNIRH / ANA
- **Metadata page:** [https://metadados.snirh.gov.br/geonetwork/srv/por/catalog.search#/metadata/0f57c8a0-6a0f-4283-8ce3-114ba904b9fe](https://metadados.snirh.gov.br/geonetwork/srv/por/catalog.search#/metadata/0f57c8a0-6a0f-4283-8ce3-114ba904b9fe)
- **How to download:** Open metadata page → find download link for **geoft_bho_2017_linha_costa.gpkg** → download GeoPackage file.



#### 4. Brasília shapefile (KML)

- **Source:** IBGE
- **Access page:** [https://www.ibge.gov.br/geociencias/organizacao-do-territorio/estrutura-territorial/27385-localidades.html](https://www.ibge.gov.br/geociencias/organizacao-do-territorio/estrutura-territorial/27385-localidades.html)
- **How to download:** Open page → navigate to **Municípios (KML downloads)** → download Brasília / Distrito Federal KML file.


#### 5. Mobile Coverage (Cobertura Móvel)

- **Source:** dados.gov.br
- **Download:** [https://dados.gov.br/dados/conjuntos-dados/cobertura_movel](https://dados.gov.br/dados/conjuntos-dados/cobertura_movel)
- **How to download:** Open page → download ZIP containing coverage files (must include `Atributos_Setores_Censo_2010.csv` and `Cobertura_2021_11_Setores.csv`).



#### 6. DETER Forest Degradation Alerts (Amazon)

- **Source:** INPE / Terrabrasilis
- **Download:** [https://terrabrasilis.dpi.inpe.br/downloads/](https://terrabrasilis.dpi.inpe.br/downloads/)
- **How to download:** Open page → select **DETER-AMZ public shapefile** → download latest ZIP (e.g., `deter-amz-public-YYYYmmdd.zip`).



#### 7. IBAMA Enforcement (Autos de Infração)

- **Source:** dados.gov.br
- **Dataset page:** [https://dados.gov.br/dados/conjuntos-dados/fiscalizacao-auto-de-infracao](https://dados.gov.br/dados/conjuntos-dados/fiscalizacao-auto-de-infracao)
- **How to download:** Open page → download yearly CSV files (2016–2024) → optionally compress into one ZIP (`auto_infracao_csv.zip`).



#### 8. ICMBio Enforcement (Autos de Infração Shapefiles)

- **Source:** [https://www.gov.br/icmbio/pt-br/assuntos/dados_geoespaciais/mapa-tematico-e-dados-geoestatisticos-das-unidades-de-conservacao-federais](https://www.gov.br/icmbio/pt-br/assuntos/dados_geoespaciais/mapa-tematico-e-dados-geoestatisticos-das-unidades-de-conservacao-federais)
- **How to download:** Open page → locate **Autos de Infração shapefile package** → download ZIP.



#### 9. Fixed Broadband Access (STARLINK & GEO – Anatel)

- **Source:** [https://dados.gov.br/dados/conjuntos-dados/acessos---banda-larga-fixa](https://dados.gov.br/dados/conjuntos-dados/acessos---banda-larga-fixa)
- **How to download:** Open page → download yearly files `Acessos_Banda_Larga_Fixa_YYYY.csv` (2015–2024) → optionally compress into `acessos_banda_larga_fixa.zip`.



#### 10. MapBiomas Land Cover (Annual Coverage TIFFs)

- **Source (2024 example):** [https://storage.googleapis.com/mapbiomas-public/initiatives/brasil/collection_10/lulc/coverage/brazil_coverage_2024.tif](https://storage.googleapis.com/mapbiomas-public/initiatives/brasil/collection_10/lulc/coverage/brazil_coverage_2024.tif)
- **How to download:** Download `brazil_coverage_YYYY.tif` for years 2016–2024.



#### 11. CAMS Particulate Matter (PM1, PM2.5, PM10)

- **Source:** [https://cds.climate.copernicus.eu/](https://cds.climate.copernicus.eu/) [https://atmosphere.copernicus.eu/](https://atmosphere.copernicus.eu/)
- **How to download:** Create free CDS account → search for particulate matter reanalysis → request NetCDF files for 2016–2024 (Brazil region) → download `.nc` files.


#### 12. CHIRTS-ERA5 Maximum Temperature (Tmax)

- **Source:** Climate Hazards Center (UCSB)
👉 [https://www.chc.ucsb.edu/data/chirts-era5](https://www.chc.ucsb.edu/data/chirts-era5)
- **How to download:**
Open page → navigate to monthly Tmax GeoTIFF files → download `.tif` files for 2016–2024.


#### 13. CHIRPS Precipitation (Monthly TIFFs)

**Source:** Climate Hazards Center [https://data.chc.ucsb.edu/products/CHIRPS/v3.0/](https://data.chc.ucsb.edu/products/CHIRPS/v3.0/)
**How to download:** Navigate to `/monthly/latam/tifs/` → download monthly precipitation `.tif` files for 2016–2024.



#### 14. SIM Mortality Data (DATASUS)

- **Source:** Ministério da Saúde 👉 [https://dadosabertos.saude.gov.br/dataset/sim](https://dadosabertos.saude.gov.br/dataset/sim)
- **How to download:** Open page → download “Mortalidade Geral YYYY” CSV files for 2017–2024 → optionally compress into `deaths.zip`.


#### 15. FAO-GAEZ Soy Potential Raster (GAEZ v5)

- **Source:** FAO GAEZ [https://gaez.fao.org/](https://gaez.fao.org/)
- **How to download:** Open portal → go to **Data / Downloads** → locate **Soy attainable yield (high-tech)** raster (RES05…SOY.HRLM) → download GeoTIFF.



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

