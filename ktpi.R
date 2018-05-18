#!/usr/bin/env Rscript
suppressMessages(library(docopt))
suppressMessages(library(jsonlite))

# ktpi.R neighbours -c 3 -r 4 -w 2 -x 4 -y 3 -z 5 -m 1 -n 2000 -k 100 -l tiles.txt
# ktpi.R neighbours -p ./features/ -c 3 -r 4 -a .tif -w 2 -x 4 -y 3 -z 5 -m 1 -n 2000 -k 100 -l tiles.txt
# ktpi.R statistic -p ./features/ -q ./dems/ -c 3 -r 4 -a .tif -w 1 -x 99 -y 1 -z 99 -m 1 -n 2000 -d 5 -l tiles.txt -u ./output/
# ktpi.R terrain -p ./features/ -q ./dems/ -c 3 -r 4 -a .tif -w 1 -x 99 -y 1 -z 99 -m 1 -n 2000 -d 5 -l tiles.txt -u ./output/
# ktpi.R ktpi -p ./features/ -q ./dems/ -c 3 -r 4 -a .tif -w 1 -x 99 -y 1 -z 99 -m 1 -n 2000 -d 5 -k 100 -l tiles.txt -u ./output/
# ktpi.R kaspSlp -p ./features/ -q ./dems/ -c 3 -r 4 -a .tif -w 1 -x 99 -y 1 -z 99 -m 1 -n 2000 -d 5 -k 100 -o across -l tiles.txt -u ./output/
# ktpi.R ktpi-cli --ktpi-function statistic --ktpi-function terrain -p ./features/ -q ./dems/ -a .tif -w 1 -x 99 -y 1 -z 99 -m 1 -n 2000 -d 1 -d 5 -d 10 -d 20 -l tiles.txt -u ./output/
# ktpi.R ktpi-cli --ktpi-function ktpi -p ./features/ -q ./dems/ -a .tif -w 1 -x 99 -y 1 -z 99 -m 1 -n 2000 -d 5 -f 20 -t 50 -s 10 -d 10 -f 50 -t 200 -s 50 -l tiles.txt -u ./output/
# ktpi.R ktpi-cli --ktpi-function kaspSlp -p ./features/ -q ./dems/ -a .tif -w 1 -x 99 -y 1 -z 99 -m 1 -n 2000 -d 5 -f 20 -t 50 -s 10 -d 10 -f 50 -t 200 -s 50 -o uphill -o across -o downhill -l tiles.txt -u ./output/
# ktpi.R ktpi-json --ktpi-function statistic --ktpi-function terrain -p ./features/ -q ./dems/ -a .tif -w 1 -x 99 -y 1 -z 99 -m 1 -n 2000 -d 1 -d 5 -d 10 -d 20 -l tiles.txt -u ./output/
# ktpi.R ktpi-json --ktpi-function ktpi -p ./features/ -q ./dems/ -a .tif -w 1 -x 99 -y 1 -z 99 -m 1 -n 2000 -d 5 -f 20 -t 50 -s 10 -d 10 -f 50 -t 200 -s 50 -l tiles.txt -u ./output/
# ktpi.R ktpi-json --ktpi-function kaspSlp -p ./features/ -q ./dems/ -a .tif -w 1 -x 99 -y 1 -z 99 -m 1 -n 2000 -d 5 -f 20 -t 50 -s 10 -d 10 -f 50 -t 200 -s 50 -o uphill -o across -o downhill -l tiles.txt -u ./output/
# ktpi.R ktpi-json --ktpi-function statistic --ktpi-function terrain --ktpi-function ktpi --ktpi-function kaspSlp --ktpi-function kaspDir --ktpi-function kaspSDir --ktpi-function kaspCDir --ktpi-function kaspSlpSDir --ktpi-function kaspSlpCDir --ktpi-function kaspSlpEle2 --ktpi-function kaspSlpEle2SDir --ktpi-function kaspSlpEle2CDir --ktpi-function kaspSlpLnEle --ktpi-function kaspSlpLnEleSlpSDir --ktpi-function kaspSlpLnEleSlpCDir -p ./features/ -q ./dems/ -a .tif -w 1 -x 3 -y 1 -z 2 -m 1 -n 4000 -d 1 -f 10 -t 20 -s 5 -d 5 -f 20 -t 100 -s 20 -d 10 -f 100 -t 200 -s 20 -d 10 -f 250 -t 500 -s 50 -d 10 -f 600 -t 1000 -s 100 -d 20 -f 1000 -t 2000 -s 200 -d 20 -f 2250 -t 2500 -s 250 -o across -o uphill -o downhill -u ./output/ > /json.txt

