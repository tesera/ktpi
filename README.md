# ktpi (Kernel Topographic Position Indice)

**TL/DR: KPTI creates multi-scale and multi-kernel terrain indices from digital elevation modle (DEM) data.  It can be used locally or in a more complex cluster configuration on Amazon Web Services for larger jobs.**


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
$ ./ktpi.R (statistic | terrain) <feature-file> <dem-folder> <output-folder> [-d|--dem-calc-size <dsize>] [-x|--exp-rast]
$ ./ktpi.R ktpi <feature-file> <dem-folder> <output-folder> [-d <dsize>] [-k|--kernel-size <ksize>] [-x|--exp-rast]
$ ./ktpi.R (kaspSlp | kaspDir | kaspSDir | kaspCDir | kaspSlpSDir | kaspSlpCDir | kaspSlpEle2 | kaspSlpEle2SDir | kaspSlpEle2CDir | kaspSlpLnEle | kaspSlpLnEleSlpSDir | kaspSlpLnEleSlpCDir) <feature-file> <dem-folder> <output-folder> [-d <dsize>] [-k|--kernel-size <ksize>] [-o|--orientation <orient>] [-x|--exp-rast]
# examples
$ ./ktpi.R statistic ./features/3/4.tif ./dems/ ./output --dem-calc-size=5
$ ./ktpi.R terrain ./features/3/4.tif ./dems/ ./output -d 10 --exp-rast
$ ./ktpi.R ktpi ./features/3/4.tif ./dems/ ./output -d 20 --kernel-size=2000
$ ./ktpi.R kaspSDir ./features/3/4.tif ./dems/ ./output -d 10 -k 500 -o across
$ ./ktpi.R kaspSlpLnEleSlpSDir ./features/3/4.tif ./dems/ ./output -d 20 -k 2000 -o uphill -x

# build CLI commands
$ ./ktpi.R ktpi-cli (--ktpi-function <ktpi-func>)... <feature-folder> <dem-folder> <output-folder> (--tile-col-min <cmin>) (--tile-col-max <cmax>) (--tile-row-min <rmin>) (--tile-row-max <rmax>) (--raster-cells <rcell>) (--raster-cell-size <csize>) (-d <dsize>... [-f <kfrom> -t <kto> -s <kstep>]...) [-o|--orientation <orient>...] [-x|--exp-rast] [-l|--limit-tiles <tiles-csv>]
#example    
$ ./ktpi.R ktpi-cli --ktpi-function statistic --ktpi-function terrain --ktpi-function ktpi --ktpi-function kaspSlp --ktpi-function kaspDir --ktpi-function kaspSDir --ktpi-function kaspCDir --ktpi-function kaspSlpSDir --ktpi-function kaspSlpCDir --ktpi-function kaspSlpEle2 --ktpi-function kaspSlpEle2SDir --ktpi-function kaspSlpEle2CDir --ktpi-function kaspSlpLnEle --ktpi-function kaspSlpLnEleSlpSDir --ktpi-function kaspSlpLnEleSlpCDir /Users/mk/Documents/Projects/sk-hris/plots /Users/mk/Documents/Projects/sk-hris/dems /Users/mk/Documents/Projects/sk-hris/output --tile-col-min 0 --tile-col-max 15 --tile-row-min 0 --tile-row-max 9 --raster-cells 600 --raster-cell-size 5 -d 5 -f 10 -t 20 -s 5 -d 5 -f 40 -t 100 -s 20 -d 10 -f 100 -t 200 -s 20 -d 10 -f 250 -t 500 -s 50 -d 10 -f 600 -t 1000 -s 100 -d 20 -f 1000 -t 2000 -s 200 -d 20 -f 2250 -t 2500 -s 250 -o across -o uphill -o downhill -l /Users/mk/Documents/Projects/sk-hris/plotsTiles.txt > /Users/mk/Documents/Projects/sk-hris/plotsCli.txt

