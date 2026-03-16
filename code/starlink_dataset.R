## # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
##                     BUILDING ANALYTICAL DATASET FOR                        ## 
##     'Effects of Starlink adoption on forest degradation in the Amazon'     ##
##                               March, 2026                                  ##
##       Pedro Pereira Borges, Bruno Kawaoka Komatsu, Dimitri Maturano,       ##
##                Fabio Nishida, and  Naercio Menezes Filho                   ##
## # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


{ # 0. INITIALIZATION ####
  # Removes all objects from Environment and clear unused objects
  rm(list=ls()); gc()
  
  # Loading required R packages 
  library(tidyverse) 
  library(sf) 
  library(readxl)
  library(tiff) 
  library(stringi) 
  library(exactextractr) 
  library(terra) 
  
  # Setting the working directory (root)
  setwd("path/to/code")
  
  # Name of DETER shapefile (update with your version)
  DETER_zip = "deter-amz-public-2025set01.zip"
  
  
  # Check and create required directories
  for (folder in c("../data",
                   "../data/processed",
                   "../data/mapbiomas",
                   "../data/chirts-era5",
                   "../data/chirps-v3.0")) {
    if (!dir.exists(folder)) {
      dir.create(folder, recursive = TRUE)
      message("Created folder: ", folder)
    }
  }
  
    
  # Check raster data folders — stop if empty
  raster_folders = c("../data/mapbiomas",
                     "../data/deaths",
                     "../data/chirts-era5",
                     "../data/chirps-v3.0")
  
  empty_folders = raster_folders[sapply(raster_folders, function(f) length(list.files(f)) == 0)]
  
  if (length(empty_folders) > 0) {
    stop(
      "The following folders exist but are empty. Please populate them ",
      "with the required raster files before running this script:\n",
      paste0("  - ", empty_folders, collapse = "\n"), "\n",
      "Refer to https://github.com/fhnishida/StarlinkAmazon for detailed instructions."
    )
  }
  
  
  # Official CRS for computing areas (SIRGAS 2000 - conic Albers equiv, in meters)
    # https://biblioteca.ibge.gov.br/visualizacao/livros/liv102169.pdf (page 21)
  proj_wk = 'PROJCS["Conica_Equivalente_de_Albers_Brasil",  
    GEOGCS["GCS_SIRGAS2000",  
      DATUM["D_SIRGAS2000",  
        SPHEROID["Geodetic_Reference_System_of_1980",6378137,298.2572221009113]],  
      PRIMEM["Greenwich",0],  
      UNIT["Degree",0.017453292519943295]],  
    PROJECTION["Albers"],  
    PARAMETER["standard_parallel_1",-2],  
    PARAMETER["standard_parallel_2",-22],  
    PARAMETER["latitude_of_origin",-12],  
    PARAMETER["central_meridian",-54],  
    PARAMETER["false_easting",5000000],  
    PARAMETER["false_northing",10000000],  
    UNIT["Meter",1]]'
  
  # Function to obtain info of shapefiles/rasters' CRS/EPSG
  crs_info = function(x) {
    crs_obj = st_crs(x)
    sprintf("CRS: %s | EPSG: %s | Unit: %s",
            sub('^[^"]*"([^"]+)".*$', '\\1', crs_obj$wkt),
            crs_obj$epsg,
            crs_obj$units_gdal) 
  }
  
  # Amazonian municipalities shapefile (IBGE via INPE)
  amz = st_read("/vsizip/../data/municipalities_legal_amazon.zip/municipalities_legal_amazon.shp") %>%
    st_make_valid() %>% 
    st_transform(crs = proj_wk) %>% st_make_valid() %>%
    mutate(
      areamun = as.numeric(units::set_units(st_area(.), km^2)),
      codmun = as.numeric(geocodigo),
      uf = as.numeric(substr(geocodigo, 1, 2))
    ) %>%
    select(codmun, namemun = nome, uf, areamun) %>% 
    
    # 2022 Census municipal population (IBGE)
    left_join(
      read.csv("../data/tabela4714.csv", 
               sep = ",", quote = "\"", skip = 3) %>% 
        rename(codmun = Cód., pop = X2022) %>% .[1:5570, ] %>% 
        select(codmun, pop) %>%
        mutate(codmun = as.numeric(codmun)),
      by = "codmun"
    )
  
}


{ # 1. BUILDING MUNICIPAL PANEL ####

# Latitude and Longitude (using centroids)
  latlong = amz %>% st_transform(4674) %>% st_make_valid() %>%
    mutate(lat = st_coordinates(st_centroid(geometry))[,2],
           lon = st_coordinates(st_centroid(geometry))[,1]) %>% 
    select(codmun, lat, lon) %>%
    st_drop_geometry()
  
  
  ## Distances to Brasilia and nearest coast
  # Calculates distance using CRS 4674 (SIRGAS 2000 in degrees)
  sf_use_s2(TRUE) # Uses Google's S2 Geometry for spherical approximation
  
  # Amazonian municipalities shapefile
  mun = amz %>% st_transform(4674) %>% st_make_valid() %>% select(codmun)
  
  # South America coastline (National Water and Sanitation Agency - ANA)
  sa_coast = st_read("../data/geoft_bho_2017_linha_costa.gpkg",
                     layer = "geoft_bho_2017_linha_costa") %>%
    st_make_valid() %>% st_transform(4674)  %>% st_make_valid() %>%
    .[1,] # only continental part of South America
  
  # Brasilia shapefile - capital of Brazil
  brasilia = st_read("/vsizip/../data/Localidades_Municipios_kml.zip/kml/DF/brasilia_5300108_localidades_2022.kml") %>%
    st_make_valid() %>% st_transform(4674)  %>% st_make_valid()
  
  dist = mun %>%
    mutate(
      dist_coast = as.numeric(st_distance(mun, sa_coast) / 1000),
      dist_brasilia = as.numeric(st_distance(mun, brasilia) / 1000)
    ) %>%
    st_drop_geometry()
  
  rm(sa_coast, brasilia, mun)
  
  
  # 2021 municipal mobile coverage
  mobile = read_csv2(unz("../data/cobertura_movel.zip", "Atributos_Setores_Censo_2010.csv")) %>%
    select(setor=`Código Setor Censitário`, area=`Área (km2)`, 
           codmun=`Código Município`) %>% 
    left_join(
      read_csv2(unz("../data/cobertura_movel.zip", "Cobertura_2021_11_Setores.csv")) %>%
        filter(Operadora=="Todas") %>% 
        select(setor=`Código Setor Censitário`, coverarea=Cobertura_Todas),
      by="setor") %>% arrange(setor) %>%
    mutate(setor = as.character(setor),
           coverarea = ifelse(is.na(coverarea), 0, coverarea)) %>%
      group_by(codmun) %>% 
      summarise(coverarea = weighted.mean(x=coverarea, w=area))
  
  
  # Joining datasets
  mun = amz %>% 
    merge(2017:2024) %>% rename(year = y) %>%
    left_join(mobile, by = "codmun") %>% 
    left_join(dist, by = "codmun") %>% 
    left_join(latlong, by = "codmun") %>% 
    mutate(dens = pop / areamun) %>%
    arrange(codmun, year) %>%
    st_drop_geometry()
  
  saveRDS(mun, "../data/processed/munic.RDS")
  rm(mun, mobile, dist, latlong)
  
} # 1. BUILDING MUNICIPAL PANEL (END)



