# Replication code for "Does access to Starlink improve criminal capability in the Amazon?" (2026)
### by Borges, Komatsu, Maturano, Nishida, and Menezes Filho

---

## Table of Contents

1. [Overview](#1-overview)
2. [Repository Structure](#2-repository-structure)
3. [R Packages](#3-r-packages)
4. [`starlink_dataframe.R`](#4-starlink_dataframer)
5. [`starlink_results.Rmd`](#5-starlink_resultsrmd)
6. [How to Run](#6-how-to-run)
7. [Downloading Datasets](#7-downloading-datasets)

---

## 1. Overview

This repository contains two code files that together reproduce all results of
the paper. The workflow is strictly sequential:

```
starlink_dataframe.R   →   analytical_dataset.dta   →   starlink_results.Rmd
     (data build)               (intermediary)              (results)
```

`starlink_dataframe.R` ingests all raw datasets, processes them, and exports a
single Stata-format panel dataset (`datasets/processed/analytical_dataset.dta`).
`starlink_results.Rmd` reads that dataset and produces all regression tables,
event-study plots, and figures included in the paper and supplementary
materials.

> **Before running either file**, make sure all raw datasets have been
> downloaded and placed in the correct subfolders. See
> [README_data.md](README_data.md) for full instructions.

---

## 2. Repository Structure

```
.
├── starlink_dataframe.R       # Step 1 — builds the analytical dataset
├── starlink_results.Rmd       # Step 2 — produces all results
├── README.md                  # This file
├── README_data.md             # Data sources and download instructions
└── datasets/
    ├── [raw files]            # Downloaded by the user (see README_data.md)
    └── processed/             # Created automatically by starlink_dataframe.R
        └── analytical_dataset.dta
```

---

## 3. R Packages

### 3.1 Installation

Run the block below once to install all required packages:

```r
install.packages(c(
  # Data wrangling
  "tidyverse",
  "data.table",
  "readxl",
  "stringi",
  "haven",
  "fastDummies",
  # Spatial
  "sf",
  "terra",
  "exactextractr",
  "tiff",
  # Econometrics
  "fixest",
  "broom",
  # Visualization
  "ggplot2",   # included in tidyverse, listed explicitly for clarity
  "ggpubr",
  "ggnewscale"
))
```

### 3.2 Package Reference Table

| Package | Version tested | Role | Used in |
|---------|---------------|------|---------|
| `tidyverse` | ≥ 2.0 | Data manipulation and visualization (`dplyr`, `ggplot2`, `tidyr`, `purrr`, `readr`, `stringr`, `forcats`, `lubridate`) | Both files |
| `data.table` | ≥ 1.15 | Fast row-binding of large spatial extractions (`rbindlist`) | `starlink_dataframe.R` |
| `readxl` | ≥ 1.4 | Reading `.xlsx` files | `starlink_dataframe.R` |
| `stringi` | ≥ 1.8 | String normalization (accented characters in Portuguese keywords) | `starlink_dataframe.R` |
| `haven` | ≥ 2.5 | Reading/writing Stata `.dta` files | Both files |
| `fastDummies` | ≥ 1.7 | Creating year dummy columns for the event-study | `starlink_results.Rmd` |
| `sf` | ≥ 1.0 | Reading and processing vector spatial data (shapefiles, KML, GPKG) | Both files |
| `terra` | ≥ 1.7 | Reading and processing raster data (GeoTIFF, NetCDF) | `starlink_dataframe.R` |
| `exactextractr` | ≥ 0.10 | Area-weighted extraction of raster values to polygons | `starlink_dataframe.R` |
| `tiff` | ≥ 0.1 | Low-level TIFF support required by `terra` on some systems | `starlink_dataframe.R` |
| `fixest` | ≥ 0.12 | Two-way fixed-effects IV regression (`feols`) and fit statistics | `starlink_results.Rmd` |
| `broom` | ≥ 1.0 | Tidying regression output into data frames | `starlink_results.Rmd` |
| `ggpubr` | ≥ 0.6 | Combining multiple `ggplot2` panels (`ggarrange`, `annotate_figure`) | `starlink_results.Rmd` |
| `ggnewscale` | ≥ 0.4 | Multiple color/fill scales in the same `ggplot2` figure | `starlink_results.Rmd` |

> All packages are available on CRAN. No GitHub-only or private packages are
> required.

---

## 4. File 1 — `starlink_dataframe.R`

### Purpose

Reads all raw datasets, performs spatial and tabular processing, and joins
everything into a single municipality × year panel saved as
`datasets/processed/analytical_dataset.dta`.

### Structure

The script is organized into numbered sections using the `{ # N. SECTION ####`
convention, making it easy to fold/unfold blocks in RStudio:

| Section | Name | Description |
|---------|------|-------------|
| 0 | Initialization | Loads packages, sets the working directory and the official Brazilian CRS (SIRGAS 2000 / Albers conical equal-area) |
| 1 | Building Municipal Panel | Reads the Legal Amazon municipalities shapefile; appends 2022 Census population, 2021 mobile coverage, distances to the coast and Brasília, and centroids |
| 2 | Forest Degradation | Reads DETER alerts (INPE), intersects with municipalities, computes flagged area and count by degradation type (fire, selective cutting, other) per municipality × month |
| 3 | Environmental Enforcement | Reads IBAMA and ICMBio infraction notices; classifies them by type (deforestation, fire, flora, fauna, pollution, administrative); aggregates to municipality × year |
| 4 | Satellite Broadband | Reads ANATEL fixed-broadband subscription records; isolates Starlink (LEO) and other VSAT/GEO providers; normalizes by population |
| 5 | Air Pollution | Extracts area-weighted monthly PM₁, PM₂.₅ and PM₁₀ concentrations from CAMS EAC4 NetCDF reanalysis files; converts units from kg/m³ to µg/m³ |
| 6 | Climate Controls | Extracts area-weighted monthly maximum temperature (CHIRTS-ERA5) and precipitation (CHIRPS v3.0) from GeoTIFF rasters |
| 7 | Mortality Rates | Reads SIM death records; classifies deaths by ICD-10 chapter; computes rates per 100,000 inhabitants including homicide sub-categories |
| 8 | Forest Cover and Transitions | Reads MapBiomas annual land-cover rasters; computes forest cover share and year-to-year transition matrices (forest → other land uses) by municipality |
| 9 | Potential Soy Yield | Extracts area-weighted attainable soybean yield (FAO-GAEZ v5, high-input scenario) as a heterogeneity instrument |
| 10 | Joining Datasets | Left-joins all processed `.RDS` files on `codmun × year` and writes the final `analytical_dataset.dta` |

### Key design choices

- **CRS:** All spatial operations use SIRGAS 2000 Albers conical equal-area
  (the standard for area computations in Brazil, as defined by IBGE). The
  projection string is defined once at initialization and passed to all
  `st_transform()` calls.
- **ZIP reading:** Raw files are read directly from `.zip` archives using
  `/vsizip/` (GDAL virtual filesystem) and `unz()`, so nothing needs to be
  manually extracted.
- **Resumable PM extraction:** Because processing CAMS NetCDF files can take
  several hours, Section 5 automatically detects the latest completed year/month
  in `datasets/processed/` and resumes from there.
- **Intermediary outputs:** Each section saves its result as an `.RDS` file in
  `datasets/processed/`. This allows individual sections to be re-run
  independently without re-processing the entire pipeline.

### Outputs

| File | Description |
|------|-------------|
| `datasets/processed/munic.RDS` | Municipal panel (geography + covariates) |
| `datasets/processed/deter.RDS` | DETER degradation alerts |
| `datasets/processed/police.RDS` | Environmental enforcement fines |
| `datasets/processed/starlink.RDS` | Starlink subscriptions per 1,000 inhabitants |
| `datasets/processed/geosat.RDS` | Other GEO satellite subscriptions per 1,000 inhabitants |
| `datasets/processed/pm_cams.RDS` | PM₁, PM₂.₅, PM₁₀ concentrations |
| `datasets/processed/tmax.RDS` | Mean annual maximum temperature |
| `datasets/processed/prcp.RDS` | Mean annual precipitation |
| `datasets/processed/deaths.RDS` | Mortality rates by ICD-10 chapter |
| `datasets/processed/mb_forest.RDS` | Forest cover share (MapBiomas) |
| `datasets/processed/mbtrans.RDS` | Forest cover transitions (MapBiomas) |
| `datasets/processed/soy_potential.RDS` | Attainable soybean yield (FAO-GAEZ) |
| `datasets/processed/analytical_dataset.dta` | **Final analytical dataset** |

---

## 5. `starlink_results.Rmd`

### Purpose

Reads `analytical_dataset.dta` and reproduces all regression tables, event-study
plots, heterogeneity analyses, and figures presented in the paper.

### Structure

| Chunk | Name | Description |
|-------|------|-------------|
| `Initialization` | Setup | Loads packages, sets locale to handle Portuguese characters, defines helper functions |
| `DataNormalization` | Data prep | Reads the `.dta` file; normalizes outcome variables by municipal area; creates year dummy columns for the event-study specification; applies unit rescaling |
| `VariableNames` | Variable labels | Defines a lookup table mapping internal variable names to display labels and classifying them as outcomes (`out`) or covariates (`cov`) |
| `Covariates` | Model specs | Defines the list of covariate sets used across model specifications (Model I: no controls; Model II: full controls) |
| `ResultsTable` | Table scaffold | Initializes the formatted results matrix |
| `Estimations` | Main IV results | Estimates the 2SLS model with `feols()` for all outcome variables and both covariate sets; stores first-stage diagnostics; collects coefficients and confidence intervals for figures |
| `PlaceboTest` | Event study | Estimates placebo/event-study regressions using the interaction of mobile coverage × year dummies as instruments; plots pre-trend tests |
| `FigHeterogeneity` | Heterogeneity | Splits the sample by soybean yield potential (above/below median) and re-estimates the main model separately for each half |
| `FigMaps` | Maps | Builds Figure 1: maps of Starlink subscription rates, mobile coverage polygons, and DETER degradation alerts for 2022 and 2024 |
| `FigDegradation` | Fig. 3 | Coefficient plots for forest degradation outcomes |
| `FigFines` | Fig. 4 | Coefficient plots for environmental enforcement outcomes |
| `FigForestConv` | Fig. 5 | Coefficient plots for forest cover transition outcomes |
| `FigPollutionDeath` | Fig. 6 | Coefficient plots for PM pollution and mortality outcomes |
| Supplementary | Tables & Figs S1–S2 | Descriptive statistics table, first-stage results, and heterogeneity figure |

### Identification strategy

The paper uses a **two-way fixed-effects instrumental variables** design:

- **Endogenous variable:** Starlink subscriptions per 1,000 inhabitants
  (`starlink`)
- **Instrument:** Interaction of municipality-level 2021 mobile network coverage
  (`coverarea`) × year dummies (`coverarea:year`)
- **Fixed effects:** Municipality (`codmun`) + state × year
  (`interaction(uf, year)`)
- **Standard errors:** Clustered at the municipality level

The `feols()` formula syntax used is:

```r
outcome ~ covariates | codmun + interaction(uf, year) | starlink ~ coverarea:year
```

### Outputs

All figures and tables are rendered inline in the knitted HTML document. The
main outputs are:

| Output | Description |
|--------|-------------|
| Fig. 1 | Maps of Starlink adoption and forest degradation (2022 vs. 2024) |
| Fig. 2 | Event-study / placebo tests for forest degradation |
| Fig. 3 | IV estimates — forest degradation |
| Fig. 4 | IV estimates — environmental enforcement fines |
| Fig. 5 | IV estimates — forest cover transitions |
| Fig. 6 | IV estimates — air pollution and mortality |
| Table S1 | Descriptive statistics (2017–2021 vs. 2022–2024) |
| Table S2 | First-stage regression results and diagnostics |
| Fig. S1 | Heterogeneity by soybean yield potential |

---

## 6. How to Run

### Step 1 — Install packages

```r
install.packages(c(
  "tidyverse", "data.table", "readxl", "stringi", "haven", "fastDummies",
  "sf", "terra", "exactextractr", "tiff",
  "fixest", "broom",
  "ggpubr", "ggnewscale"
))
```

### Step 2 — Download raw data

Follow the instructions in [README_data.md](README_data.md) and place all files
in the `datasets/` directory as described there.

### Step 3 — Set the working directory

At the top of `starlink_dataframe.R`, update the `setwd()` call to point to the
root of this repository on your machine:

```r
setwd("/path/to/this/repository")
```

Do the same in the `Initialization` chunk of `starlink_results.Rmd`.

### Step 4 — Build the dataset

Open `starlink_dataframe.R` in RStudio and run it in full (Ctrl+Shift+Enter or
`source("starlink_dataframe.R")`).

> ⚠️ **Runtime warning:** Section 5 (air pollution) can take **several hours**
> depending on available RAM and CPU. The script is designed to be resumable —
> if interrupted, simply re-run and it will continue from the last completed
> month.

### Step 5 — Produce results

Open `starlink_results.Rmd` and knit it to HTML:

```r
rmarkdown::render("starlink_results.Rmd")
```

Or click **Knit** in RStudio. All figures and tables will be embedded in the
output HTML file.

---
## 7. Downloading Datasets

This document describes all datasets required to run `starlink_dataframe.R` and `starlink_results.Rmd`. The datasets are **not** included in this repository due to size and licensing constraints. Follow the instructions below to download each file and place it in the correct subfolder within `datasets/`.

> **Note for non-Portuguese speakers:** Several datasets are hosted on Brazilian government portals whose interfaces are entirely in Portuguese. Step-by-step instructions in English are provided for each of those cases.

---

#### Repository structure

After downloading all files, your `datasets/` directory should look like this:

```
datasets/
├── municipalities_legal_amazon.zip
├── tabela4714.csv
├── Localidades_Municipios_kml.zip
├── geoft_bho_2017_linha_costa.gpkg
├── cobertura_movel.zip
├── areas_cobertas.zip
├── deter-amz-public-2025set01.zip
├── auto_infracao_csv.zip
├── autos_infracao_icmbio_shp.zip
├── acessos_banda_larga_fixa.zip
├── PM1_BR_2016_2024.nc
├── PM2.5_BR_2016_2024.nc
├── PM10_BR_2016_2024.nc
├── chirts-era5/          ← folder with yearly .tif files
├── chirps-v3.0/          ← folder with monthly .tif files
├── deaths.zip
├── mapbiomas/            ← folder with yearly .tif files
├── DATA_GAEZ-V5_MAPSET_RES05-YXX_GAEZ-V5.RES05-YXX.HP0120.AGERA5.HIST.SOY.HRLM.tif
└── processed/            ← created automatically by starlink_dataframe.R
```

---

### 1. Geographic Base

#### 1.1 Legal Amazon Municipalities Shapefile

| Field       | Detail |
|-------------|--------|
| **File**    | `municipalities_legal_amazon.zip` |
| **Source**  | TerraBrasilis / INPE |
| **URL**     | <https://terrabrasilis.dpi.inpe.br/download/dataset/legal-amz-aux/vector/municipalities_legal_amazon.zip> |

**Instructions:** Direct download — click the URL above (or paste it in your
browser) and save the `.zip` file to `datasets/`.

---

#### 1.2 Brazilian Municipalities — Population (2022 Census)

| Field       | Detail |
|-------------|--------|
| **File**    | `tabela4714.csv` |
| **Source**  | IBGE — SIDRA Table 4714 |
| **URL**     | <https://sidra.ibge.gov.br/tabela/4714> |

**Instructions (English):**

1. Open the URL above. You will see a data query interface called **SIDRA**.
2. Leave the default selections (all territories, year 2022).
3. Click the green **Download** button at the top of the page.
4. A dialog box will appear. Under *Formato* (Format), select **CSV (US)**.
5. Check the box **Exibir códigos de territórios** ("Show territory codes") — this
   adds the numeric municipality code needed by the script.
6. Click **Baixar** (Download) and save the file as `tabela4714.csv` inside
   `datasets/`.

---

#### 1.3 Brazilian Localities — Brasília KML

| Field       | Detail |
|-------------|--------|
| **File**    | `Localidades_Municipios_kml.zip` |
| **Source**  | IBGE — Geociências |
| **URL**     | <https://www.ibge.gov.br/geociencias/organizacao-do-territorio/estrutura-territorial/27385-localidades.html> |

**Instructions (English):**

1. Open the URL above. The page title is *Localidades*.
2. Scroll down to the **Downloads** section and click the link for
   **Localidades_Municipios_kml.zip** (the full national KML package).
3. Save the `.zip` file to `datasets/`. The script reads the Brasília KML from
   within the archive without extracting it.

---

#### 1.4 South America Coastline

| Field       | Detail |
|-------------|--------|
| **File**    | `geoft_bho_2017_linha_costa.gpkg` |
| **Source**  | ANA — National Water and Sanitation Agency |
| **URL**     | <https://metadados.snirh.gov.br/geonetwork/srv/por/catalog.search#/metadata/0f57c8a0-6a0f-4283-8ce3-114ba904b9fe> |

**Instructions (English):**

1. Open the URL above (ANA's metadata catalogue).
2. On the right side of the page, click **Transferência** (Transfer/Download).
3. Download the GeoPackage file (`.gpkg`) and save it to `datasets/`.

---

### 2. Mobile Network Coverage

#### 2.1 Coverage by Census Sector (tabular)

| Field       | Detail |
|-------------|--------|
| **File**    | `cobertura_movel.zip` |
| **Source**  | ANATEL — dados.gov.br |
| **URL**     | <https://dados.gov.br/dados/conjuntos-dados/cobertura_movel> |

**Instructions (English):**

1. Open the URL above. The page title is *Cobertura Móvel*.
2. Scroll down to the **Recursos** (Resources) section.
3. Find the resource named **Atributos dos Setores Censitários** and the one
   named **Cobertura 2021 — Setores Censitários**. Download both CSV files.
4. Place both CSVs inside a single ZIP archive named `cobertura_movel.zip` and
   save it to `datasets/`. The expected internal file names are
   `Atributos_Setores_Censo_2010.csv` and `Cobertura_2021_11_Setores.csv`.

---

#### 2.2 Coverage Polygons by Municipality (KML)

| Field       | Detail |
|-------------|--------|
| **File**    | `areas_cobertas.zip` |
| **Source**  | ANATEL — dados.gov.br |
| **URL**     | <https://dados.gov.br/dados/conjuntos-dados/cobertura_movel> |

**Instructions (English):**

1. From the same ANATEL page above, look for the resource section containing
   KML files aggregated by state (*UF*) and municipality.
2. Download the KML files for all Legal Amazon states:
   `ac`, `am`, `ap`, `ma`, `mt`, `pa`, `ro`, `rr`, `to`.
3. The expected file naming pattern inside the archive is
   `todas_todas_<uf>_municipio_simple.kml`.
4. Compress all KML files into a single ZIP named `areas_cobertas.zip` and save
   it to `datasets/`.

---

### 3. Forest Degradation

#### 3.1 DETER Degradation Alerts (INPE)

| Field       | Detail |
|-------------|--------|
| **File**    | `deter-amz-public-2025set01.zip` |
| **Source**  | INPE — TerraBrasilis |
| **URL**     | <https://terrabrasilis.dpi.inpe.br/downloads/> |

**Instructions (English):**

1. Open the URL above and look for the section **DETER — Amazônia**.
2. Download the most recent public shapefile of alerts
   (*deter-amz-public-…zip*). As of the time of writing, the file used is
   `deter-amz-public-2025set01.zip`.
3. Save the `.zip` file to `datasets/` without extracting it; the script reads
   directly from the archive.

---

### 4. Environmental Enforcement

#### 4.1 IBAMA — Infraction Notices (*Autos de Infração*)

| Field       | Detail |
|-------------|--------|
| **File**    | `auto_infracao_csv.zip` |
| **Source**  | IBAMA — dados.gov.br |
| **URL**     | <https://dados.gov.br/dados/conjuntos-dados/fiscalizacao-auto-de-infracao> |

**Instructions (English):**

1. Open the URL. The page title is *Fiscalização — Auto de Infração*.
2. Under **Recursos**, click **Acessar recurso** to open the download page.
3. Download the CSV files for each year from 2016 to 2024. Each file is named
   `auto_infracao_ano_YYYY.csv`.
4. Compress all yearly CSVs into a single ZIP named `auto_infracao_csv.zip` and
   save it to `datasets/`.

---

#### 4.2 ICMBio — Infraction Notices (Shapefile)

| Field       | Detail |
|-------------|--------|
| **File**    | `autos_infracao_icmbio_shp.zip` |
| **Source**  | ICMBio — dados.gov.br |
| **URL**     | <https://dados.gov.br/dados/conjuntos-dados/autos-de-infracao-icmbio> |

**Instructions (English):**

1. Open the URL. The page title is *Autos de Infração — ICMBio*.
2. Under **Recursos**, find the shapefile download link (look for the `.shp`
   or *Shapefile* label).
3. Download the file and save it as `autos_infracao_icmbio_shp.zip` inside
   `datasets/`. The expected shapefile inside the archive is
   `autos_infracao_icmbio.shp`.

---

### 5. Satellite Broadband Access

#### 5.1 Fixed Broadband Subscriptions — ANATEL

| Field       | Detail |
|-------------|--------|
| **File**    | `acessos_banda_larga_fixa.zip` |
| **Source**  | ANATEL — dados.gov.br |
| **URL**     | <https://dados.gov.br/dados/conjuntos-dados/acessos---banda-larga-fixa> |

**Instructions (English):**

1. Open the URL. The page title is *Acessos — Banda Larga Fixa*.
2. Under **Recursos**, download the CSV files for all available years
   (the script uses files from 2015–2016 through 2024, named
   `Acessos_Banda_Larga_Fixa_YYYY.csv` or
   `Acessos_Banda_Larga_Fixa_YYYY-YYYY.csv`).
3. Compress all CSV files into a single ZIP named
   `acessos_banda_larga_fixa.zip` and save it to `datasets/`.

> This dataset is used for both **Starlink** subscriptions and the control
> variable for other GEO satellite internet providers (VSAT).

---

### 6. Air Pollution (Particulate Matter)

#### 6.1 CAMS PM Reanalysis (PM₁, PM₂.₅, PM₁₀)

| Field       | Detail |
|-------------|--------|
| **Files**   | `PM1_BR_2016_2024.nc`, `PM2.5_BR_2016_2024.nc`, `PM10_BR_2016_2024.nc` |
| **Source**  | Copernicus Atmosphere Monitoring Service (CAMS) |
| **URL**     | <https://ads.atmosphere.copernicus.eu/datasets/cams-global-reanalysis-eac4> |

**Instructions (English):**

1. You will need a free [Copernicus ADS account](https://ads.atmosphere.copernicus.eu/user/register).
2. After logging in, navigate to the dataset **CAMS global reanalysis (EAC4)**.
3. Select the variables for each particulate size:
   - **Particulate matter d < 1 µm** → `pm1`
   - **Particulate matter d < 2.5 µm** → `pm2p5`
   - **Particulate matter d < 10 µm** → `pm10`
4. Set the temporal coverage to **2016–2024**, time resolution **3-hourly**,
   and spatial domain to Brazil (approximately −5°N to −35°S, −75°W to −30°W).
5. Download each variable as a separate NetCDF (`.nc`) file and name them
   `PM1_BR_2016_2024.nc`, `PM2.5_BR_2016_2024.nc`, and `PM10_BR_2016_2024.nc`.
6. Place all three files in `datasets/`.

> ⚠️ **Warning:** Extraction of these rasters is computationally intensive and
> can take **several hours**. See the comment in `starlink_dataframe.R`
> (Section 5) for guidance on resuming interrupted runs.

---

### 7. Climate Controls

#### 7.1 Maximum Temperature — CHIRTS-ERA5

| Field       | Detail |
|-------------|--------|
| **Files**   | Yearly `.tif` files inside `datasets/chirts-era5/` |
| **Source**  | CHC — University of California, Santa Barbara |
| **URL**     | <https://www.chc.ucsb.edu/data/chirts-era5> |

**Instructions (English):**

1. Open the URL and navigate to the **Monthly Tmax** product.
2. Download the monthly GeoTIFF files for **2016–2024**.
3. Place all `.tif` files inside `datasets/chirts-era5/`. The expected filename
   pattern is `CHIRTS-ERA5.daily.global.0.25deg.ltm.1983-2016.Tmax.YYYY.MM.tif`
   (years encoded at positions 26–29 and months at 31–32 in the script).

---

#### 7.2 Precipitation — CHIRPS v3.0

| Field       | Detail |
|-------------|--------|
| **Files**   | Monthly `.tif` files inside `datasets/chirps-v3.0/` |
| **Source**  | CHC — University of California, Santa Barbara |
| **URL**     | <https://data.chc.ucsb.edu/products/CHIRPS/v3.0/monthly/latam/tifs/> |

**Instructions (English):**

1. Open the URL. You will see a directory listing of monthly GeoTIFF files.
2. Download all files corresponding to **2016–2024**. File names follow the
   pattern `chirps-v3.0.YYYY.MM.tif`.
3. Save all `.tif` files inside `datasets/chirps-v3.0/`.

---

### 8. Mortality Rates

#### 8.1 SIM — Sistema de Informações sobre Mortalidade (DATASUS)

| Field       | Detail |
|-------------|--------|
| **File**    | `deaths.zip` (user-assembled) |
| **Source**  | Ministério da Saúde — DATASUS |
| **URL**     | <https://dadosabertos.saude.gov.br/dataset/sim> |

**Instructions (English):**

1. Open the URL. The page title is *SIM — Declarações de Óbito*.
2. Under **Recursos**, find and download the files labelled
   **Mortalidade Geral YYYY** for each year from **2017 to 2024**. These are
   large CSV files (`.csv`).
3. Each file will be named `Mortalidade_Geral_YYYY.csv`.
4. Compress all eight files into a single ZIP named `deaths.zip` and save it to
   `datasets/`.

> **Note:** The portal may require you to click through a terms-of-use screen
> (*"Aceitar os termos"* — accept the terms) before downloading. Click
> **Aceitar** (Accept) to proceed.

---

### 9. Forest Cover and Land Use

#### 9.1 MapBiomas — Annual Land Cover (Collection 10)

| Field       | Detail |
|-------------|--------|
| **Files**   | Yearly `.tif` files inside `datasets/mapbiomas/` |
| **Source**  | MapBiomas Brasil — Google Earth Engine / GCS |
| **URL**     | Direct GCS links (see below) |

**Instructions (English):**

Download the annual land-cover GeoTIFF for each year from 2016 to 2024 using
the following URL pattern (replace `YYYY` with the desired year):

```
https://storage.googleapis.com/mapbiomas-public/initiatives/brasil/collection_10/lulc/coverage/brazil_coverage_YYYY.tif
```

For example, for 2022:

```
https://storage.googleapis.com/mapbiomas-public/initiatives/brasil/collection_10/lulc/coverage/brazil_coverage_2022.tif
```

Save all nine files inside `datasets/mapbiomas/`. File names must start with
`brazil_coverage` and end with `.tif` for the script's `list.files()` call to
detect them.

---

### 10. Potential Soy Yield

#### 10.1 FAO-GAEZ v5 — Attainable Yield, Soy, High-Input

| Field       | Detail |
|-------------|--------|
| **File**    | `DATA_GAEZ-V5_MAPSET_RES05-YXX_GAEZ-V5.RES05-YXX.HP0120.AGERA5.HIST.SOY.HRLM.tif` |
| **Source**  | FAO — Global Agro-Ecological Zones v5 |
| **URL**     | <https://gaez.fao.org/pages/data-viewer> |

**Instructions (English):**

1. Open the URL. Click **Launch Data Viewer**.
2. In the left panel, navigate to:
   - **Theme:** Agro-climatic Resources → Yield Gap and Attainable Yield
   - **Sub-theme:** Attainable Yield
   - **Crop:** Soybean
   - **Water supply:** Rain-fed
   - **Input level:** High
   - **Historical period:** 2001–2020 (AGERA5)
3. Click **Download** and select the **0.05° resolution** GeoTIFF.
4. The downloaded filename should match the one listed above. Save it to
   `datasets/`.