'Usage:
    ktpi.R (statistic | terrain) (--folder <fpre>) (--dem-folder <dpre>) (--tile-col <tcol>) (--tile-row <trow>) (--extension <ext>) (--tile-col-min <cmin>) (--tile-col-max <cmax>) (--tile-row-min <rmin>) (--tile-row-max <rmax>) (--raster-cell-size <csize>) (--raster-cells <rcell>) [--dem-calc-size <dsize>] [--limit-tiles <tiles-csv>] (--output-folder <ofolder>) [--exp-rast]
    ktpi.R ktpi (--folder <fpre>) (--dem-folder <dpre>) (--tile-col <tcol>) (--tile-row <trow>) (--extension <ext>) (--tile-col-min <cmin>) (--tile-col-max <cmax>) (--tile-row-min <rmin>) (--tile-row-max <rmax>) (--raster-cell-size <csize>) (--raster-cells <rcell>) [--dem-calc-size <dsize>] [--kernel-size <ksize>] [--limit-tiles <tiles-csv>] (--output-folder <ofolder>) [--exp-rast]
    ktpi.R (kaspSlp | kaspDir | kaspSDir | kaspCDir | kaspSlpSDir | kaspSlpCDir | kaspSlpEle2 | kaspSlpEle2SDir | kaspSlpEle2CDir | kaspSlpLnEle | kaspSlpLnEleSlpSDir | kaspSlpLnEleSlpCDir) (--folder <fpre>) (--dem-folder <dpre>) (--tile-col <tcol>) (--tile-row <trow>) (--extension <ext>) (--tile-col-min <cmin>) (--tile-col-max <cmax>) (--tile-row-min <rmin>) (--tile-row-max <rmax>) (--raster-cell-size <csize>) (--raster-cells <rcell>) [--dem-calc-size <dsize>] [--kernel-size <ksize>] [--orientation <orient>] (--output-folder <ofolder>) [-l|--limit-tiles <tiles-csv>] [--exp-rast]
    ktpi.R neighbours [--folder <pre>] (-c <fcol>) (-r <frow>) [--extension <app>] (--tile-col-min <cmin>) (--tile-col-max <cmax>) (--tile-row-min <rmin>) (--tile-row-max <rmax>) (--raster-cells <rcell>) (--raster-cell-size <csize>) (-k <ksize>) [-l|--limit-tiles <tiles-csv>]
    ktpi.R ktpi-cli (--ktpi-function <ktpi-func>)... (--folder <fpre>) (--dem-folder <dpre>) (--extension <app>) (--tile-col-min <cmin>) (--tile-col-max <cmax>) (--tile-row-min <rmin>) (--tile-row-max <rmax>) (--raster-cells <rcell>) (--raster-cell-size <csize>) (-d <dsize>... [-f <kfrom> -t <kto> -s <kstep>]...) [-o|--orientation <orient>...] [-l|--limit-tiles <tiles-csv>] (--output-folder <ofolder>) [--exp-rast]
    ktpi.R ktpi-json (--ktpi-function <ktpi-func>)... (--folder <fpre>) (--dem-folder <dpre>) (--extension <app>) (--tile-col-min <cmin>) (--tile-col-max <cmax>) (--tile-row-min <rmin>) (--tile-row-max <rmax>) (--raster-cells <rcell>) (--raster-cell-size <csize>) (-d <dsize>... [-f <kfrom> -t <kto> -s <kstep>]...) [-o|--orientation <orient>...] [-l|--limit-tiles <tiles-csv>] (--output-folder <ofolder>) [--exp-rast]
    ktpi.R [-h|--help]
    kpti.R --version
    ktpi.R info

