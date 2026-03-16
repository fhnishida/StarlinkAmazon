# Replication code for "The Effects of Starlink adoption on forest degradation in the Amazon" (2026)
### by Borges, Komatsu, Maturano, Nishida, and Menezes Filho

---

## Table of Contents

1. [Overview](#1-overview)
2. [Downloading Datasets](#2-downloading-datasets)
3. [`starlink_dataset.R`](#3-starlink_datasetr)
4. [`starlink_results.Rmd`](#4-starlink_resultsrmd)


---

## 1. Overview

This repository contains two code files that together reproduce all results of
the paper. The workflow is strictly sequential:

```
starlink_dataset.R   →   analytical_dataset.dta   →   starlink_results.Rmd
   (data build)              (intermediary)                (results)
```

`starlink_dataset.R` reads all raw datasets, processes them, and exports a
single Stata-format panel dataset (`analytical_dataset.dta`).
`starlink_results.Rmd` reads that dataset and produces all regression tables,
event-study plots, and figures included in the paper and supplementary
materials.

> **Before running either file**, make sure all raw datasets have been
> downloaded and placed in the correct subfolders. See
> [2. Downloading Datasets](#2-downloading-datasets) for full instructions.
 
---

### How to Run

#### Step 1 — Install packages

| Package | Version tested | Role | Used in |
|---------|---------------|------|---------|
| `tidyverse` | ≥ 2.0 | Data manipulation and visualization (`dplyr`, `ggplot2`, `tidyr`, `purrr`, `readr`, `stringr`, `forcats`, `lubridate`) | Both files |
| `data.table` | ≥ 1.15 | Fast row-binding of large spatial extractions (`rbindlist`) | `starlink_dataset.R` |
| `readxl` | ≥ 1.4 | Reading `.xlsx` files | `starlink_dataset.R` |
| `stringi` | ≥ 1.8 | String processing | `starlink_dataset.R` |
| `haven` | ≥ 2.5 | Reading/writing Stata `.dta` files | Both files |
| `fastDummies` | ≥ 1.7 | Creating year dummy columns for the event-study | `starlink_results.Rmd` |
| `sf` | ≥ 1.0 | Reading and processing vector spatial data (shapefiles, KML, GPKG) | Both files |
| `terra` | ≥ 1.7 | Reading and processing raster data (GeoTIFF, NetCDF) | `starlink_dataset.R` |
| `exactextractr` | ≥ 0.10 | Area-weighted extraction of raster values to polygons | `starlink_dataset.R` |
| `tiff` | ≥ 0.1 | Low-level TIFF support required by `terra` on some systems | `starlink_dataset.R` |
| `fixest` | ≥ 0.12 | Two-way fixed-effects IV regression (`feols`) and fit statistics | `starlink_results.Rmd` |
| `broom` | ≥ 1.0 | Tidying regression output into data frames | `starlink_results.Rmd` |
| `ggpubr` | ≥ 0.6 | Combining multiple `ggplot2` panels (`ggarrange`, `annotate_figure`) | `starlink_results.Rmd` |
| `ggnewscale` | ≥ 0.4 | Multiple color/fill scales in the same `ggplot2` figure | `starlink_results.Rmd` |

> All packages are available on CRAN. No GitHub-only or private packages are required.


#### Step 2 — Download raw data

Follow the instructions in [2. Downloading Datasets](#2-downloading-datasets) and place all files
in the `data/` directory as described there.

#### Step 3 — Set the working directory

At the top of `starlink_dataset.R`, update the `setwd()` call to point to the
root of this repository on your machine:

```r
setwd("/path/to/code")
```

and the DETER dataset name (depends on the date you downloaded):
```r
DETER_zip = "deter-amz-public-2025set01.zip" # example
```

Do the same in the `Initialization` chunk of `starlink_results.Rmd`.

#### Step 4 — Build the dataset

Open `starlink_dataset.R` in RStudio and run it in full (Ctrl+Shift+Enter or `source("starlink_dataset.R")`).

> ⚠️ **Runtime warning:** Some dataset process can take **several hours**
> depending on available RAM and CPU. In particular, particulate matter extraction (from CAMS-EAC4) 
> was designed to be resumable — if interrupted, simply re-run and it will continue from the last 
> completed month.

#### Step 5 — Produce results

Open `starlink_results.Rmd` and knit it to HTML:

```r
rmarkdown::render("starlink_results.Rmd")
```

Or click **Knit** in RStudio. All figures and tables will be embedded in the
output HTML file.


---

### Repository Structure

```
.
├── README.md                       # This file
└── code/
│   ├── starlink_dataset.R          # Step 1 — builds the analytical dataset
│   └── starlink_results.Rmd        # Step 2 — produces all results and figures
└── data/
    ├── [raw files]                 # Downloaded by the user (see README.md)
    └── processed/                
        └── [intermediary files]    # Created automatically by starlink_dataset.R
        └── analytical_dataset.dta  # Processed dataset to be used in starlink_results.Rmd
```


---
## 2. Downloading Datasets

This document describes all datasets required to run `starlink_dataset.R` and `starlink_results.Rmd`. The datasets are **not** included in this repository due to size and licensing constraints. Follow the instructions below to download each file and place it in the correct subfolder within `data/`.

> **Note for non-Portuguese speakers:** Several datasets are hosted on Brazilian government portals whose interfaces are entirely in Portuguese. Step-by-step instructions in English are provided for each of those cases.

---

#### Repository structure

After downloading all files, your `data/` directory should look like this:

```
data/
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
├── data_sfc.nc
├── DATA_GAEZ-V5_MAPSET_RES05-YXX_GAEZ-V5.RES05-YXX.HP0120.AGERA5.HIST.SOY.HRLM.tif
├── chirts-era5/          ← folder with monthly .tif files
├── chirps-v3.0/          ← folder with monthly .tif files
├── deaths/               ← folder with yearly .csv and zipped .csv files
├── mapbiomas/            ← folder with yearly .tif files
└── processed/            ← created automatically by starlink_dataset.R
```

---

### 1. Geographic Base

#### 1.1 Legal Amazon Municipalities Shapefile

| **File**    | `municipalities_legal_amazon.zip` |
|-------------|--------|
| **Source**  | TerraBrasilis — INPE |
| **URL**     | <https://terrabrasilis.dpi.inpe.br/download/dataset/legal-amz-aux/vector/municipalities_legal_amazon.zip> |

**Instructions:** Direct download — click the URL above (or paste it in your browser) and save the `.zip` file to `data/` without extracting it; the script reads directly from the archive.

---

#### 1.2 Brazilian Municipalities — Population (2022 Census)


| **File**    | `tabela4714.csv` |
|-------------|--------|
| **Source**  | IBGE — SIDRA |
| **URL**     | <https://sidra.ibge.gov.br/tabela/4714> |

**Instructions:**

1. Open the URL above. You will see a data query interface called **SIDRA**.
2. Leave tick only on the following checkboxes: 'População residente (Pessoas)' and 'Município [5770/5770]'.
3. Click the **Download** button at the bottom of the page.
4. A dialog box will appear. Under *Formato* (Format), select **CSV (US)**.
5. Check the box **Exibir códigos de territórios** ("Show territory codes") — this    adds the numeric municipality code needed by the script.
6. Click **Download** and save the file as `tabela4714.csv` inside `data/`.

---

#### 1.3 Brazilian Localities — Brasília KML


| **File**    | `Localidades_Municipios_kml.zip` |
|-------------|--------|
| **Source**  | IBGE |
| **URL**     | <https://www.ibge.gov.br/geociencias/organizacao-do-territorio/estrutura-territorial/27385-localidades.html> |

**Instructions:**

1. Open the URL above. The page title is *Localidades do Brasil*.
2. Scroll down to the **Localidades do Brasil - Municípios (kml)** section and click the link on **kml** for download (the full national KML package).
3. Save the `Localidades_Municipios_kml.zip` file to `data/`. The script reads the Brasília KML from within the archive without extracting it.

---

#### 1.4 South America Coastline


| **File**    | `geoft_bho_2017_linha_costa.gpkg` |
|-------------|--------|
| **Source**  | ANA — National Water and Sanitation Agency |
| **URL**     | <https://metadados.snirh.gov.br/geonetwork/srv/por/catalog.search#/metadata/0f57c8a0-6a0f-4283-8ce3-114ba904b9fe> |

**Instructions:**

1. Open the URL above (ANA's metadata catalogue).
2. Scroll down to **Linha de Costa (gpkg)**, click **Baixar** (Download).
3. Download the GeoPackage file (`.gpkg`) and save it to `data/`.

---

### 2. Mobile Network Coverage

#### 2.1 Coverage by Census Sector (tabular)


| **Files**    | `cobertura_movel.zip` |
|-------------|--------|
| **Source**  | ANATEL — National Telecommunications Agency |
| **URL**     | <https://dados.gov.br/dados/conjuntos-dados/cobertura_movel> |

**Instructions:**

1. Open the URL above. The page title is *Cobertura Móvel*.
2. Scroll down and click on **Recursos** (Resources) section.
3. Find the resource named **Cobertura Móvel** (Mobile Coverage) and download ZIP file.
4. Save `cobertura_movel.zip` to `data/` without extracting it; the script reads directly from the archive.

---

#### 2.2 Coverage Polygons by Municipality (KML)


| **File**    | `areas_cobertas.zip` |
|-------------|--------|
| **Source**  | ANATEL — National Telecommunications Agency |
| **URL**     | <https://dados.gov.br/dados/conjuntos-dados/cobertura_movel> |

**Instructions:**

1. From the same ANATEL page above and under **Recursos**, look for the resource named **Áreas Cobertas** (Coverage Areas) and download ZIP file.
2. Save `areas_cobertas.zip` to `data/` without extracting it; the script reads directly from the archive.

---

### 3. Forest Degradation

#### 3.1 DETER Degradation Alerts (INPE)


| **File**    | `deter-amz-public-2025set01.zip` |
|-------------|--------|
| **Source**  | TerraBrasilis — INPE |
| **URL**     | <https://terrabrasilis.dpi.inpe.br/downloads/> |

**Instructions:**

1. Open the URL above and look for the section **Bioma Amazônia - DETER (Avisos)** (Amazon Biome - DETER (Alerts).
2. Download the most recent public shapefile of alerts (*deter-amz-public-(...).zip*). As of the time of writing, the file used is `deter-amz-public-2025set01.zip`.
3. Save the `.zip` file to `data/` without extracting it; the script reads directly from the archive.

---

### 4. Environmental Enforcement

#### 4.1 IBAMA — Infraction Notices


| **File**    | `auto_infracao_csv.zip` |
|-------------|--------|
| **Source**  | IBAMA — Brazilian Institute of Environment and Renewable Natural Resources |
| **URL**     | <https://dados.gov.br/dados/conjuntos-dados/fiscalizacao-auto-de-infracao> |

**Instructions:**

1. Open the URL. The page title is **Portal de Dados Abertos** (Open Data Portal).
2. Click on **Recursos** (Resources), find **Autos de infração** and click on **Acessar o recurso** (Access the resource).
3. Download the ZIP file `auto_infracao_csv.zip` and save it to `data/` without extracting it; the script reads directly from the archive.

---

#### 4.2 ICMBio — Infraction Notices (Shapefile)


| **File**    | `autos_infracao_icmbio_shp.zip` |
|-------------|--------|
| **Source**  | ICMBio — Chico Mendes Institute for Biodiversity Conservation |
| **URL**     | <[https://dados.gov.br/dados/conjuntos-dados/autos-de-infracao-icmbio](https://www.gov.br/icmbio/pt-br/assuntos/dados_geoespaciais/mapa-tematico-e-dados-geoestatisticos-das-unidades-de-conservacao-federais)> |

**Instructions:**

1. Open the URL. The page title is *Dados geoespaciais de referência da Cartografia Nacional e dados temáticos produzidos no ICMBio*.
2. Scroll down and click on **Autos de Infração ICMBio - shp**.
3. Download the file and save it as `autos_infracao_icmbio_shp.zip` inside `data/` without extracting it; the script reads directly from the archive.

---

### 5. Satellite Broadband Access

#### 5.1 Fixed Broadband Subscriptions — ANATEL


| **File**    | `acessos_banda_larga_fixa.zip` |
|-------------|--------|
| **Source**  | ANATEL — National Telecommunications Agency |
| **URL**     | <https://dados.gov.br/dados/conjuntos-dados/acessos---banda-larga-fixa> |

**Instructions:**

1. Open the URL. The page title is *Acessos - Banda Larga Fixa*.
2. Under **Recursos**, find **Dados de Acessos de Comunicação Multimídia** and click on **Acessar o recurso**
3. Download `acessos_banda_larga_fixa.zip` and save it to `data/` without extracting it; the script reads directly from the archive.

> This dataset is used for both **Starlink** subscriptions and for other GEO satellite internet providers.

---

### 6. Air Pollution (Particulate Matter)

#### 6.1 CAMS PM Reanalysis (PM₁, PM₂.₅, PM₁₀)


| **File**    | `data_sfc.nc` |
|-------------|--------|
| **Source**  | Copernicus Atmosphere Monitoring Service (CAMS) |
| **URL**     | <https://ads.atmosphere.copernicus.eu/data/cams-global-reanalysis-eac4?tab=download> |

**Instructions:**

1. You will need a free [Copernicus account](https://ads.atmosphere.copernicus.eu/user/register).
2. After logging in, navigate to the dataset URL above to **CAMS global reanalysis (EAC4)** webpage.
3. In **Variable** > **Single level**, select:
   - **Particulate matter d < 1 µm (PM1)**
   - **Particulate matter d < 2.5 µm (PM2.5)**
   - **Particulate matter d < 10 µm (PM10)**
5. Set the temporal coverage from **2017-01-01** to **2024-12-31**
6. Select **all times** from 00:00 to 21:00
7. In **Geographical area**, select **Sub-region extraction** using: 6°N to −19°S, and −75°W to −43°W
8. In **Format**, select **Zipped netCDF (experimental)**
9. Click **Submit Form** and you will be redirected to a page where you can download your request after data processing (may take a hour)
10. Download the file and unzip it to `data/data_sfc.nc`.

---

### 7. Climate Controls

#### 7.1 Maximum Temperature — CHIRTS-ERA5


| **Files**   | Monthly `CHIRTS-ERA5.monthly_Tmax.YYYY.MM.tif` |
|-------------|--------|
| **Source**  | CHC — University of California, Santa Barbara |
| **URL**     | <https://data.chc.ucsb.edu/experimental/CHIRTS-ERA5/tmax/tifs/monthly/> |

**Instructions:**

1. Open the URL and You will see a directory listing of monthly GeoTIFF files.
2. Download the monthly GeoTIFF files for **2017–2024**.
3. Place all `.tif` files inside `data/chirts-era5/`. The expected filename pattern is `CHIRTS-ERA5.monthly_Tmax.YYYY.MM.tif`, where YYYY is a year and MM is a month.

---

#### 7.2 Precipitation — CHIRPS v3.0


| **Files**   | Monthly `chirps-v3.0.YYYY.MM.tif` files |
|-------------|--------|
| **Source**  | CHC — University of California, Santa Barbara |
| **URL**     | <https://data.chc.ucsb.edu/products/CHIRPS/v3.0/monthly/latam/tifs/> |

**Instructions:**

1. Open the URL. You will see a directory listing of monthly GeoTIFF files.
2. Download all files corresponding to **2017–2024**. File names follow the pattern `chirps-v3.0.YYYY.MM.tif`, where YYYY is a year and MM is a month.
3. Save all `.tif` files inside `data/chirps-v3.0/`.

---

### 8. Mortality Rates

#### 8.1 SIM — Sistema de Informações sobre Mortalidade (DATASUS)


| **Files**    | `Mortalidade_Geral_YYYY_csv.zip`, `DOYYOPEN_csv.zip`, and `DO24OPEN.csv` |
|-------------|--------|
| **Source**  | Ministério da Saúde — DATASUS |
| **URL**     | <https://dados.gov.br/dados/conjuntos-dados/sim-1979-2019> |

**Instructions:**

1. Open the URL. The page title is *SIM — Declarações de Óbito*.
2. Under **Recursos**, find and download the CSV files labelled **Mortalidade Geral YYYY** for each year from **2017 to 2024**. Some.
3. Some of these files are zipped and other are unzipped CSV files with the following patterns `Mortalidade_Geral_YYYY` or `DOYYOPEN`.
4. Save all files into `data/deaths` with their original names and formats:
  - 2017-2021: `Mortalidade_Geral_YYYY_csv.zip`, where YYYY is a year
  - 2022-2023: `DOYYOPEN.csv`, where YY is a year
  - 2024: `DO24OPEN_csv.zip`


---

### 9. Forest Cover and Land Use

#### 9.1 MapBiomas — Annual Land Cover (Collection 10)


| **Files**   | Yearly `brazil_coverage_YYYY.tif` files |
|-------------|--------|
| **Source**  | MapBiomas   |
| **URL**     | Direct link below |

**Instructions:**

1. Download the annual land-cover GeoTIFF for each year from 2016 to 2024 using the following URL pattern (replace `YYYY` with the desired year):
```
https://storage.googleapis.com/mapbiomas-public/initiatives/brasil/collection_10/lulc/coverage/brazil_coverage_YYYY.tif
```

For example, for 2022:

```
https://storage.googleapis.com/mapbiomas-public/initiatives/brasil/collection_10/lulc/coverage/brazil_coverage_2022.tif
```

2. Save all files inside `data/mapbiomas/`.

---

### 10. Potential Soy Yield

#### 10.1 FAO-GAEZ v5 — Attainable Yield, Soy, High-Input


| **File**    | `DATA_GAEZ-V5_MAPSET_RES05-YXX_GAEZ-V5.RES05-YXX.HP0120.AGERA5.HIST.SOY.HRLM.tif` |
|-------------|--------|
| **Source**  | FAO — Global Agro-Ecological Zones v5 |
| **URL**     | <https://storage.googleapis.com/fao-gismgr-gaez-v5-data/DATA/GAEZ-V5/MAPSET/RES05-YXX/GAEZ-V5.RES05-YXX.HP0120.AGERA5.HIST.SOY.HRLM.tif> |

**Instructions:**

1. Download the file using the URL.
2. Save `GAEZ-V5.RES05-YXX.HP0120.AGERA5.HIST.SOY.HRLM.tif` to `data/`.

---

## 3. `starlink_dataset.R`

### Purpose

Reads all raw datasets, performs spatial and tabular processing, and joins everything into a single municipality × year panel saved as `analytical_dataset.dta`.

### Structure

The script is organized into numbered sections, making it easy to fold/unfold blocks in RStudio:

| Section | Name | Description |
|---------|------|-------------|
| 0 | Initialization | Loads packages, sets the working directory and the official Brazilian CRS (SIRGAS 2000 / Albers conical equal-area) |
| 1 | Building Municipal Panel | Reads the Legal Amazon municipalities shapefile; appends 2022 Census population, 2021 mobile coverage, and distances to the coast and Brasília |
| 2 | Forest Degradation | Reads DETER alerts (INPE), intersects with municipalities, computes flagged area and count by degradation type (fire, selective cutting, other) per municipality × year |
| 3 | Environmental Enforcement | Reads IBAMA and ICMBio infraction notices; classifies them by type (deforestation, fire, flora, fauna, pollution, administrative); aggregates to municipality × year |
| 4 | Satellite Broadband | Reads ANATEL fixed-broadband subscription records; isolates Starlink (LEO) and other VSAT/GEO providers; normalizes by population |
| 5 | Air Pollution | Extracts area-weighted 3-hourly PM₁, PM₂.₅ and PM₁₀ concentrations from CAMS EAC4 NetCDF reanalysis files; aggregates to annual average and converts units from kg/m³ to µg/m³ |
| 6 | Climate Controls | Extracts area-weighted monthly maximum temperature (CHIRTS-ERA5) and precipitation (CHIRPS v3.0) from GeoTIFF rasters |
| 7 | Mortality Rates | Reads SIM death records; classifies deaths by ICD-10; computes rates per 100,000 inhabitants including homicide sub-categories |
| 8 | Forest Cover and Transitions | Reads MapBiomas annual land-cover rasters; computes forest cover share and year-to-year transition matrices (forest → other land uses) by municipality |
| 9 | Potential Soy Yield | Extracts municipal attainable soybean yield (FAO-GAEZ v5, high-input scenario) for heterogeneity analysis |
| 10 | Joining Datasets | Left-joins all processed `.RDS` files on `codmun × year` and writes the final `data/processed/analytical_dataset.dta` |

### Key design choices

- **CRS:** Some spatial operations use SIRGAS 2000 Albers conical equal-area (the standard for area computations in Brazil, [as defined by IBGE](https://biblioteca.ibge.gov.br/visualizacao/livros/liv102169.pdf)) to calculate areas within municipal polygons. 
- **ZIP reading:** Raw files are read directly from `.zip` archives using `/vsizip/` (GDAL virtual filesystem) and `unz()`, so files do not need to be
  manually extracted (except for CAMS-EAC4 data, since zip filename is not standardized).
- **Resumable PM extraction:** Because processing CAMS NetCDF files can take several hours, Section 5 automatically detects the latest completed year/month
  in `data/processed/` and resumes from there.
- **Intermediary outputs:** Each section saves its result as an `.RDS` file in `data/processed/`. This allows individual sections to be re-run   independently without re-processing the entire pipeline.

### Outputs

| File | Description |
|------|-------------|
| `data/processed/munic.RDS` | Municipal panel (geography + covariates) |
| `data/processed/deter.RDS` | DETER degradation alerts |
| `data/processed/police.RDS` | Environmental enforcement fines |
| `data/processed/starlink.RDS` | Starlink subscriptions per 1,000 inhabitants |
| `data/processed/geosat.RDS` | Other GEO satellite subscriptions per 1,000 inhabitants |
| `data/processed/pm_cams.RDS` | PM₁, PM₂.₅, PM₁₀ concentrations |
| `data/processed/tmax.RDS` | Mean annual maximum temperature |
| `data/processed/prcp.RDS` | Mean annual precipitation |
| `data/processed/deaths.RDS` | Mortality rates by ICD-10 chapter |
| `data/processed/mb_forest.RDS` | Forest cover share (MapBiomas) |
| `data/processed/mbtrans.RDS` | Forest cover transitions (MapBiomas) |
| `data/processed/soy_potential.RDS` | Attainable soybean yield (FAO-GAEZ) |
| `data/processed/analytical_dataset.dta` | **Final analytical dataset** |

---

## 4. `starlink_results.Rmd`

### Purpose

Reads `data/processed/analytical_dataset.dta` and reproduces all regression tables, event-study
plots, heterogeneity analyses, and figures presented in the paper.

### Structure

| Chunk | Name | Description |
|-------|------|-------------|
| `Initialization` | Setup | Loads packages, sets locale to handle Portuguese characters, defines helper functions |
| `DataNormalization` | Data prep | Reads the `.dta` file; normalizes outcome variables by municipal area; creates year dummy columns for the event-study specification; applies unit normalization |
| `VariableNames` | Variable labels | Defines a lookup table mapping internal variable names to display labels and classifying them as outcomes (`out`) or covariates (`cov`) |
| `Covariates` | Model specs | Defines the list of covariate sets used across model specifications (Model I: no controls; Model II: full controls) |
| `ResultsTable` | Table scaffold | Initializes the formatted results matrix |
| `Estimations` | Main IV results | Estimates the 2SLS model with `feols()` for all outcome variables and both covariate sets; stores first-stage diagnostics; collects coefficients and confidence intervals for figures |
| `PlaceboTest` | Event study | Estimates placebo/event-study regressions using the interaction of mobile coverage × year dummies as instruments; plots pre-trend tests from 2017 to 2024 |
| `FigHeterogeneity` | Heterogeneity | Splits the sample by soybean yield potential (above/below median) and re-estimates the main model separately for each half |
| `FigMaps` | Maps | Builds Figure 1: maps of Starlink subscription rates, mobile coverage polygons, and DETER degradation alerts for 2022 and 2024 |
| `FigDegradation` | Fig. 3 | Coefficient plots for forest degradation outcomes |
| `FigFines` | Fig. 4 | Coefficient plots for environmental enforcement outcomes |
| `FigForestConv` | Fig. 5 | Coefficient plots for forest cover transition outcomes |
| `FigPollutionDeath` | Fig. 6 | Coefficient plots for PM pollution and mortality outcomes |
| Supplementary | Tables & Figs S1–S2 | Descriptive statistics table, first-stage results, and heterogeneity figure |

### Identification strategy

The paper uses a **two-way fixed-effects instrumental variables** design:

- **Endogenous variable:** Starlink subscriptions per 1,000 inhabitants (`starlink`)
- **Instrument:** Interaction of municipality-level 2021 mobile network coverage (`coverarea`) × year dummies (`coverarea:year`)
- **Fixed effects:** Municipality (`codmun`) + state × year (`interaction(uf, year)`)
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