{ # 2. FOREST DEGRADATION ####
  
  # DETER forest degradation alerts
  deter = st_read(paste0("/vsizip/../data/", DETER_zip, 
                         "/deter-amz-deter-public.shp")) %>%
    st_make_valid() %>% st_transform(crs=proj_wk) %>% st_make_valid() %>%
    rename(class=CLASSNAME, codmun=GEOCODIBGE) %>%
    mutate(year = year(VIEW_DATE),
           codmun = as.numeric(codmun),
           class = case_when(
             class=="CICATRIZ_DE_QUEIMADA" ~ "deter_degr_fire",
             class=="DEGRADACAO" ~ "deter_degr_outr",
             class=="CS_DESORDENADO" ~ "deter_degr_wood",
             class=="CS_GEOMETRICO" ~ "deter_degr_wood",
             class=="CORTE_SELETIVO" ~ "deter_degr_wood",
           )) %>%
    filter(year >= 2017 & year <= 2024 & !is.na(class)) %>% 
    st_intersection(amz) %>% st_make_valid() %>%
    mutate(class = ifelse(class=="", NA, class),
           month = month(VIEW_DATE)) %>%
    group_by(codmun, year, month, class) %>%
    summarise(n = n()) %>% ungroup() %>%
    mutate(area = as.numeric(units::set_units(st_area(.), km^2))) %>%
    pivot_wider(names_from = "class", 
                values_from = c("area", "n"),
                names_glue  = "{.value}_mun_{class}") %>% 
    mutate(
      across(colnames(.)[grepl("^(area_|n_)", colnames(.))],
             ~ifelse(is.na(.x), 0, .x)),
      area_mun_deter_degr = rowSums(across(starts_with("area_mun_deter_degr_")), na.rm = TRUE),
      n_mun_deter_degr = rowSums(across(starts_with("n_mun_deter_degr_")), na.rm = TRUE),
    ) %>% st_drop_geometry() %>% group_by(codmun, year, month) %>%
    summarise(
      across(colnames(.)[grepl("^(area_|n_)", colnames(.))],
             ~sum(.x))
    ) %>% ungroup()
  
  
  deter = amz %>% select(codmun) %>% st_drop_geometry() %>%
    merge(2017:2024) %>% rename(year = y) %>%
    merge(1:12) %>% rename(month = y) %>% 
    arrange(codmun, year, month) %>% 
    left_join(deter, by = c("codmun", "year", "month")) %>%
    mutate_at(
      vars(starts_with("area_"), starts_with("n_")),
      ~replace(., is.na(.), 0)
    )
    
  saveRDS(deter %>%
            filter(year >= 2017 & year <= 2025) %>% 
            group_by(codmun, year) %>% 
            summarise(
              across(starts_with("area_") | starts_with("n_"), ~ sum(.x, na.rm = TRUE))
            ) %>% 
            ungroup(),
          "../data/processed/deter.RDS")
  
  rm(deter)
  
} # 2. FOREST DEGRADATION (END)