Options:
    -h --help                                   show this screen.
    --version                                   show version.
    statistic                                   runs statistic indices at the defined cell size. ie. statistic dsize=5, will develop statistic indices at the 5m cell size.
    terrain                                     runs terrain indices at the defined cell size. ie. terrain dsize=10, will develop terrain indices at the 10m cell size.
    ktpi                                        runs topographic position indices at the defined cell and kernel neighbourhood size. ie. ktpi dsize=20 kernel-size=800, will develop topographic position indices (sd & mean_diff) for a 20m dem cell size at the 800m kernel neighbourhood.
    kaspSlp                                     runs slope indices at the defined orientation (across, uphill, downhill) at the defined cell and kernel neighbourhood size. ie. ktpi-aspect ktpislp uphill dsize=10 kernel-size=500, will develop slope indices for a 10m dem cell size at the 500m kernel ring for DEM values uphill of the kernel centroid. 
    kaspDir                                     runs direction indices at the defined orientation (across, uphill, downhill) at the defined cell and kernel neighbourhood size.
    kaspSDir                                    runs sin direction indices at the defined orientation (across, uphill, downhill) at the defined cell and kernel neighbourhood size.
    kaspCDir                                    runs cos direction indices at the defined orientation (across, uphill, downhill) at the defined cell and kernel neighbourhood size.
    kaspSlpSDir                                 runs Al Stage slope * sin direction
    kaspSlpCDir                                 runs Al Stage slope * cos direction
    kaspSlpEle2                                 runs Al Stage slope * dem^2
    kaspSlpEle2SDir                             runs Al Stage slope * dem^2 * sin direction
    kaspSlpEle2CDir                             runs Al Stage slope * dem^2 * sin direction
    kaspSlpLnEle                                runs Al Stage slope * natural log of dem
    kaspSlpLnEleSlpSDir                         runs Al Stage slope * natural log of dem * slp * sin direction
    kaspSlpLnEleSlpCDir                         runs Al Stage slope * natural log of dem * slp * cos direction
    neighbours                                  gets a list of the neighbouring tiles of a given raster tile, based on the given raster dimensions, and a given kernel size, and a text file of tiles to filter (column of "col/row").
    ktpi-cli                                    creates a list of CLI commands on min/max column/row, dem calculation sizes, kernel from-to-step, orientation, and a text file of tiles to filter
    ktpi-json                                   creates a list of JSON messages on min/max column/row, dem calculation sizes, kernel from-to-step, orientation, and a text file of tiles to filter
    -p <fpre>, --folder <fpre>                  prepended input feature raster source folder (/<folder>/)
    -q <dpre>, --dem-folder <dpre>              prepended input DEM raster source folder (/<folder>/)
    -c <fcol>, --tile-col <fcol>                tile column
    -r <frow>, --tile-row <frow>                tile row
    -a <ext>, --extension <ext>                 appended tile file extension (.tif)
    -w <cmin>, --tile-col-min <cmin>            project tile min column value
    -x <cmax>, --tile-col-max <cmax>            project ile max column value
    -y <rmin>, --tile-row-min <rmin>            project tile min row value
    -z <rmax>, --tile-row-max <rmax>            project tile max row value
    -m <csize>, --raster-cell-size <csize>      raster cell size (m)
    -n <rcell>, --raster-cells <rcell>          raster tile size (cells)
    -d <dsize>, --dem-calc-size <dsize>         DEM cell size to calculate indices. ie. 5 = 5m [DEFAULT = raster cell size, maximum = cell size * tile cells] ( recalculated to be nearest evenly divisible into tile size: for (i in 1:(tilecells)) {if(tilecells%%i == 0) {print(i)}} ).
    -k <ksize>, --kernel-size <ksize>           kernel neighbourhood size, in ground units, to calculate ktpi indices. ie. 50 = 50m (DEFAULT = demCalcSize x 5)
    -f <kfrom>, --kernel-from <kfrom>           kernel from range
    -t <kto>, --kernel-to <kto>                 kernel to ranged
    -s <kstep>, --kernel-step <kstep>           kernel range step
    -o <orient>, --orientation <orient>         ktpi-aspect kernel orientation: across, uphill, downhill
    -l <tiles>, --limit-tiles <tiles>           text file of tiles to filter (column of "col/row") [default: none]
    --ktpi-function <ktpi-func>                 ktpi functions to generate CLI/JSON arguments
    -u <ofolder>, --output-folder <ofolder>     existing output data folder (/<folder>/)
    --exp-rast                                  exports indices rasters.
' -> doc
args <- docopt(doc)

inputDataPath <- file.path(Sys.getenv('HRIS_DATA'), 'input')
outputDataPath <- file.path(Sys.getenv('HRIS_DATA'), 'output')
dir.create(outputDataPath, showWarnings = FALSE)