# build SQS messages
$ ./ ktpi.R ktpi-sqs (--ktpi-feature <ktpi-feat>) (--ktpi-function <ktpi-func>)... (--tile-col-min <cmin>) (--tile-col-max <cmax>) (--tile-row-min <rmin>) (--tile-row-max <rmax>) (--raster-cells <rcell>) (--raster-cell-size <csize>) (-d <dsize>... [-f <kfrom> -t <kto> -s <kstep>]...) [-o|--orientation <orient>...] [-x|--exp-rast] [-l|--limit-tiles <tiles-csv>]
#example
$ ./ktpi.R ktpi-sqs --ktpi-feature plots --ktpi-function statistic --ktpi-function terrain --ktpi-function ktpi --ktpi-function kaspSlp --ktpi-function kaspDir --ktpi-function kaspSDir --ktpi-function kaspCDir --ktpi-function kaspSlpSDir --ktpi-function kaspSlpCDir --ktpi-function kaspSlpEle2 --ktpi-function kaspSlpEle2SDir --ktpi-function kaspSlpEle2CDir --ktpi-function kaspSlpLnEle --ktpi-function kaspSlpLnEleSlpSDir --ktpi-function kaspSlpLnEleSlpCDir --tile-col-min 0 --tile-col-max 15 --tile-row-min 0 --tile-row-max 9 --raster-cells 600 --raster-cell-size 5 -d 5 -f 10 -t 20 -s 5 -d 5 -f 40 -t 100 -s 20 -d 10 -f 100 -t 200 -s 20 -d 10 -f 250 -t 500 -s 50 -d 10 -f 600 -t 1000 -s 100 -d 20 -f 1000 -t 2000 -s 200 -d 20 -f 2250 -t 2500 -s 250 -o across -o uphill -o downhill -l /Users/mk/Documents/Projects/sk-hris/plotsTiles.txt > /Users/mk/Documents/Projects/sk-hris/plotsSqs_update.txt
    
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
* **Tile Structure**: Develop a uniform size tile at the beginning as a function of the project area.
* **DEM raster**: DEM raster data over the entire region, ie. 1m, 2m, 5m, or 10m. DEM data will automatically be aggregated, as specified, for larger dem cell calculations.
* **DEM raster tiling**: Restructure the DEM raster data to the tile structure. /input/dems/[column folder]/[row file].tif
* **Feature polygon**: Polygon features with UNIQUE RASTER identifier.
* **Feature raster**: Corresponding raster format of the feature polygon with the raster cell value as its unique integer identifier and will be used for the zonal analysis (NOTE: Feature rasters must coincide with DEM raster, origin and cell size).
* **Feature raster tiling**: Restructure the feature unit data to the tile structure. /input/features/[column folder]/[row file].tif

NOTE 1 - DEM cell size VS. kernel size: It is HIGHLY recommended that at larger [kernel size]s you choose a larger [dem cell size] that is a multiple of the original dem cell size. When the kernel is over 100 times the dem cell size the KTPI script takes significantly longer to process, and frankly could crash as your kernel focal analysis would contain 40000 cells (a square 200 cells E-W and 200 cells N-S).

NOTE 2 - DEM cell size: KTPI will automatically aggregate the DEM raster up to the new dem cell size as requested by the CLI input. It should be noted that the dem cell size should always be a multiple of the original dem cell size and evenly divisible into the number of cells in the raster. Example: your raster tiles are 500x500 cells of 5m x 5m or 2500m x 2500m: I recommend using the 5m dem cell size for kernels up to 500m, then use a 10m dem cell size for kernels up to 1000m, then 20m dem cell size for kernels up to 2000m, however a 30m dem cell size cannot be used as 2500m is no evenly divisible by 30m, the next recommended dem cell sizes would be 25m, then 50m, then 100m.

NOTE 3 - Adjacent tile merging: Provided your input data is structured properly (/input/dems/[column folder]/[row file].tif & /input/features/[column folder]/[row file].tif)) KTPI will automatically merge the adjacent tiles it requires for the kernel it is trying to calculate to remove any edge effect calculations within the subject tile. Example: your raster tiles are 500x500 cells of 5m x 5m or 2500m x 2500m: if you want a kernel calculation of 2000m on tile /5/6.tif, KTPI will automatically merge the adjacent 8 raster tiles (/4/5.tif, /5/5.tif, /6/5.tif, /4/6.tif, /6/6.tif, /4/7.tif, /5/7.tif, /6/7.tif) so the edge calculations in the subject tile (/5/6.tif) will compute properly; if you want a kernel calculation of 4000m on /5/6.tif, KTPI will automatically merge the adjacent 24 raster tiles so the edge calculations in the subject tile will compute properly.

NOTE 4 - Features split across tiles: If a feature polygon in the subject tile is split across multiple adjacent tiles, KTPI will calculate the values for the entire feature based on the above merged tiles and output the result for the entire feature. The result for that same feature in the adjacent tile calculations will again calculate the values for the entire feature, so the results for that feature will be duplicated.

## Feature Data Output