{ # 3. ENVIRONMENTAL ENFORCEMENT ####
  
  ## 3.1. IBAMA
  ibamamun = data.frame()
  offendmun = data.frame()
  
  for (t in 2017:2024) {
    x = read.csv2(unz("../data/auto_infracao_csv.zip",
                  paste0("auto_infracao_ano_",t,".csv"))) %>%
      mutate(year = year(DAT_HORA_AUTO_INFRACAO),
             month = month(DAT_HORA_AUTO_INFRACAO),
             id = row_number()) %>% 
      select(year, month, INFRACAO_AREA, TIPO_INFRACAO, id, 
             codmun = COD_MUNICIPIO) %>%
      mutate(
        TIPO_INFRACAO = case_when(
          TIPO_INFRACAO %in% c("Fauna", "Pesca") ~ "Fauna",
          TIPO_INFRACAO %in% c("Flora") ~ "Flora",
          TIPO_INFRACAO %in% c("Qualidade Ambiental", "Cadastro Técnico Federal",
                           "Controle Ambiental", "Licenciamento") ~ "Pollution",
          TIPO_INFRACAO %in% c("Administração Ambiental", "Cadastro Técnico Federal",
                           "Ord. Urbano e Patr. Cultural", "Unidade de Conservação",
                           "Org. Gen. Modific. e Biopirataria", "Outras") ~ "Administrative"
          )
        )
    
    x = x %>% 
      select(id) %>% 
      right_join(x, by = "id") %>% 
      mutate(id = row_number(),
             dummy_defo = ifelse(INFRACAO_AREA == "Desmatamento" | 
                                   INFRACAO_AREA == "Desmatamento e Queimada", 1, 0),
             dummy_fire = ifelse(INFRACAO_AREA == "Desmatamento e Queimada" | 
                                   INFRACAO_AREA == "Queimada", 1, 0),
             dummy_flor = ifelse(TIPO_INFRACAO == "Flora", 1, 0),
             dummy_faun = ifelse(TIPO_INFRACAO == "Fauna", 1, 0),
             dummy_polu = ifelse(TIPO_INFRACAO == "Pollution", 1, 0),
             dummy_admi = ifelse(TIPO_INFRACAO == "Administrative", 1, 0),
             )
    
    ibamamun = rbind(ibamamun,
                     x %>% st_drop_geometry() %>%
                       group_by(codmun, year, month) %>% summarise(
                         n_mun_ibama = n(),
                         n_mun_ibama_fire = sum(dummy_fire),
                         n_mun_ibama_defo = sum(dummy_defo),
                         n_mun_ibama_flor = sum(dummy_flor),
                         n_mun_ibama_faun = sum(dummy_faun),
                         n_mun_ibama_polu = sum(dummy_polu),
                         n_mun_ibama_admi = sum(dummy_admi),
                       )) 
    
  }
    
  ## 3.2. ICMBio ##
  
  # Word lists to categorize environmental criminal activities (using regex/ASCII)
  rx = list(
    `Administrative` = c(
      "veiculo", "placa", "moto", "carro", "recreacao", "lazer", "balneario", "atrativo", 
      "circuito", "entrou", "permanencia", "permanece(u|r)", "visita", "trafeg", "reforma",
      "construc(ao|oes)", "cerca", "edific", "alvenaria", "galpao", "instala", "casa",
      "imovel", "benfeitoria", "rancho", "muro", "instalacao", "estrutura", "construir",
      "chale", "atraca", "ponte", "barragem", "fazenda", "moradia", "retirada de agua",
      "residencia", "empresa", "transit", "motocicleta", "barramento", "intervir", 
      "compra ilegal de terra publica", "obstrucao", "turístico", "estacionando", 
      "invas(ao|oes)", "loteamento", "quarto", "estacionamento", "picha", "comercio",
      "obra", "interven", "oficina", "loja", "comercial", "quiosque", "automotor", 
      "movimentacao de solo", "conduzir moto", "empreendimento", "buggy", "turistica",
      "bicicleta", "hotel", "vistacao", "entrada e vedada", "motociclesta", "mergulho",
      "desembarque", "lambreta", "acampado", "religi", "edificacao", "captacao de agua"
    ),
    `LoggingPlant` = c(
      "produtos florestais", "motosserra", "corte", "madeira", "carread", "derrubada",
      "exploracao florestal", "angelim", "tora", "carreador", "retirada", "palmito",
      "cortar", "serraria", "trepadeira", "trator esteira", "paraju", "aderno", "miridiba",
      "tauari", "maracatiara", "cedro", "essencia", "essência", "madeireiro", "cipó silvestre",
      "madeireira", "araucaria", "abatimento", "transporte de arvore", "seletiva",
      "castanheira", "\\bretirada\\s+de\\s+\\d+(?:[\\.,]\\d+)?\\s*arvore(s)?\\b", 
      "produto florestal", "trator de esteira", "trator valmit", "moto-serra", "motoserra",
      "produtos florestrais", "cascalho",  "trator de pneu", "toreiro", "trator fiatallis",
      "\\babater\\s+\\d+\\s+arvore\\b", "pinhao", "plantas", "bromelia", "orquid(e|i)a",
      "orquidia", "acai", "frut", "lenha"
    ),
    `Mining` = c(
      "exploracao de ouro", "garimpo", "extracao de areia", "retirada de areia",
      "minerio", "minera", "quartz", "quartiz", "garimpagem", "granito", "minerios",
      "exploracao aurifera", "garimpe", "minwracao", "mercurio", "amolar"
    ),
    `Wildlife` = c(
      "pescar", "quelonio", "pesca", "caca", "arma(s) de fogo", "tatu", "fuzarca",
      "zangaria", "espingarda", "rede", "goiamum", "tartaruga", "pirarucu", "peixe-boi",
      "municao", "alevino", "molinete", "calibre", "armadilha", "abater anima"
    ),
    `DegradDeforest` = c(
      "retroescadeira", "suprimi", "destruir", "ocupacao", "incendio", "vegetacao nativa",
      "supress", "aterr", "estrada", "acesso", "abertura de estrada", "queima", "grilagem",
      "hectar", "destruicao", "eros", "invasão",  "\\b(?:ha|\\d+\\s*ha)\\b", "uso de fogo",
      "marge(m|ns)", "assoreamento", "atraves do fogo", "uso do fogo", "abertura de trilha",
      "escavacao", "limpeza da area", "limpeza de area", "loteamento", "trator escavadeira", 
      "lesao", "destruindo", "utilizando fogo", "reabertura", "remocao", "abrir uma trilha",
      "atea", "plato", "retro escavadeira", "parcelamento", "desmat", "corte raso", "ramal"
    ),
    `Livestock` = c(
      "gado", "pecuaria", "pasto", "bovino", "soltura", "suino", "animais domesticos",
      "criacao de peixes", "pastagem"
    ),
    `Pollution` = c(
      "vazamento", "residuo", "esgoto", "efluente", "derram", "resto", "lixo", "dejeto", 
      "sedimento", "afluente", "descarte", "embalagem", "entulho", "toxic"
    ),
    `Crop` = c(
      "agricultura", "agricola", "agrotoxico"
    )
  )
  
  shp = st_read("/vsizip/../data/autos_infracao_icmbio_shp.zip/autos_infracao_icmbio.shp") %>%
    st_make_valid() %>% st_transform(crs = proj_wk) %>% st_make_valid() %>%
    rename(year = ano) %>% mutate(year = as.numeric(year)) %>%
    select(numero_ai, desc_ai, data, year, artigo_1, artigo_2, tipo_infra) %>%
    filter(year >= 2017 & year <= 2024) %>% rowwise() %>% mutate(
      
      month = month(data),
      
      TIPO_INFRACAO = case_when(
        artigo_1 %in% as.character(c(24:42, 84)) | artigo_2 %in% as.character(c(24:42, 84)) ~ "Fauna",
        artigo_1 %in% as.character(c(43:60, 85)) | artigo_2 %in% as.character(c(43:60, 85)) ~ "Flora",
        artigo_1 %in% as.character(61:71) | artigo_2 %in% as.character(61:71) ~ "Pollution",
        artigo_1 %in% as.character(c(72:83, 86:90)) | artigo_2 %in% as.character(c(72:83, 86:90)) ~ "Administrative",
        TRUE ~ NA
      ),
      
      desc_ai = stri_replace_all_regex(desc_ai, "[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]", ""),
      desc_ai = stri_trans_nfc(desc_ai),
      desc_ai = str_to_lower(desc_ai, locale = "pt"),
      desc_ai = stri_trans_general(desc_ai, "Latin-ASCII"), # remover acentos para facilitar matching
      desc_ai = str_squish(desc_ai), # normalizar espaços
      
      ATIVIDADE = case_when(
        any(str_detect(desc_ai, rx$DegradDeforest)) ~ "DegradDeforest",
        any(str_detect(desc_ai, rx$Logging)) ~ "Logging",
        any(str_detect(desc_ai, rx$Crop)) ~ "Crop",
        any(str_detect(desc_ai, rx$Livestock)) ~ "Livestock",
        any(str_detect(desc_ai, rx$Wildlife)) ~ "Wildlife",
        any(str_detect(desc_ai, rx$Pollution)) ~ "Pollution",
        any(str_detect(desc_ai, rx$Mining)) ~ "Mining",
        any(str_detect(desc_ai, rx$Administrative)) ~ "Administrative",
        TRUE ~ "Other"
      ),
      
      TIPO_INFRACAO = ifelse(!is.na(TIPO_INFRACAO), TIPO_INFRACAO,
                             case_when(
                               ATIVIDADE %in% c("DegradDeforest", "Logging", "Crop") ~ "Flora",
                               ATIVIDADE %in% c("Livestock", "Wildlife") ~ "Fauna",
                               ATIVIDADE %in% c("Pollution", "Mining") ~ "Pollution",
                               ATIVIDADE %in% c("Administrative", "Other") ~ "Administrative"
                             )),
      
      dummy_fire = 1 * (any(str_detect(desc_ai, c("fogo", "incendi", "queima"))) &
                    !str_detect(desc_ai, "arma de fogo") | 
                    artigo_1 == "58" | artigo_2 == "58"),
      dummy_fire = ifelse(is.na(dummy_fire), 0, dummy_fire),
      
      dummy_flor = 1 * (TIPO_INFRACAO == "Flora"),
      dummy_faun = 1 * (TIPO_INFRACAO == "Fauna"),
      dummy_polu = 1 * (TIPO_INFRACAO == "Pollution"),
      dummy_admi = 1 * (TIPO_INFRACAO == "Administrative"),
      
      dummy_defo = case_when(
        artigo_1 %in% as.character(c(43:44, 48:53, 58)) | artigo_2 %in% as.character(c(43:44, 48:53, 58)) ~ 1,
        !(artigo_1 %in% as.character(24:90)) & !(artigo_2 %in% as.character(24:90)) &
          ATIVIDADE %in% c("DegradDeforest", "Logging") ~ 1,
        TRUE ~ 0),
      
      org = "icmbio",
      
      ) %>% ungroup() %>%
    select(year, month, dummy_fire, dummy_flor, dummy_defo,
           dummy_faun, dummy_polu, dummy_admi)
  
  
  icmbiomun = amz %>% st_intersection(shp) %>% st_drop_geometry() %>%
    group_by(codmun, year, month) %>% summarise(
      n_mun_icmbio = n(),
      n_mun_icmbio_fire = sum(dummy_fire),
      n_mun_icmbio_defo = sum(dummy_defo),
      n_mun_icmbio_flor = sum(dummy_flor),
      n_mun_icmbio_faun = sum(dummy_faun),
      n_mun_icmbio_polu = sum(dummy_polu),
      n_mun_icmbio_admi = sum(dummy_admi),
    )
  
  
  ## 3.3. Joining IBAMA and ICMBIO
  police = amz %>% st_drop_geometry() %>% select(codmun) %>% 
    merge(2017:2024) %>% rename(year = y) %>%
    merge(1:12) %>% rename(month = y) %>%
    arrange(codmun, year, month) %>%
    left_join(ibamamun, by = c("codmun", "year", "month")) %>%
    left_join(icmbiomun, by = c("codmun", "year", "month")) %>%
    mutate_at(
      vars(starts_with("n_")), ~replace(., is.na(.), 0)
    ) %>% 
    mutate(
      n_mun_police = n_mun_ibama + n_mun_icmbio,
      n_mun_police_fire = n_mun_ibama_fire + n_mun_icmbio_fire,
      n_mun_police_defo = n_mun_ibama_defo + n_mun_icmbio_defo,
      n_mun_police_flor = n_mun_ibama_flor + n_mun_icmbio_flor,
      n_mun_police_faun = n_mun_ibama_faun + n_mun_icmbio_faun,
      n_mun_police_polu = n_mun_ibama_polu + n_mun_icmbio_polu,
      n_mun_police_admi = n_mun_ibama_admi + n_mun_icmbio_admi,
    ) %>% 
    select(codmun, year, month, starts_with("n_mun"))
  
 
  saveRDS(
    police %>%
      filter(year >= 2017 & year <= 2024) %>%
      group_by(codmun, year) %>%
      summarise(across(.cols = starts_with("n_"), .fns = ~ sum(.x, na.rm = TRUE)), 
                .groups = "drop") %>% ungroup(),
    "../data/processed/police.RDS"
    )
  
  rm(police, ibamamun, icmbiomun, x, shp, rx)
  
} # 3. ENVIRONMENTAL ENFORCEMENT (END)