wd <- Sys.getenv('HRIS_DATA')
setwd(wd)
options(warn = -1)

source_local <- function(fname){
    argv <- commandArgs(trailingOnly = FALSE)
    base_dir <- dirname(substring(argv[grep("--file=", argv)], 8))
    source(paste(base_dir, fname, sep="/"))
}

if (args$'info') {
    print(.libPaths())
    print(sessionInfo())
    print(version)
}

tilesfile <- args$'limit-tiles'
tiles <- "none"
if (tilesfile != "none") { 
    tiles <- read.csv(tilesfile, stringsAsFactors=FALSE, header=FALSE)$V1
}

if (args$'statistic' | args$'terrain' | args$'ktpi' | args$'kaspSlp' | args$'kaspDir' | 
    args$'kaspSDir' | args$'kaspCDir' | args$'kaspSlpSDir' | args$'kaspSlpCDir' | 
    args$'kaspSlpEle2' | args$'kaspSlpEle2SDir' | args$'kaspSlpEle2CDir' | 
    args$'kaspSlpLnEle' | args$'kaspSlpLnEleSlpSDir' | args$'kaspSlpLnEleSlpCDir') {

    source_local("lib/ktpi_util.R")
    source_local("lib/ktpi_aspect.R")
    source_local("lib/ktpi_terrain.R")

    # gets feature neighbouring tile files based on the kernel neighbourhood size
    neighbourFileList <- getNeighbours(args$'folder', args$'tile-col', args$'tile-row', args$'extension',
        args$'tile-col-min', args$'tile-col-max', args$'tile-row-min', args$'tile-row-max', 
        args$'raster-cells', args$'raster-cell-size', args$'kernel-size', tiles)

    # merges feature neighbouring tile files
    featureNeighbourRaster <- mergeRasters(neighbourFileList)

    # gets dem neighbouring tile files based on the kernel neighbourhood size
    neighbourFileList <- getNeighbours(args$'dem-folder', args$'tile-col', args$'tile-row', args$'extension',
        args$'tile-col-min', args$'tile-col-max', args$'tile-row-min', args$'tile-row-max', 
        args$'raster-cells', args$'raster-cell-size', args$'kernel-size', tiles)

    # merges dem neighbouring tile files
    demNeighbourRaster <- mergeRasters(neighbourFileList)

    # gets initial indice table with unique featid and cell counts
    indic <- getFeatureIdCount(args$'folder',
            args$'tile-col',
            args$'tile-row',
            args$'extension')
    indicFeatCountInit <- nrow(indic)

    # runs statistic indices
    if (args$'statistic') {
        ktpiFunction <- "statistic"
        featStat <- statisticIndices(args$'folder', args$'tile-col', args$'tile-row', args$'extension',
            featureNeighbourRaster, demNeighbourRaster,
            args$'output-folder',
            args$'dem-calc-size',
            args$'exp-rast')
        indic <- merge(indic, featStat, by = "featid")
        indicFeatCountPost <- nrow(indic)
    }

    # runs terrain indices
    if (args$'terrain') {
        ktpiFunction <- "terrain"
        featTerr <- terrainIndices(args$'folder', args$'tile-col', args$'tile-row', args$'extension',
            featureNeighbourRaster,
            demNeighbourRaster,
            args$'output-folder',
            args$'dem-calc-size',
            args$'exp-rast')
        indic <- merge(indic, featTerr, by = "featid")
        indicFeatCountPost <- nrow(indic)
    }

    # runs kernel topographic position indices
    if (args$'ktpi') {
        ktpiFunction <- "ktpi"
        featKtpi <- ktpiIndices(args$'folder', args$'tile-col', args$'tile-row', args$'extension',
            featureNeighbourRaster,
            demNeighbourRaster,
            args$'output-folder',
            args$'dem-calc-size',
            args$'kernel-size',
            args$'exp-rast')
        indic <- merge(indic, featKtpi, by = "featid")
        indicFeatCountPost <- nrow(indic)
    }

    # runs kernel aspect indices
    if (args$'kaspSlp' | args$'kaspDir' | args$'kaspSDir' | 
        args$'kaspCDir' | args$'kaspSlpSDir' | args$'kaspSlpCDir' | 
        args$'kaspSlpEle2' | args$'kaspSlpEle2SDir' | args$'kaspSlpEle2CDir' | 
        args$'kaspSlpLnEle' | args$'kaspSlpLnEleSlpSDir' | args$'kaspSlpLnEleSlpCDir'
        ) {
        if (args$'kaspSlp') { ktpiFunction <- "kaspSlp" }
        if (args$'kaspDir') { ktpiFunction <- "kaspDir" }
        if (args$'kaspSDir') { ktpiFunction <- "kaspSDir" }
        if (args$'kaspCDir') { ktpiFunction <- "kaspCDir" }
        if (args$'kaspSlpSDir') { ktpiFunction <- "kaspSlpSDir" }
        if (args$'kaspSlpCDir') { ktpiFunction <- "kaspSlpCDir" }
        if (args$'kaspSlpEle2') { ktpiFunction <- "kaspSlpEle2" }
        if (args$'kaspSlpEle2SDir') { ktpiFunction <- "kaspSlpEle2SDir" }
        if (args$'kaspSlpEle2CDir') { ktpiFunction <- "kaspSlpEle2CDir" }
        if (args$'kaspSlpLnEle') { ktpiFunction <- "kaspSlpLnEle" }
        if (args$'kaspSlpLnEleSlpSDir') { ktpiFunction <- "kaspSlpLnEleSlpSDir" }
        if (args$'kaspSlpLnEleSlpCDir') { ktpiFunction <- "kaspSlpLnEleSlpCDir" }
        featKaspi <- kaspIndices(ktpiFunction,
            args$'folder', args$'tile-col', args$'tile-row', args$'extension',
            featureNeighbourRaster,
            demNeighbourRaster,
            args$'output-folder',
            args$'dem-calc-size',
            args$'kernel-size',
            args$'exp-rast',
            args$'orientation')
        indic <- merge(indic, featKaspi, by = "featid")
        indicFeatCountPost <- nrow(indic)
    }

    if (indicFeatCountInit != indicFeatCountPost) stop("processed stopped: input feature count is not equivalent to output feature count")

    # turn scientific notation off
    options(scipen=999)
    # round off numeric indic values to 6 decimal places
    is.num <- sapply(indic, is.numeric)
    indic[is.num] <- lapply(indic[is.num], round, 6)
    # replace indic "NA" values with ""
    indic[is.na(indic)] <- ""

    # generates output indices table filename and path
    outputTableName <- paste(args$'tile-col', args$'tile-row', ktpiFunction, args$'orientation', args$'dem-calc-size', args$'kernel-size', "indices.csv", sep = "_")
    outputTablePath <- paste(args$'output-folder', outputTableName, sep = "/")

    # writes out indices table file
    write.table(indic, file =  outputTablePath, append = FALSE, sep = ",", col.names = TRUE, row.names = FALSE, quote = FALSE)
}