The following is a list of the *output indice values* summarized for each feature entity in a [tile] for a given [dem_cell_size] and [kernel_size]: ./output/[col]_[row]_[function name]_[kasp orientation]_[dem cell size]_[kernel size]_indices.csv

#### DEM statistic indices: [col]\_[row]\_statistic\_\_[dem cell size]\_\_indices.csv
* **tr_st_min_[dem_cell_size]**: minimum elevation within the feature for that DEM raster cell size
* **tr_st_max_[dem_cell_size]**: maximum elevation within the feature for that DEM raster cell size
* **tr_st_mean_[dem_cell_size]**: mean elevation within the feature for that DEM raster cell size
* **tr_st_sd_[dem_cell_size]**: standard deviation of elevation values within the feature for that DEM raster cell size

#### DEM terrain indices: [col]\_[row]\_terrain\_\_[dem cell size]\_\_indices.csv
* **tr\_te\_tri\_[dem\_cell\_size]**: Terrain Roughness Index within the feature for that DEM raster cell size
* **tr\_te\_tpi\_[dem\_cell\_size]**: Topographic Position Index within the feature for that DEM raster cell size
* **tr\_te\_roughness\_[dem\_cell\_size]**: roughness within the feature for that DEM raster cell size
* **tr\_te\_slope\_[dem\_cell\_size]**: slope within the feature for that DEM raster cell size
* **tr\_te\_aspect\_[dem\_cell\_size]**: aspect within the feature for that DEM raster cell size

#### DEM topographic position indices: [col]\_[row]\_ktpi\_\_[dem cell size]\_[kernel size]\_indices.csv
* **tr\_tp\_[dem\_cell\_size]m\_[kernel\_size]m\_[kernel\_cells]\_mean\_diff**: the mean, of the difference in elevation between the subject cell and the mean elevation of the kernel cells, of each cell within the feature for that kernel size and that DEM raster cell size
* **tr\_tp\_[dem\_cell\_size]m\_[kernel\_size]m\_[kernel\_cells]\_sd**: the mean, of the standard deviation of elevation of the kernel cells, of each cell within the feature for that kernel size and that DEM raster cell size

#### DEM kernel aspect indices: [col]\_[row]\_kasp[func]\_[kasp orientation]\_[dem cell size]\_[kernel size]\_indices.csv
* **tr\_ka\_[dem\_cell\_size]m\_[kernel\_size]m\_[kernel_cells]\_[kasp_function]\_[orientation]**: the kasp aspect interactions as a function of slope, direction and/or elevation, of each cell within the feature for that kernel size and that DEM raster cell size


## Raster Output

KTPI can also output the rasters that are generated prior to the zonal analysis to the feature. A raster can be generated for every indice in every tile, the following is a list of the *output raster files* for a [tile] for a given [dem_cell_size] and [kernel_size]:

#### DEM statistic indice rasters:
* **./output/tr_st/max/[dem_cell_size]/[column folder]/[row file].tif**
* **./output/tr_st/mean/[dem_cell_size]/[column folder]/[row file].tif**
* **./output/tr_st/min/[dem_cell_size]/[column folder]/[row file].tif**
* **./output/tr_st/sd/[dem_cell_size]/[column folder]/[row file].tif**

#### DEM terrain indice rasters:
* **./output/tr_te/aspect/[dem_cell_size]/[column folder]/[row file].tif**
* **./output/tr_te/ktpiflowdir9/[dem_cell_size]/[column folder]/[row file].tif**
* **./output/tr_te/roughness/[dem_cell_size]/[column folder]/[row file].tif**
* **./output/tr_te/slope/[dem_cell_size]/[column folder]/[row file].tif**
* **./output/tr_te/tpi/[dem_cell_size]/[column folder]/[row file].tif**
* **./output/tr_te/tri/[dem_cell_size]/[column folder]/[row file].tif**

#### DEM kernel topographic indice rasters:
* **./output/tr_tp/mean_diff/[dem_cell_size]/[kernel_size]/[column folder]/[row file].tif**
* **./output/tr_tp/sd/[dem_cell_size]/[kernel_size]/[column folder]/[row file].tif**

#### DEM kernel aspect indice rasters:
* **./output/tr_ka/[kasp_function]/[dem_cell_size]/[kernel_size]/[orientation]/[column folder]/[row file].tif**


## Scaled indice generation

Performing indice generation over a large area, over multiple [dem_cell_size] and over a range of [kernel_size] requires running the tool many times, for example all indices on one tile:6/7, one dem cell size:18, only two kernel sizes:200&1600, and the three kasp orientations:across,uphill,downhill the following CLI commands are required:

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