{ # 4. SATELLITE BROADBAND ####

  ## STARLINK
  aux = data.frame()
  for (t in 2021:2024) {
    aux = bind_rows(aux, 
                    read_csv2(unz("../data/acessos_banda_larga_fixa.zip",
                                  paste0("Acessos_Banda_Larga_Fixa_",t,".csv"))) %>%
                      filter(Tecnologia == "VSAT" & `Meio de Acesso` == "Satélite" &
                               Empresa == "STARLINK BRAZIL SERVICOS DE INTERNET LTDA."
                             ) %>%
                      select(codmun=`Código IBGE Município`, year=Ano, month=Mês, 
                             Acessos) %>%
                      group_by(codmun, year, month) %>%
                      summarise(starlink = sum(Acessos))) %>%
      arrange(codmun, year, month)
    }
  
  starlink = amz %>% 
    st_drop_geometry() %>% 
    select(codmun, pop) %>% unique() %>%
    merge(2017:2024) %>% rename(year = y) %>%
    merge(1:12) %>% rename(month = y) %>%
    arrange(codmun, year, month) %>%
    left_join(aux, by = c("codmun", "year", "month")) %>%
    mutate(starlink = ifelse(is.na(starlink), 0, starlink),
           starlink = starlink / (pop / 1000)) %>%
    select(-pop)
  
  saveRDS(
    starlink %>%
      filter(year >= 2022 & year <= 2025) %>%
      group_by(codmun, year) %>%
      summarise(starlink = mean(starlink)),
    "../data/processed/starlink.RDS"
    )
  
  
  ## Other GEO satellite internet providers ##
  aux = data.frame()
  
  for (t in c("2017-2018","2019-2020","2021","2022","2023","2024")) {
    aux = bind_rows(aux, 
                    read_csv2(unz("../data/acessos_banda_larga_fixa.zip",
                        paste0("Acessos_Banda_Larga_Fixa_",t,".csv"))) %>%
                      filter(Tecnologia == "VSAT" & `Meio de Acesso` == "Satélite" &
                               Empresa != "STARLINK BRAZIL SERVICOS DE INTERNET LTDA."
                             ) %>%
                      select(codmun=`Código IBGE Município`, year=Ano, month=Mês, 
                             Acessos) %>%
                      group_by(codmun, year, month) %>%
                      summarise(geosat = sum(Acessos))) %>%
      arrange(codmun, year, month)
    }
  
  geosat = amz %>% 
    st_drop_geometry() %>% 
    select(codmun, pop) %>% unique() %>%
    merge(2017:2024) %>% rename(year = y) %>%
    merge(1:12) %>% rename(month = y) %>%
    arrange(codmun, year, month) %>%
    left_join(aux, by = c("codmun", "year", "month")) %>%
    mutate(geosat = ifelse(is.na(geosat), 0, geosat),
           geosat = geosat / (pop / 1000)) %>%
    select(-pop)
  
  
  saveRDS(
    geosat %>%
      filter(year >= 2017 & year <= 2024) %>%
      group_by(codmun, year) %>%
      summarise(geosat = mean(geosat)),
    "../data/processed/geosat.RDS"
    )
  
  rm(aux, geosat, starlink)
} # 4. SATELLITE BROADBAND (END)


