# Replication codes for "Does access to Starlink improve criminal capability in the Amazon?" (2026)
### by Borges, Komatsu, Maturano, Nishida, and Menezes Filho

---

### Content

> **Important:** Download all files below and place them in the repository `datasets/` folder. Keep original filenames whenever possible, as the script expects specific names.

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


---
### Downloading the required datasets

This document describes all datasets required to run `starlink_dataframe.R` and `starlink_results.Rmd`. The datasets are **not** included in this repository due to size and licensing constraints. Follow the instructions below to download each file and place it in the correct subfolder within `datasets/`.

> **Note for non-Portuguese speakers:** Several datasets are hosted on Brazilian government portals whose interfaces are entirely in Portuguese. Step-by-step instructions in English are provided for each of those cases.

---

#### Summary Table

| # | Dataset | Variable(s) | Source | Period |
|---|---------|-------------|--------|--------|
| 1a | Legal Amazon municipalities | spatial base | INPE/TerraBrasilis | — |
| 1b | Municipal population | `pop` | IBGE Census 2022 | 2022 |
| 1c | Brasília KML | distance instrument | IBGE | — |
| 1d | SA coastline | distance instrument | ANA | — |
| 2a | Mobile coverage (sectors) | `coverarea` | ANATEL | 2021 |
| 2b | Mobile coverage (polygons) | maps | ANATEL | 2021 |
| 3 | DETER alerts | `area_mun_deter_*`, `n_mun_deter_*` | INPE | 2016–2024 |
| 4a | IBAMA infractions | `n_mun_ibama_*` | IBAMA | 2016–2024 |
| 4b | ICMBio infractions | `n_mun_icmbio_*` | ICMBio | 2016–2024 |
| 5 | Broadband subscriptions | `starlink`, `geosat` | ANATEL | 2015–2024 |
| 6 | CAMS PM reanalysis | `pm1mun`, `pm25mun`, `pm10mun` | Copernicus | 2016–2024 |
| 7a | CHIRTS-ERA5 Tmax | `tmax` | CHC/UCSB | 2016–2024 |
| 7b | CHIRPS v3.0 precipitation | `prcp` | CHC/UCSB | 2016–2024 |
| 8 | SIM mortality records | `mort_*`, `hom`, `hom_fa` | DATASUS | 2017–2024 |
| 9 | MapBiomas land cover | `p_forest`, forest transitions | MapBiomas | 2016–2024 |
| 10 | FAO-GAEZ soy yield | `soyield_ful_mun_high` | FAO | 2001–2020 |

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

#### 1. Geographic Base

##### 1.1 Legal Amazon Municipalities Shapefile

| Field       | Detail |
|-------------|--------|
| **File**    | `municipalities_legal_amazon.zip` |
| **Source**  | TerraBrasilis / INPE |
| **URL**     | <https://terrabrasilis.dpi.inpe.br/download/dataset/legal-amz-aux/vector/municipalities_legal_amazon.zip> |

**Instructions:** Direct download — click the URL above (or paste it in your
browser) and save the `.zip` file to `datasets/`.

---

##### 1.2 Brazilian Municipalities — Population (2022 Census)

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

##### 1.3 Brazilian Localities — Brasília KML

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

##### 1.4 South America Coastline

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

#### 2. Mobile Network Coverage

##### 2.1 Coverage by Census Sector (tabular)

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

##### 2.2 Coverage Polygons by Municipality (KML)

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

#### 3. Forest Degradation

##### 3.1 DETER Degradation Alerts (INPE)

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

#### 4. Environmental Enforcement

##### 4.1 IBAMA — Infraction Notices (*Autos de Infração*)

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

##### 4.2 ICMBio — Infraction Notices (Shapefile)

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

#### 5. Satellite Broadband Access

##### 5.1 Fixed Broadband Subscriptions — ANATEL

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

#### 6. Air Pollution (Particulate Matter)

##### 6.1 CAMS PM Reanalysis (PM₁, PM₂.₅, PM₁₀)

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

#### 7. Climate Controls

##### 7.1 Maximum Temperature — CHIRTS-ERA5

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

##### 7.2 Precipitation — CHIRPS v3.0

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

#### 8. Mortality Rates

##### 8.1 SIM — Sistema de Informações sobre Mortalidade (DATASUS)

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

#### 9. Forest Cover and Land Use

##### 9.1 MapBiomas — Annual Land Cover (Collection 10)

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

#### 10. Potential Soy Yield

##### 10.1 FAO-GAEZ v5 — Attainable Yield, Soy, High-Input

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

