# ktpi

Kernel Topographic Position Indice (ktpi) is a R based utility to classify topography based on elevation statistics, terrain indices and topographic position indices from DEM (digital elevation model) data. This is based on the work of Jones, K. Bruce et al 2000; Weiss 2001; Moore, I.D. et. al., 1993; Stage and Salas, 2007; and Wilson and Gallant, 2005 in Terrain Analysis: Principles and Applications.

## Setting up ktpi with docker
This tool has been prepared to run in a docker container. The following steps will help get started. Once you have a ktpi setup with docker, you can drop into a ktpi-ready environment at any time with the run command (step 3).

1. Install Docker (see tesera wiki? wip? same steps from mrat).
2. Load the docker environment. `eval "$(docker-machine env dev)"`
3. Build the ktpi docker image: `docker build --rm -t ktpi .`.
4. Run the ktpi docker image: `docker run -v $PWD:/opt/ktpi -t -i ktpi`.
5. At this point you should be in a docker container able to run all ktpi commands (wip). Typing `exit` will leave the container, and you can jump back in again with step 3.

## Dependencies

#### System dependencies
* [R](http://www.r-project.org/)
* [gdal](http://www.gdal.org/)
* [geos](http://geos.osgeo.org)

#### R package dependencies
* [sp](http://cran.r-project.org/web/packages/sp/index.html)
* [raster](http://cran.r-project.org/web/packages/raster/index.html)
* [rgdal](http://cran.r-project.org/web/packages/rgdal/index.html)
* [rgeos](http://cran.r-project.org/web/packages/rgeos/index.html)
* [docopt](http://cran.r-project.org/web/packages/docopt/index.html)
* [testthat](http://cran.r-project.org/web/packages/testthat/index.html)


## Usage

````
# basic command passing in minimal args
# 1. calculates metrics (statistic/terrain/ktpi/kasp...) for the dem raster tile (dem.tif) in the ./dems folder
# 2. summarizes metrics for each unique feature in a given feature raster tile (feature.tif)
# 3. writes metrics per feature to a text file (.csv) in the ./output folder

$ ./ktpi.R statistic ./features/3/4.tif ./dems/ ./output --dem-calc-size=5
$ ./ktpi.R terrain ./features/3/4.tif ./dems/ ./output -d 10 --exp-rast
$ ./ktpi.R ktpi ./features/3/4.tif ./dems/ ./output -d 20 --kernel-size=2000
$ ./ktpi.R kaspSDir ./features/3/4.tif ./dems/ ./output -d 10 -k 500 -o across
$ ./ktpi.R kaspSlpLnEleSlpSDir ./features/3/4.tif ./dems/ ./output -d 20 -k 2000 -o uphill -x
    
````

## What data can I get out of ktpi?

Metrics of topography are calculated for raster representations of polygon feature data. Calculations are performed over a digital elevation model with various cell moving window kernel using raster focal analysis, the calculations are then summarized using raster zonal analysis to each raster polygon feature by unique numeric value.

1. DEM statistic indices are calculated using the R raster package zonal function (minimum, maximum, mean, standard deviation of elevation values) for each feature.

2. DEM terrain indices are calculated using the R raster package terrain function (aspect, roughness, slope, TPI, and TRI) which implements an 8 cell kernel focal analysis, then summarizes the indices (mean) using raster zonal analysis to each raster polygon feature by unique numeric value. The terrain function implementation of flowdir was not used as the function has a built in randomization when flow direction has multiple possibilities, and the 2^n directions cannot be summarized/averaged.

3. DEM kernel topographic position indices are calculated using the R raster package focal function (mean, standard deviation) which implements variable cell kernel using raster focal analysis, then summarizes the indices (mean) using raster zonal analysis to each raster feature with unique numeric value.

4. DEM kernel aspect indices (Al Stage aspect slope, direction and elevation interactions) are calculated using the R raster package focal function which implements variable cell kernel ring raster focal analysis, then summarizes the indices (mean) using raster zonal analysis to each raster feature with unique numeric value.


## Input Data Requirements

The following outlines the process for structuring the input data properly for developing the terrain metrics.

* **Data Coordinate System**: All data must be in a UTM grid coordinate system, units in metres.
* **Project Area**: Build a project area polygon containing the project area plus sufficient area beyond equal to the largest focal kernel, ie. 2000m, to eliminate edge effect.
* **Tile Structure**: Develop a uniform size tile based on the [OSGEO Tile Map Service (TMS)](http://wiki.osgeo.org/wiki/Tile_Map_Service_Specification) specification, the tile structure should be established at the beginning as a function of the project area. http://server/services/service-name/(zoom-level)/x-coord/y-coord.tif
* **DEM raster**: Collect DEM raster data over the entire region, ie. 1m, 2m, 5m, or 10m. DEM data will automatically be aggregated for larger dem cell calculations.
* **DEM raster tiling**: Restructure the DEM raster data to the tile structure.
* **Feature polygon**: Polygon features with unique integer identifier.
* **Feature raster**: Corresponding raster format of the feature polygon with the raster cell value as its unique integer identifier (feature raster cells must coincide with DEM raster).
* **Feature raster tiling**: Restructure the feature unit data to the tile structure.


## Data Output

The following is a list of the *output indice values* summarized for each feature entity in a [tile] for a given [dem_cell_size] and [kernel_size]: ./output/[tile].csv

#### DEM statistic indices:
* **tr_st_min_[dem_cell_size]**: minimum elevation within the feature for that DEM raster cell size
* **tr_st_max_[dem_cell_size]**: maximum elevation within the feature for that DEM raster cell size
* **tr_st_mean_[dem_cell_size]**: mean elevation within the feature for that DEM raster cell size
* **tr_st_sd_[dem_cell_size]**: standard deviation of elevation values within the feature for that DEM raster cell size

#### DEM terrain indices:
* **tr_te_tri_[dem_cell_size]**: Terrain Roughness Index within the feature for that DEM raster cell size
* **tr_te_tpi_[dem_cell_size]**: Topographic Position Index within the feature for that DEM raster cell size
* **tr_te_roughness_[dem_cell_size]**: roughness within the feature for that DEM raster cell size
* **tr_te_slope_[dem_cell_size]**: slope within the feature for that DEM raster cell size
* **tr_te_aspect_[dem_cell_size]**: aspect within the feature for that DEM raster cell size

#### DEM topographic position indices:
* **tr_tp_[dem_cell_size]m_[kernel_size]m_[kernel_cells]_mean_diff**: the mean, of the difference in elevation values between each cell and the mean elevation of the kernel cells, of each cell within the feature for that kernel size and that DEM raster cell size
* **tr_tp_[dem_cell_size]m_[kernel_size]m_[kernel_cells]_sd**: the mean, of the standard deviation of elevation values of the kernel cells, of each cell within the feature for that kernel size and that DEM raster cell size

#### DEM kernel aspect indices:
* **tr_ka_[dem_cell_size]m_[kernel_size]m_[kernel_cells]_[kasp_function]_[orientation]**: the kasp aspect interactions as a function of slope, direction and/or elevation, of each cell within the feature for that kernel size and that DEM raster cell size

The following is a list of the *output raster files* for a [tile] for a given [dem_cell_size] and [kernel_size]:

#### DEM statistic indice rasters:
* **./output/tr_st/max/[dem_cell_size]/[tile].tif**
* **./output/tr_st/mean/[dem_cell_size]/[tile].tif**
* **./output/tr_st/min/[dem_cell_size]/[tile].tif**
* **./output/tr_st/sd/[dem_cell_size]/[tile].tif**

#### DEM terrain indice rasters:
* **./output/tr_te/aspect/[dem_cell_size]/[tile].tif**
* **./output/tr_te/ktpiflowdir9/[dem_cell_size]/[tile].tif**
* **./output/tr_te/roughness/[dem_cell_size]/[tile].tif**
* **./output/tr_te/slope/[dem_cell_size]/[tile].tif**
* **./output/tr_te/tpi/[dem_cell_size]/[tile].tif**
* **./output/tr_te/tri/[dem_cell_size]/[tile].tif**

#### DEM kernel topographic indice rasters:
* **./output/tr_tp/mean_diff/[dem_cell_size]/[kernel_size]/[tile].tif**
* **./output/tr_tp/sd/[dem_cell_size]/[kernel_size]/[tile].tif**

#### DEM kernel aspect indice rasters:
* **./output/tr_ka/[kasp_function]/[dem_cell_size]/[kernel_size]/[orientation]/[tile].tif**


## Scaled indice generation

Performing indice generation over a large area, over multiple [dem_cell_size] and over a range of [kernel_size] requires running the tool many times, for example all indices on one tile:6/7, one dem cell size:18, two kernel sizes:200&1600, and the three kasp orientations:across,uphill,downhill the following CLI commands are required:

````
./ktpi.r statistic ./input/features/6/7.tif ./input/dems ./output -d 18 -x
./ktpi.r terrain ./input/features/6/7.tif ./input/dems ./output -d 18 -x

./ktpi.r ktpi ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -x
./ktpi.r ktpi ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -x

./ktpi.r kaspSlp ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o across -x
./ktpi.r kaspSlp ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o uphill -x
./ktpi.r kaspSlp ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o downhill -x
./ktpi.r kaspSlp ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o across -x
./ktpi.r kaspSlp ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o uphill -x
./ktpi.r kaspSlp ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o downhill -x

./ktpi.r kaspDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o across -x
./ktpi.r kaspDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o uphill -x
./ktpi.r kaspDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o downhill -x
./ktpi.r kaspDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o across -x
./ktpi.r kaspDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o uphill -x
./ktpi.r kaspDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o downhill -x

./ktpi.r kaspSDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o across -x
./ktpi.r kaspSDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o uphill -x
./ktpi.r kaspSDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o downhill -x
./ktpi.r kaspSDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o across -x
./ktpi.r kaspSDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o uphill -x
./ktpi.r kaspSDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o downhill -x

./ktpi.r kaspCDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o across -x
./ktpi.r kaspCDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o uphill -x
./ktpi.r kaspCDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o downhill -x
./ktpi.r kaspCDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o across -x
./ktpi.r kaspCDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o uphill -x
./ktpi.r kaspCDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o downhill -x

./ktpi.r kaspSlpSDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o across -x
./ktpi.r kaspSlpSDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o uphill -x
./ktpi.r kaspSlpSDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o downhill -x
./ktpi.r kaspSlpSDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o across -x
./ktpi.r kaspSlpSDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o uphill -x
./ktpi.r kaspSlpSDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o downhill -x

./ktpi.r kaspSlpCDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o across -x
./ktpi.r kaspSlpCDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o uphill -x
./ktpi.r kaspSlpCDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o downhill -x
./ktpi.r kaspSlpCDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o across -x
./ktpi.r kaspSlpCDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o uphill -x
./ktpi.r kaspSlpCDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o downhill -x

./ktpi.r kaspSlpEle2 ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o across -x
./ktpi.r kaspSlpEle2 ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o uphill -x
./ktpi.r kaspSlpEle2 ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o downhill -x
./ktpi.r kaspSlpEle2 ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o across -x
./ktpi.r kaspSlpEle2 ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o uphill -x
./ktpi.r kaspSlpEle2 ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o downhill -x

./ktpi.r kaspSlpEle2SDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o across -x
./ktpi.r kaspSlpEle2SDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o uphill -x
./ktpi.r kaspSlpEle2SDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o downhill -x
./ktpi.r kaspSlpEle2SDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o across -x
./ktpi.r kaspSlpEle2SDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o uphill -x
./ktpi.r kaspSlpEle2SDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o downhill -x

./ktpi.r kaspSlpEle2CDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o across -x
./ktpi.r kaspSlpEle2CDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o uphill -x
./ktpi.r kaspSlpEle2CDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o downhill -x
./ktpi.r kaspSlpEle2CDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o across -x
./ktpi.r kaspSlpEle2CDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o uphill -x
./ktpi.r kaspSlpEle2CDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o downhill -x

./ktpi.r kaspSlpLnEle ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o across -x
./ktpi.r kaspSlpLnEle ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o uphill -x
./ktpi.r kaspSlpLnEle ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o downhill -x
./ktpi.r kaspSlpLnEle ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o across -x
./ktpi.r kaspSlpLnEle ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o uphill -x
./ktpi.r kaspSlpLnEle ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o downhill -x

./ktpi.r kaspSlpLnEleSlpSDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o across -x
./ktpi.r kaspSlpLnEleSlpSDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o uphill -x
./ktpi.r kaspSlpLnEleSlpSDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o downhill -x
./ktpi.r kaspSlpLnEleSlpSDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o across -x
./ktpi.r kaspSlpLnEleSlpSDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o uphill -x
./ktpi.r kaspSlpLnEleSlpSDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o downhill -x

./ktpi.r kaspSlpLnEleSlpCDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o across -x
./ktpi.r kaspSlpLnEleSlpCDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o uphill -x
./ktpi.r kaspSlpLnEleSlpCDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 200 -o downhill -x
./ktpi.r kaspSlpLnEleSlpCDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o across -x
./ktpi.r kaspSlpLnEleSlpCDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o uphill -x
./ktpi.r kaspSlpLnEleSlpCDir ./input/features/6/7.tif ./input/dems ./output -d 18 -k 1600 -o downhill -x
````

#### Scaled example input data:
* all indices: statistic, terrain, ktpi, and kasp
* 1600 tiles: 40x40 feature and DEM tiles @ 500x500 cells & 5m raster cell size
* 12M features: polygon features to which data is summarized
* 5 ktpi kernels: dem_cell_size @ 5m & kernel_size = 25m, 50m, 75m, 100m
* 5 ktpi kernels: dem_cell_size @ 10m & kernel_size = 100m, 150m, 200m, 250m, 300m
* 7 ktpi kernels: dem_cell_size @ 10m & kernel_size = 400m, 500m, 600m, 700m, 800m, 900m, 1000m
* 6 ktpi kernels: dem_cell_size @ 20m & kernel_size = 1000m, 1200m, 1400m, 1600m, 1800m, 2000m
* 5 kasp kernels @ 3 orientations: dem_cell_size @ 5m & kernel_size = 25m, 50m, 75m, 100m
* 5 kasp kernels @ 3 orientations: dem_cell_size @ 10m & kernel_size = 100m, 150m, 200m, 250m, 300m
* 7 kasp kernels @ 3 orientations: dem_cell_size @ 10m & kernel_size = 400m, 500m, 600m, 700m, 800m, 900m, 1000m
* 6 kasp kernels @ 3 orientations: dem_cell_size @ 20m & kernel_size = 1000m, 1200m, 1400m, 1600m, 1800m, 2000m

#### Scaled example commands:
* 1,312,000 CLI requests: [statistic @1600 tiles x 3 cell sizes[5,10,20]] + [terrain @1600 tiles x 3 cell sizes] + [ktpi @1600 tiles x 22 kernels (5 + 5 + 7 + 6)] + [12 kasp function @1600 tiles X 22 kernels X 3 orientations]

#### Scaled example output data:
* 1,312,000 CSV files: one CSV per CLI request
* 12M records with 866 attributes (12 statistic + 18 terrain + 44 ktpi + 792 kasp)

Besides the vast number of individual commands, spatial calculations of this magnitude require a scaled environment in which to calculate the topographic metrics as some can be rather computationally costly. This can be accomplished in a cluster computing environment allowing distribution of the data and calculations across a cluster of computing instances, and then aggregation of the data into a single database. Scaled indice generation service is available from [Tesera](http://tesera.com/), please contact [mkieser](https://github.com/mkieser).

The following is an example of the CLI command for getting the required data from a S3 bucket, calculating a single indice calculation (ktpi) on a single feature tile (3/4.tif), outputting a log file, and putting all the output data to a S3 bucket:
````
aws s3 cp s3://1604-tpi/test1/input/features/2/3.tif ./features/2/3.tif && aws s3 cp s3://1604-tpi/test1/input/dems/2/3.tif ./dems/2/3.tif &&aws s3 cp s3://1604-tpi/test1/input/features/2/4.tif ./features/2/4.tif && aws s3 cp s3://1604-tpi/test1/input/dems/2/4.tif ./dems/2/4.tif &&aws s3 cp s3://1604-tpi/test1/input/features/2/5.tif ./features/2/5.tif && aws s3 cp s3://1604-tpi/test1/input/dems/2/5.tif ./dems/2/5.tif &&aws s3 cp s3://1604-tpi/test1/input/features/3/3.tif ./features/3/3.tif && aws s3 cp s3://1604-tpi/test1/input/dems/3/3.tif ./dems/3/3.tif &&aws s3 cp s3://1604-tpi/test1/input/features/3/4.tif ./features/3/4.tif && aws s3 cp s3://1604-tpi/test1/input/dems/3/4.tif ./dems/3/4.tif &&aws s3 cp s3://1604-tpi/test1/input/features/3/5.tif ./features/3/5.tif && aws s3 cp s3://1604-tpi/test1/input/dems/3/5.tif ./dems/3/5.tif &&aws s3 cp s3://1604-tpi/test1/input/features/4/3.tif ./features/4/3.tif && aws s3 cp s3://1604-tpi/test1/input/dems/4/3.tif ./dems/4/3.tif &&aws s3 cp s3://1604-tpi/test1/input/features/4/4.tif ./features/4/4.tif && aws s3 cp s3://1604-tpi/test1/input/dems/4/4.tif ./dems/4/4.tif &&aws s3 cp s3://1604-tpi/test1/input/features/4/5.tif ./features/4/5.tif && aws s3 cp s3://1604-tpi/test1/input/dems/4/5.tif ./dems/4/5.tif && mkdir -p ./output && ./ktpi.R ktpi ./features/3/4.tif ./dems ./output -d 5 -k 25 -x &> ./output/3-4_tpii_5_25.txt && aws s3 sync ./output s3://1604-tpi/test1/output
````

## Recommended improvements
* vector tile output
* build a custom version of kptiflowdir9deg, averaging multi-directional, outputting directional degrees, using a 3x3 kernel.
* data checks:
  * check for large exponential values - requested IM: 20160203
  * raster indices:
    * min: >=0, <=8850m
    * max: >=0, >=8850m
    * mean: >=0, <=max, >=min
    * sd: >=0, <=max
  * terrain indices:
    * slope (slope and aspect are computed according to Horn (1981)): range -90 - 90
    * aspect (slope and aspect are computed according to Horn (1981)): range 0 - 360
    * TRI (mean of the absolute differences between the value of a cell and the value of its 8 surrounding cells): range 0 - [max-min]
    * TPI (difference between the value of a cell and the mean value of its 8 surrounding cells): range -[max-min] - [max-min]
    * roughness (difference between the value of a cell and the maximum and the minimum of its 8 surrounding cells): range -[max-min] - [max-min]
    * flowdir (the direction of the greatest drop in elevation (or the smallest rise if all kernel cells are higher), encoded as powers of 2 (0 to 7). The cell to the right of the focal cell ’x’ is 1, the one below that is 2, and so on): range 0 - 128  need to discuss with IM
  * kernel topographic position indices:
    * mean_diff (): range -[max-min] - [max-min]
    * sd (): >=0, <=max
  * kernel aspect:
    * slope: 0 - inf
    * direction: 0 - 360
    * sine direction: -1 - +1
    * cosine direction: -1 - +1
