# Replication codes for "Does access to Starlink improve criminal capability in the Amazon?" (2026)
### by Borges, Komatsu, Maturano, Nishida, and Menezes Filho

---

### How to download required datasets

**All files go into the repository `datasets/` folder.** The script expects that path.

1. **Amazon municipalities shapefile (Terrabrasilis / IBGE)**
   URL: `https://terrabrasilis.dpi.inpe.br/download/dataset/legal-amz-aux/vector/municipalities_legal_amazon.zip`
   How to download: open the URL → locate **municipalities_legal_amazon.zip** in the file list → click *Download* (or right-click & *Save link as...*). Save the ZIP to your `datasets/` folder.

2. **Municipal population — IBGE (SIDRA, table 4714)**
   URL: `https://sidra.ibge.gov.br/tabela/4714`
   How to download: open the SIDRA page → choose the year/columns you want (set the year to 2022) → click **Download** → select **CSV (US)** and tick **Exibir códigos de territórios** → Save file as `tabela4714.csv` in `datasets/`.

3. **South America coastline (ANA / SNIRH — Linha de Costa)**
   Metadata / catalog: `https://metadados.snirh.gov.br/geonetwork/srv/por/catalog.search#/metadata/0f57c8a0-6a0f-4283-8ce3-114ba904b9fe`
   How to download: open the metadata page → find the dataset **Linha de Costa / geoft_bho_2017_linha_costa** → click the download or data access link (GeoPackage) → download the `.gpkg` and place it in `datasets/`.

4. **Brasília localities KML (IBGE)**
   Info / page: `https://www.ibge.gov.br/geociencias/organizacao-do-territorio/estrutura-territorial/27385-localidades.html`
   How to download: open the IBGE Localidades page → navigate to *Municípios* or *KML downloads* → select Distrito Federal / Brasília → download the KML (or ZIP) and save into `datasets/`.

5. **Mobile coverage (Cobertura móvel — dados.gov.br)**
   URL / dataset page: `https://dados.gov.br/dados/conjuntos-dados/cobertura_movel`
   How to download: open the dataset page → click **Download** or the link to the provided ZIP → download the zip that contains `Atributos_Setores_Censo_2010.csv` and `Cobertura_2021_11_Setores.csv` → save ZIP into `datasets/`.

6. **DETER forest alerts (INPE / Terrabrasilis DETER)**
   Landing: `https://terrabrasilis.dpi.inpe.br/downloads/`
   How to download: open the Terrabrasilis downloads page → look for **DETER (Amazon / DETER-AMZ)** → select the *public* DETER shapefile package (e.g., `deter-amz-public-YYYYmmdd.zip`) → click **Download** → place ZIP in `datasets/`.

7. **IBAMA enforcement — Autos de infração (dados.gov.br)**
   Dataset page: `https://dados.gov.br/dados/conjuntos-dados/fiscalizacao-auto-de-infracao`
   How to download: open the page → download the CSV(s) for each year (or use the API/Download button) → name files `auto_infracao_ano_2016.csv` … `auto_infracao_ano_2024.csv` and compress them into `auto_infracao_csv.zip` if desired → save into `datasets/`.

8. **ICMBio enforcement (Autos de Infração shapefiles)**
   Info / download: `https://www.gov.br/icmbio/pt-br/assuntos/dados_geoespaciais/mapa-tematico-e-dados-geoestatisticos-das-unidades-de-conservacao-federais`
   How to download: open the ICMBio geospatial data page → find the **Autos de Infração** shapefile package → click to download the shapefile ZIP → save it into `datasets/`.

9. **Acessos — Banda Larga Fixa (Anatel / dados.gov.br) — STARLINK & GEO satellite**
   Dataset page: `https://dados.gov.br/dados/conjuntos-dados/acessos---banda-larga-fixa`
   How to download: open page → download yearly CSVs named `Acessos_Banda_Larga_Fixa_YYYY.csv` (2015–2024 ranges) → compress into `acessos_banda_larga_fixa.zip` (script uses those CSV names inside a zip) → save into `datasets/`.

10. **MapBiomas coverage TIFFs (annual land-cover)**
    Example direct link pattern: `https://storage.googleapis.com/mapbiomas-public/initiatives/brasil/collection_10/lulc/coverage/brazil_coverage_2024.tif`
    How to download: open MapBiomas site (`https://mapbiomas.org/`) or use the Google Cloud link above → download `brazil_coverage_YYYY.tif` for 2016–2024 → save files into `datasets/mapbiomas/`.

11. **CAMS particulate matter (PM1 / PM2.5 / PM10) — Copernicus / CAMS**
    Portals: `https://cds.climate.copernicus.eu/` and `https://atmosphere.copernicus.eu/`
    How to download: use the Copernicus Atmosphere Data Store (CDS) or CAMS portal → search for particulate matter / reanalysis over Brazil → request NetCDF product for 2016–2024 (or use the prepared aggregated files if available) → download `PM1_BR_2016_2024.nc`, `PM2.5_BR_2016_2024.nc`, `PM10_BR_2016_2024.nc` (or similarly named files) → save into `datasets/`. (If using the CDS API, follow CDS API instructions to retrieve multi-year NetCDF.)

12. **CHIRTS-ERA5 Tmax (monthly GeoTIFFs)**
    URL: `https://www.chc.ucsb.edu/data/chirts-era5`
    How to download: open CHC page → navigate to CHIRTS-ERA5 Tmax product → select monthly TIFFs for the required years → download the `.tif` files and put them into `datasets/chirts-era5/`.

13. **CHIRPS precipitation monthly TIFFs**
    URL: `https://data.chc.ucsb.edu/products/CHIRPS/v3.0/`
    How to download: open CHIRPS product page → download monthly TIFFs for Latin America / Brazil for 2016–2024 → save files into `datasets/chirps-v3.0/`.

14. **SIM mortality (DATASUS “Mortalidade Geral YYYY” CSVs)**
    URL: `https://dadosabertos.saude.gov.br/dataset/sim`
    How to download: open SIM dataset page → find *Mortalidade Geral* files by year → download CSV for each year 2017–2024 → optionally compress them into `deaths.zip` → save into `datasets/`.

15. **FAO-GAEZ soy potential raster (GAEZ v5)**
    Portal: `https://gaez.fao.org/` (FAO GAEZ)
    How to download: open GAEZ data portal → search for the **Soy attainable yield (high-tech)** raster (RES05…SOY.HRLM) → select the map product and download the GeoTIFF → save into `datasets/` with the filename referenced in the script (or rename appropriately).


### Final notes

* 


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