{ # 5. AIR POLLUTION ####

  # Function for exact_extract() to calculate average weighted by covered area
  sum_coverage = function(x){
    list(x %>%
           mutate(total_area = sum(coverage_area, na.rm=T),
                  proportion = coverage_area / total_area,
                  product = value * proportion) %>%
           select(product)
         )
    }
  
  
  ## 5.1 Extracting particulate matter from nc's (collection of rasters)
   # WARNING: PROCESSING CAN TAKE SEVERAL HOURS TO CONCLUDE
   # Therefore, we divided this code into two parts:
   # (a) Extracting averaging 3-hour data into monthly basis and saving a RDS
   #     for every completed year of extraction
   # (b) Joining all yearly RDS into one data frame and aggregating all data
  
  
  # (a) Extracting PM data and saving to RDS file
  for (PM_SIZE in c("1", "2.5", "10")) {
    message(paste0("## PM", PM_SIZE, " - Raster Extraction ##"))
    N = sub("\\.", "p", PM_SIZE)
    
    aux = rast("../data/data_sfc.nc", subds = paste0("pm", N)) %>%
      project(proj_wk) %>%
      crop(amz, snap = "out")
    
    timestamps = as.numeric(sub(paste0("pm", N,"_valid_time="), "", names(aux))) # UNIX timestamps
    dates = as.POSIXct(timestamps, origin = "1970-01-01", tz = "UTC") # Convert to POSIXct
    
    
    # Check lastest file to resume extraction (if)
    files = list.files("../data/processed")
    files = files[grepl(paste0("pm", sub("\\.", "", PM_SIZE), "mun"), files)]
    
    run = TRUE
    
    if (any(grepl("pm", files))) {
      ym_matches = regmatches(files, regexpr("\\d{4}[_]?\\d{2}", files))
      ym_matches = gsub("(\\d{4})[_]?(\\d{2})", "\\1-\\2", ym_matches)
      
      ym_dates = as.Date(paste0(ym_matches, "-01"))
      latest_month = max(ym_dates, na.rm = TRUE)
      next_month = as.Date(format(latest_month, "%Y-%m-01")) + months(1)
      latest_cutoff = as.POSIXct(next_month, tz = "UTC") # Convert to POSIXct
      
      # Retain only dates occurring after the cutoff date
      if (sum(dates >= latest_cutoff) > 0) {
        aux = aux[[dates >= latest_cutoff]]
        timestamps = as.numeric(sub(paste0("pm", N, "_valid_time="), "", names(aux))) # UNIX timestamps
        dates = as.POSIXct(timestamps, origin = "1970-01-01", tz = "UTC") # Convert to POSIXct
      } else {
        run = FALSE
      }
    }
    
    if (run) {
      ano = year(dates)
      mes = month(dates)
      dia = day(dates)
      hora = hour(dates)
      print(paste0("Starting at ", ano[1], "-", mes[1]))
      
      pm_mun = tibble()
  
      for (i in 1:length(dates)) {
        if (i == 1 || (dia[i] >= 15 & dia[i-1] < 15) || mes[i-1] != mes[i]) {
          message(paste0("## Year ", ano[i], ", Month ", mes[i], ", Day ", dia[i]," ## ", 
                         format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " ##"))
        }
        
        tif = aux[[i]]
        y = ano[i]
        m = mes[i]
        d = dia[i]
        h = hora[i] 
        
        ext = exact_extract(tif, amz, coverage_area = T, progress=F,
                            max_cells_in_memory = 3e+9,
                            summarize_df = T, fun = sum_coverage)
        pm_mun = bind_rows(pm_mun, 
                           bind_cols(amz %>% st_drop_geometry() %>% select(codmun),
                                     year = y, month = m, dia = d, hour = h,
                                     pm_mun = sapply(ext, sum, na.rm=T))
                           )
        
        if (y == 2024 & m == 12 || m != mes[i+1]) {
          saveRDS(pm_mun, paste0("../data/processed/pm", sub("\\.", "", PM_SIZE), "mun_", y, "_", sprintf("%02d",m)))
          pm_mun = tibble()
        }
        
      }
    }
  }
  
  # (b) Joining all RDS extracted in (a)
  pm_mun = tibble()
  for (PM_SIZE in c("1", "2.5", "10")) {
    message(paste0("## PM", PM_SIZE, " - Binding Rows ##"))
    
    for (ano in 2017:2024) {
      
      for (mes in sprintf("%02d", 1:12)) {
        pm_mun = bind_rows(
          pm_mun,
          readRDS(paste0("../data/processed/pm", sub("\\.", "", PM_SIZE),
                         "mun_", ano, "_", mes)) %>%
            mutate( 
              pm_mun = pm_mun * 1e9, # kg/m³ → ug/m³
              pmsize = PM_SIZE,
            )
          )
      }
      
    }
  }

  saveRDS(pm_mun %>% group_by(codmun, year, pmsize) %>%
            summarise(pm_mun = mean(pm_mun)) %>%
            ungroup() %>% 
            mutate(pmsize = sub("\\.", "", pmsize)) %>%
            pivot_longer(cols = starts_with("pm_")) %>%
            mutate(name = paste0("pm", pmsize, substr(name, 4, nchar(name)))) %>%
            select(-pmsize) %>% pivot_wider(),
          paste0("../data/processed/pm_cams.RDS"))
  
  rm(aux, pm_mun, ext, tif, y, m, d, h, dates, files, hora, dia, mes, ano, i, N,
     timestamps, latest_cutoff, latest_month, next_month, ym_dates, ym_matches,
     sum_coverage, PM_SIZE)
  
} # 5. AIR POLLUTION (END)


