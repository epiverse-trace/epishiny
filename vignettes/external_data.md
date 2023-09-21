Using epishiny with your own data set
================
Sebastian Funk
2023-09-21

The *epishiny* package works with line lists, i.e. data sets in the form
of tables that contain cases as one line per individual. The package
provides a range of visualisations of different aggregations of the data
and displays them on a shiny dashboard that can be deployed on a server.

# Load in data

The package comes with a range of example line lists, but a user can
also bring their own data. Here we will use a line list of Ebola in
Sierra Leone published in Fang et al. ([2016](#ref-Fang2016)).

``` r
library("readr")
url <- paste(
  "https://raw.githubusercontent.com/parksw3/epidist-paper/main/data-raw/",
  "pnas.1518587113.sd02.csv", 
  sep = "/"
)
df <- read_csv(url)
#> Rows: 8358 Columns: 8
#> ── Column specification ──────────────────────────────────────────────────────────────────────────
#> Delimiter: ","
#> chr (6): Name, Sex, Date of symptom onset, Date of sample tested, District, ...
#> dbl (2): ID, Age
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
head(df)
#> # A tibble: 6 × 8
#>      ID Name    Age Sex   Date of symptom onse…¹ Date of sample teste…² District
#>   <dbl> <chr> <dbl> <chr> <chr>                  <chr>                  <chr>   
#> 1     1 *****    20 F     18-May-14              23-May-14              Kailahun
#> 2     2 *****    42 F     20-May-14              25-May-14              Kailahun
#> 3     3 *****    45 F     20-May-14              25-May-14              Kailahun
#> 4     4 *****    15 F     21-May-14              26-May-14              Kailahun
#> 5     5 *****    19 F     21-May-14              26-May-14              Kailahun
#> 6     6 *****    55 F     21-May-14              26-May-14              Kailahun
#> # ℹ abbreviated names: ¹​`Date of symptom onset`, ²​`Date of sample tested`
#> # ℹ 1 more variable: Chiefdom <chr>
```

# Set up geo data

We next need geological data if we want to show maps. Unfortunately
there is no systematic availability of subnational data. A search on the
HDX platform reveals that subnational data are available at
<https://data.humdata.org/dataset/cod-ab-sle>

The line list contains Districts (admin 2 level) and Governorates (admin
3 level). We can download the corresponding data sets from HDX.

``` r
## load required libraries
library("purrr")
library("sf")
#> Linking to GEOS 3.11.0, GDAL 3.5.3, PROJ 9.1.0; sf_use_s2() is TRUE

## common element of both shapefile URLs
hdx_dir <-
  "https://data.humdata.org/dataset/a4816317-a913-4619-b1e9-d89e21c056b4"
## shapefile names and resource ID (from URL)
shapefiles <- list(
  adm2 = list(
    filename = "sle_admbnda_adm2_1m_gov_ocha.zip",
    resource = "b3963917-8550-478d-9363-736492bf209a"
  ),
  adm3 = list(
    filename = "sle_admbnda_adm3_1m_gov_ocha_20161017.zip", 
    resource = "e2aa661d-af2f-42d8-bdea-c7e16a00bdb2"
  )
)
## create temporary dir for downloading
tmpdir <- tempdir()

## download and load shapefiles
shapes <- map(shapefiles, \(x) {
  ## construct URL
  url <- paste(
    hdx_dir, "resource", x$resource, "download", x$filename, sep = "/"
  )
  ## construct file name
  ## (`read_sf` expects ending `.shp.zip` for zipped shapefiles)
  destfile <- sub("\\.zip$", ".shp.zip", file.path(tmpdir, x$filename))
  download.file(url, destfile = destfile)
  return(read_sf(destfile))
})

map(shapes, head)
#> $adm2
#> Simple feature collection with 6 features and 15 fields
#> Geometry type: MULTIPOLYGON
#> Dimension:     XY
#> Bounding box:  xmin: -13.30901 ymin: 6.923379 xmax: -10.27056 ymax: 9.608103
#> Geodetic CRS:  WGS 84
#> # A tibble: 6 × 16
#>   OBJECTID admin2Name admin2Pcod admin2RefN admin2AltN admin2Al_1 admin1Name
#>      <dbl> <chr>      <chr>      <chr>      <chr>      <chr>      <chr>     
#> 1        1 Pujehun    SL0304     Pujehun    <NA>       <NA>       Southern  
#> 2        2 Port Loko  SL0204     Port Loko  <NA>       <NA>       Northern  
#> 3        3 Bonthe     SL0302     Bonthe     <NA>       <NA>       Southern  
#> 4        4 Bo         SL0301     Bo         <NA>       <NA>       Southern  
#> 5        5 Kambia     SL0202     Kambia     <NA>       <NA>       Northern  
#> 6        6 Kailahun   SL0101     Kailahun   <NA>       <NA>       Eastern   
#> # ℹ 9 more variables: admin1Pcod <chr>, admin0Name <chr>, admin0Pcod <chr>,
#> #   date <date>, validOn <date>, ValidTo <date>, Shape_Leng <dbl>,
#> #   Shape_Area <dbl>, geometry <MULTIPOLYGON [°]>
#> 
#> $adm3
#> Simple feature collection with 6 features and 19 fields
#> Geometry type: MULTIPOLYGON
#> Dimension:     XY
#> Bounding box:  xmin: -13.13473 ymin: 6.96633 xmax: -11.45532 ymax: 9.032242
#> Geodetic CRS:  WGS 84
#> # A tibble: 6 × 20
#>   OBJECTID admin3Name     admin3Pcod admin3RefN admin2Name admin2Pcod admin1Name
#>      <dbl> <chr>          <chr>      <chr>      <chr>      <chr>      <chr>     
#> 1        1 Yakemu Kpukumu SL030412   Yakemu Kp… Pujehun    SL0304     Southern  
#> 2        2 Koya           SL020412   Koya       Port Loko  SL0204     Northern  
#> 3        3 Bureh Kasseh … SL020401   Bureh Kas… Port Loko  SL0204     Northern  
#> 4        4 Panga Kabonde  SL030404   Panga Kab… Pujehun    SL0304     Southern  
#> 5        5 Galliness Per… SL030402   Galliness… Pujehun    SL0304     Southern  
#> 6        6 Kpaka          SL030403   Kpaka      Pujehun    SL0304     Southern  
#> # ℹ 13 more variables: admin1Pcod <chr>, admin0Name <chr>, admin0Pcod <chr>,
#> #   date <date>, validOn <date>, validTo <date>, Shape_Leng <dbl>,
#> #   Shape_Area <dbl>, Rowcacode0 <chr>, Rowcacode1 <chr>, Rowcacode2 <chr>,
#> #   Rowcacode3 <chr>, geometry <MULTIPOLYGON [°]>
```

The *epishiny* package takes shapefiles that associate each region with
a geographical point as latitude (`lat`) and longitude (`lon`). The
files we downloaded do not contain this information. We add the
centroids of each area using the routines contained in the `sf` package.

``` r
library("dplyr")
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
shapes <- map(shapes, \(x) {
  coords <- x |>
    st_centroid() |>
    st_coordinates() |>
    as_tibble() |>
    rename(lon = X, lat = Y)
  return(cbind(x, coords))
})
#> Warning: st_centroid assumes attributes are constant over geometries

#> Warning: st_centroid assumes attributes are constant over geometries
```

# Modules

Before we launch the modules we can define some grouping variables. In
our example we use sex and district as a variable:

``` r
group_vars <- c(Sex = "Sex", "District" = "District")
```

## Place module

Now that we have the shapefiles we can collate the information contained
in the format that *epishiny* expects:

``` r
geo_data <- list(
  "adm2" = list(
    level_name = "District",
    sf = shapes$adm2, 
    name_var = "admin2Name",
    join_by = c("admin2Name" = "District")
  ),
  "adm3" = list(
    level_name = "Governorate",
    sf = shapes$adm3,
    name_var = "admin3Name",
    join_by = c("admin3Name" = "Governorate")
  )
)
```

We use this to launch the place module:

``` r
launch_module(
  module = "place",
  df_ll = df,
  geo_data = geo_data,
  group_vars = group_vars
)
```

## Time module

To launch the time module, we need to define the date variables in the
line list. In our case we use the already quite descriptive column names
of the data.

``` r
date_vars <- c(
  `Date of symptom onset` = "Date of symptom onset",
  `Date of sample tested` = "Date of sample tested"
)
```

We use this to launch the time module:

``` r
launch_module(
  module = "time",
  df_ll = df,
  date_vars = date_vars,
  group_vars = group_vars
)
```

## Person module

We can plot an age/sex pyramid using the person module

``` r
launch_module(
  module = "person",
  df_ll = df,
  age_var = "Age",
  sex_var = "Sex",
  male_level = "M",
  female_level = "F"
)
```

# References

<div id="refs" class="references csl-bib-body hanging-indent">

<div id="ref-Fang2016" class="csl-entry">

Fang, Li-Qun, Yang Yang, Jia-Fu Jiang, Hong-Wu Yao, David Kargbo,
Xin-Lou Li, Bao-Gui Jiang, et al. 2016. “Transmission Dynamics of Ebola
Virus Disease and Intervention Effectiveness in Sierra Leone.”
*Proceedings of the National Academy of Sciences* 113 (16): 4488–93.
<https://doi.org/10.1073/pnas.1518587113>.

</div>

</div>