if (args$'neighbours') {

    source_local("lib/ktpi_util.R")

    getNeighbours(args$'folder', args$'tile-col', args$'tile-row', args$'extension',
        args$'tile-col-min', args$'tile-col-max', args$'tile-row-min', args$'tile-row-max', 
        args$'raster-cells', args$'raster-cell-size', args$'kernel-size', tiles)
}

if (args$'ktpi-cli') {

    source_local("lib/ktpi_util.R")

    createKtpiCLICommands(args$'ktpi-function', args$'folder', args$'dem-folder', args$'extension', args$'output-folder', 
        args$'tile-col-min', args$'tile-col-max', args$'tile-row-min', args$'tile-row-max', 
        args$'raster-cells', args$'raster-cell-size', args$'dem-calc-size', args$'kernel-from', args$'kernel-to', 
        args$'kernel-step', args$'orientation', args$'exp-rast', tilesfile, tiles)
}

if (args$'ktpi-json') {

    source_local("lib/ktpi_util.R")

    createKtpiJSONMessages(args$'ktpi-function', args$'folder', args$'dem-folder', args$'extension', args$'output-folder', 
        args$'tile-col-min', args$'tile-col-max', args$'tile-row-min', args$'tile-row-max', 
        args$'raster-cells', args$'raster-cell-size', args$'dem-calc-size', args$'kernel-from', args$'kernel-to', 
        args$'kernel-step', args$'orientation', args$'exp-rast', tilesfile, tiles)
}