{ # 6. MAX TEMPERATURE AND PRECIPITATION ####
  
  # Bounding box with buffer (degrees)
  bbox = st_bbox(amz %>% st_transform(4326)) + c(-.5, -.5, .5, .5)
  
  # Function to calculate the value weighted by covered area in the polygon
  sum_coverage = function(x){
    list(x %>%
           mutate(total_area = sum(coverage_area, na.rm=T),
                  proportion = coverage_area / total_area,
                  product = value * proportion) %>%
           select(product)
         )
    }
  
  
  ## 6.1. Extracting maximum temperature (Tmax) ##
  files = list.files("../data/chirts-era5", pattern = "\\.tif$")
  tmax = tibble()

  for (f in files) {
    tif = rast(paste0("../data/chirts-era5/", f)) %>% crop(bbox)
    tif[tif == -9999] = NA
    tif = tif %>% project(proj_wk)
    
    y = as.numeric(substr(f, 26, 29))
    m = as.numeric(substr(f, 31, 32))

    ext = exact_extract(tif, amz, coverage_area = T,
                        summarize_df = T, fun = sum_coverage)

    tmax = bind_rows(tmax,
                     bind_cols(amz %>% st_drop_geometry() %>% select(codmun),
                               year = y,
                               month = m,
                               tmax = sapply(ext, sum, na.rm=T)
                               )
                     )

  }
  
  
  saveRDS(tmax %>%
            mutate(codmun = as.numeric(codmun)) %>%
            filter(year >= 2017 & year <= 2024) %>%
            group_by(codmun, year) %>%
            summarise(tmax = mean(tmax)) %>%
            ungroup() %>% arrange(codmun, year),
          "../data/processed/tmax.RDS")
  
  rm(tmax)
  
  
  ## 6.2. Extracting precipitation (prcp)
  files = list.files("../data/chirps-v3.0")
  prcp = tibble()
  
  for (f in files) {
    tif = rast(paste0("../data/chirps-v3.0/", f)) %>%
      crop(bbox) %>%
      project(proj_wk)
    
    y = as.numeric(substr(f, 13, 16))
    m = as.numeric(substr(f, 18, 19))
    
    ext = exact_extract(tif, amz, coverage_area = T,
                        summarize_df = T, fun = sum_coverage)
    
    prcp = bind_rows(prcp,
                     bind_cols(amz %>% st_drop_geometry() %>% select(codmun),
                               year = y,
                               month = m,
                               prcp = sapply(ext, sum, na.rm=T)
                               )
                     )
    
  }
  
  saveRDS(prcp %>%
            mutate(codmun = as.numeric(codmun)) %>%
            filter(year >= 2017 & year <= 2024) %>%
            group_by(codmun, year) %>%
            summarise(prcp = mean(prcp)) %>%
            ungroup() %>% arrange(codmun, year),
          "../data/processed/prcp.RDS")
  rm(prcp, tif, ext, bbox, f, files, m , y, sum_coverage)

} # 6. MAX TEMPERATURE AND PRECIPITATION (END)


{ # 7. MORTALITY RATES ####
  
  mun = amz %>% select(codmun, pop) %>%
    mutate(codmun6 = as.numeric(substr(codmun, 1, 6))) %>%
    st_drop_geometry()
  
  deaths = tibble()
  files = c("Mortalidade_Geral_2017_csv.zip", "Mortalidade_Geral_2018_csv.zip",
            "Mortalidade_Geral_2019_csv.zip", "Mortalidade_Geral_2020_csv.zip",
            "Mortalidade_Geral_2021_csv.zip", "DO22OPEN.csv", "DO23OPEN.csv",
            "DO24OPEN_csv.zip")
  
  for (file in files) {
    if (substr(file, nchar(file)-2, nchar(file)) == "zip") {
      aux = read_csv2(unz(paste0("../data/deaths/", file), 
                          gsub("_(?=[^_]*$)", ".", gsub("\\.zip$", "", file), perl = TRUE)))
    } else {
      aux = read_csv2(paste0("../data/deaths/", file))
    }
    
    aux = aux %>%
      mutate(year = as.numeric(substr(DTOBITO, 5, 8)),
             month = as.numeric(substr(DTOBITO, 3, 4)),
             cid = toupper(CAUSABAS),
             cid_l = substr(cid, 1, 1),
             cid_n = as.numeric(substr(cid, 2, 3)),
             hom = ((cid_l == "X" & cid_n >= 85) |
                      (cid_l == "Y" & cid_n <= 9) |
                      (cid_l == "Y" & cid_n %in% c(35,36))) * 1,
             hom_fa = (cid_l == "X" & cid_n %in% 93:95) * 1,
             type = case_when( # http://tabnet.datasus.gov.br/cgi/sih/mxcid10lm.htm
               cid_l == "A" | cid_l == "B" ~ "infect",
               cid_l == "C" | (cid_l == "D" & cid_n <= 48) ~ "neoplasm",
               cid_l == "D" & cid_n >= 49 ~ "blood",
               cid_l == "E" ~ "endocrine",
               cid_l == "F" ~ "mental",
               cid_l == "G" ~ "nervous",
               cid_l == "H" & cid_n <= 59 ~ "eyes",
               cid_l == "H" & cid_n >= 60 ~ "ears",
               cid_l == "I" ~ "circulatory",
               cid_l == "J" | (cid_l == "U" & cid_n == 4) ~ "respiratory",
               cid_l == "K" ~ "digestive",
               cid_l == "L" ~ "skin",
               cid_l == "M" ~ "musculoskeletal",
               cid_l == "N" ~ "genitourinary",
               cid_l == "O" ~ "pregnancy",
               cid_l == "P" ~ "perinatal",
               cid_l == "Q" ~ "malformation",
               cid_l == "R" ~ "other",
               cid_l %in% c("S", "T", "V", "W", "X", "Y") ~ "extcause",
               cid_l == "Z" | cid_l == "U" ~ "other",
               )
             ) %>%
      rename(codmun6 = CODMUNOCOR) %>%
      left_join(mun , by = "codmun6")
    
    deaths = bind_rows(deaths,
                       # Total Deaths
                       aux %>% mutate(type = "total") %>%
                         group_by(codmun, year, month, type) %>%
                         summarise(qty = n()) %>% ungroup(),
                       # Deaths by ICD
                       aux %>% group_by(codmun, year, month, type) %>%
                         summarise(qty = n()) %>% ungroup(),
                       # Homicides
                       aux %>% group_by(codmun, year, month) %>%
                         summarise(hom = sum(hom, na.rm = T),
                                   hom_fa = sum(hom_fa, na.rm = T)) %>%
                         ungroup() %>%
                         pivot_longer(cols = c("hom", "hom_fa"),
                                      names_to = "type", values_to = "qty")
                       )
    
  }
  
  saveRDS(mun %>%
            merge(2017:2024) %>% rename(year = y) %>%
            left_join(deaths, by = c("codmun", "year")) %>% 
            mutate(qty = qty / (pop / 1e5)) %>%
            filter(!is.na(codmun) & !is.na(type)) %>%
            group_by(codmun, year, type) %>%
            summarise(qty = sum(qty)) %>% 
            ungroup() %>%
            pivot_wider(names_from = "type", names_prefix = "mort_", 
                        values_from = "qty", values_fill = 0) %>%
            rename(hom = mort_hom, hom_fa = mort_hom_fa) %>%
            select(codmun, year, mort_total, starts_with("mort_"), hom, hom_fa),
          "../data/processed/deaths.RDS")
  
  rm(deaths, aux, mun)
    
} # 7. MORTALITY RATES (END)


{ # 8. FOREST COVER AND TRANSITIONS ####
  
  # Municipalities shapefile
  mun = amz %>% st_transform(4326) %>% st_make_valid()
    
  # Bounding box with buffer (degrees, MapBiomas' CRS 4326)
  bbox = st_bbox(mun) + c(-.5, -.5, .5, .5)
  
  
  # MapBiomas land cover files
  period = 2016:2024
  flist = list.files("../data/mapbiomas", 
                      pattern = "^brazil_coverage.*\\.tif$", full.names = T)
  flist = flist[str_detect(flist, pattern = paste(period, collapse = "|"))]
  
  # Function to calculate the forest cover transitions
  raster_trans = function(raster_ini, raster_end, poly) {

    forest_classes = c(1, 3, 4, 5, 6, 49)
    natural_nonforest = c(10,11,12,32,29,50,13)
    agriculture_pec = c(15)
    agriculture_agr = c(18,19,39,20,40,62,41,36,46,47,35,48)
    agriculture_out = c(14,9,21)
    nonveg_min = c(30)
    nonveg_urb = c(24)
    nonveg_out = c(22,23,25,75)
    water = c(26,33,31)
    
    make_transitions = function(from, to, label) {
      expand.grid(from = from, to = to) %>%
        mutate(code = from * 100 + to,
               category = label)
      }
    
    transition_table = bind_rows(
      make_transitions(forest_classes, forest_classes, "sh_flo"),
      make_transitions(forest_classes, natural_nonforest, "sh_veg"),
      make_transitions(forest_classes, agriculture_pec, "sh_agr_pec"),
      make_transitions(forest_classes, agriculture_agr, "sh_agr_agr"),
      make_transitions(forest_classes, agriculture_out, "sh_agr_out"),
      make_transitions(forest_classes, nonveg_min, "sh_nvg_min"),
      make_transitions(forest_classes, nonveg_urb, "sh_nvg_urb"),
      make_transitions(forest_classes, nonveg_out, "sh_nvg_out"),
      make_transitions(forest_classes, water, "sh_nvg_agu")
    ) %>%
      distinct(code, category) %>%
      mutate(cat_id = as.integer(factor(category)))
    
    rm(forest_classes,natural_nonforest,
       agriculture_pec,agriculture_agr,agriculture_out,
       nonveg_min,nonveg_urb,nonveg_out,
       water)
    
    # Matriz de reclassificação
    reclass_mat = as.matrix(transition_table[, c("code", "cat_id")])
    # rm(transition_table)
    
    # Raster de transição
    transition_raster = raster_ini * 100 + raster_end
    
    # Reclassificando o raster
    transition_category_raster = classify(transition_raster, rcl = reclass_mat, others = NA)
    
    result = exact_extract(transition_category_raster, poly,
                           fun = function(values, cov) {
                             tab = table(values)
                             as.list(tab)},
                           max_cells_in_memory = 3e+10)


    df = tibble(id = seq_along(result), values = result) %>%
      unnest_wider(values, names_sep = "_")

    for(k in 1:9){
      if(!(paste0("values_",k) %in% names(df))){
        nomes = names(df)
        df$v = rep(0,times = nrow(df))
        nomes = c(nomes,paste0("values_",k))
        names(df) = nomes
        rm(nomes)
      }
      rm(k)
    }

    df = df %>%
      relocate(id,
               values_1,
               values_2,
               values_3,
               values_4,
               values_5,
               values_6,
               values_7,
               values_8,
               values_9) %>%
      rename(
        sh_agr_agr = 2,
        sh_agr_out = 3,
        sh_agr_pec = 4,
        sh_flo = 5,
        sh_nvg_agu = 6,
        sh_nvg_min = 7,
        sh_nvg_out = 8,
        sh_nvg_urb = 9,
        sh_veg = 10
      ) %>%
      mutate(
        sh_agr_agr = ifelse(is.na(sh_agr_agr),0,sh_agr_agr),
        sh_agr_out = ifelse(is.na(sh_agr_out),0,sh_agr_out),
        sh_agr_pec = ifelse(is.na(sh_agr_pec),0,sh_agr_pec),
        sh_flo = ifelse(is.na(sh_flo),0,sh_flo),
        sh_nvg_agu = ifelse(is.na(sh_nvg_agu),0,sh_nvg_agu),
        sh_nvg_min = ifelse(is.na(sh_nvg_min),0,sh_nvg_min),
        sh_nvg_out = ifelse(is.na(sh_nvg_out),0,sh_nvg_out),
        sh_nvg_urb = ifelse(is.na(sh_nvg_urb),0,sh_nvg_urb),
        sh_veg = ifelse(is.na(sh_veg),0,sh_veg),
        sh_tot = sh_agr_agr + sh_agr_out + sh_agr_pec + sh_flo + sh_nvg_agu +
          sh_nvg_min + sh_nvg_out + sh_nvg_urb + sh_veg,
        
        sh_agr_agr = sh_agr_agr / sh_tot,
        sh_agr_pec = sh_agr_pec / sh_tot,
        sh_agr_out = sh_agr_out / sh_tot,
        sh_flo = sh_flo / sh_tot,
        sh_nvg_agu = sh_nvg_agu / sh_tot,
        sh_nvg_min = sh_nvg_min / sh_tot,
        sh_nvg_out = sh_nvg_out / sh_tot,
        sh_nvg_urb = sh_nvg_urb / sh_tot,
        sh_veg = sh_veg / sh_tot
      ) %>%
      dplyr::select(-sh_tot)
    
    df = poly %>%
      dplyr::select(codmun) %>%
      bind_cols(df) %>%
      st_drop_geometry() %>%
      select(-id)
    
    return(df)
  }
  
  # Loading rasters
  mblist = list()
  j = 1
  for (ano in period) {
    mblist[[j]] = rast(x = flist[grepl(ano,flist)])
    j = j + 1
  }
  
  uflist = sort(unique(substr(mun$codmun, 1, 2)))
  
  # i=9
  for (i in 1:length(uflist)) {
    
    print(paste0("Forest transition | State ", i,"/",length(uflist)))
    
    # Selecting all state municipalities
    temp_mun = mun[substr(mun$codmun,1,2) == uflist[i],]
    bbox = st_bbox(temp_mun) + c(-.5, -.5, .5, .5)
    
    # Cutting annual rasters to state shape
    temp_stack = lapply(mblist,
                         function(r) { mask(crop(r, bbox), temp_mun) }
                         )
    
    # Transition from forest to another land cover and use
    temp = data.frame()
    for (j in 1:(length(mblist)-1)) {
      aux = raster_trans(raster_ini = temp_stack[[j]],
                         raster_end = temp_stack[[j+1]],
                         poly = temp_mun) %>% 
        mutate(year = period[j+1])
      temp = rbind(temp, aux)
      }
    
    # Saving partial extraction by state/UF
    saveRDS(temp, paste0("../data/processed/mb_trans_", uflist[i], "_",
                         period[1], "-", period[length(period)], ".RDS"))
    
    rm(temp_mun, i, temp)
    
  }
  
  # Consolidating in one dataframe
  list_mb = list.files("../data/processed", "^mb_trans", full.names = T)
  mbtrans = data.frame()
  
  for (mb in list_mb) {
    aux = readRDS(mb)
    mbtrans = rbind(mbtrans, aux)
  }
  
  saveRDS(
    mbtrans %>%
      select(codmun, year, everything()) %>%
      arrange(codmun, year),
    "../data/processed/mbtrans.RDS"
  )
 
  rm(mbtrans, aux, list_mb, mb)
  
  # # # # # # # # #
  
  ## Calculate forest area as share of municipal area
  mblist = lapply(flist, rast)
  mun$uf = substr(mun$codmun, 1, 2)
  uflist = unique(mun$uf)
  
  # Prepare results list
  results_list = list()
  
  for (ufi in uflist) {
    print(paste0("Forest proportion | State/UF: ", ufi))
    
    # Selecting State/UF
    temp_mun = mun %>% filter(uf == ufi)
    bbox = st_bbox(temp_mun) + c(-.5, -.5, .5, .5)
    
    
    # Cutting rasters by state/UF
    temp_stack = lapply(mblist, function(r) {
      mask(crop(r, bbox), temp_mun)
    })
    
    # Forest
    s1 = lapply(temp_stack, FUN = function(x) {
      exact_extract(x, temp_mun, function(values, coverage_fraction)
        sum(values %in% c(1,3,4,5,6,49)), max_cells_in_memory = 3e+09)
      })
    
    s1 = as.data.frame(s1)
    colnames(s1) = paste0("area_floresta", period)
    
    # Total area
    st = lapply(temp_stack, FUN = function(x) {
      exact_extract(x, temp_mun, function(values, coverage_fraction)
        sum(!is.na(values)), max_cells_in_memory = 3e+09)
      })
    
    st = as.data.frame(st)
    colnames(st) = paste0("area_total", period)
    
    
    temp_base = temp_mun %>%
      st_drop_geometry() %>%
      dplyr::select(codmun) %>%
      bind_cols(s1) %>%
      bind_cols(st) 
    
    # Storing results
    results_list[[ufi]] = temp_base
    
    rm(ufi, temp_mun, s1, st, temp_base)
    
  }
  
  df_area = data.table::rbindlist(results_list, use.names = T, fill = T) %>%
    data.table::melt(measure = list(paste0("area_floresta", period), 
                        paste0("area_total", period)),
         value.name = c("area_floresta", "area_total")) %>%
    mutate(
      year = as.numeric(variable) + min(period) - 1,
      p_forest = area_floresta / area_total
    ) %>%
    select(-variable)
  
  # Salvando dados
  saveRDS(df_area, "../data/processed/mb_forest.RDS")
  
  rm(mblist, mun, temp_stack, results_list, df_area, bbox, flist, j, period, 
     ano, uflist, raster_trans)
} # 8. FOREST COVER AND TRANSITIONS (END)


{ # 9. POTENTIAL SOY YIELD ####
  # Soy dataset from FAO-GAEZ v5 (historical 2001-2020)

  sum_yield = function(x){
    list(x %>%
           mutate(total_area = sum(coverage_area, na.rm=T),
                  proportion = coverage_area / total_area,
                  yield = value * proportion, # yield (prod / ha)
                  ) %>% select(yield)
         )
    }
  
  soy = tibble(amz %>% st_drop_geometry()) %>% select(codmun)
  
  tif = rast("../data/DATA_GAEZ-V5_MAPSET_RES05-YXX_GAEZ-V5.RES05-YXX.HP0120.AGERA5.HIST.SOY.HRLM.tif") %>%
    project(proj_wk)
  ext = exact_extract(tif, amz, coverage_area = T,
                      summarize_df = T, fun = sum_yield)
  
  soy = bind_cols(soy, sapply(ext, sum, na.rm=TRUE))
  colnames(soy)[2] = "soyield_ful_mun_high"

  saveRDS(soy, "../data/processed/soy_potential.RDS")
  rm(soy, ext, tif, sum_yield)
  
} # 9. POTENTIAL SOY YIELD (END) 



## 10. JOINING DATASETS # # # # # # # # # # # # # # # # # # # # # # # # # # ####
haven::write_dta(
  readRDS("../data/processed/munic.RDS") %>% 
    left_join(readRDS("../data/processed/mb_forest.RDS") %>% 
                filter(year == 2021) %>% 
                select(codmun, p_forest), 
              by = "codmun") %>% 
    mutate(areaforest = areamun * p_forest) %>%
    left_join(readRDS("../data/processed/soy_potential.RDS"),
              by = "codmun") %>%
    left_join(readRDS("../data/processed/starlink.RDS"), 
              by = c("codmun", "year")) %>% 
    left_join(readRDS("../data/processed/geosat.RDS"), 
              by = c("codmun", "year")) %>% 
    left_join(readRDS("../data/processed/deter.RDS"),
              by = c("codmun", "year")) %>% 
    left_join(readRDS("../data/processed/police.RDS"),
              by = c("codmun", "year")) %>% 
    left_join(readRDS("../data/processed/pm_cams.RDS"),
              by = c("codmun", "year")) %>% 
    left_join(readRDS("../data/processed/tmax.RDS"),
              by = c("codmun", "year")) %>%
    left_join(readRDS("../data/processed/prcp.RDS"),
              by = c("codmun", "year")) %>% 
    left_join(readRDS("../data/processed/deaths.RDS"),
              by = c("codmun", "year")) %>%
    left_join(readRDS("../data/processed/mbtrans.RDS"),
              by = c("codmun", "year")) %>%
    mutate(reg_sample = ifelse(year > 2021, 1, 0)) %>%
    arrange(codmun, year),
  "../data/processed/analytical_dataset.dta")
