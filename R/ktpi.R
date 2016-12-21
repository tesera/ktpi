#!/usr/bin/env Rscript

library(docopt)
source("./ktpi_util.R")
source("./ktpi_terrain.R")
source("./ktpi_aspect.R")

'
Usage:
    ktpi.R (statistic | terrain) <feature-file> <dem-folder> <output-folder> [-d|--dem-calc-size <dsize>] [-x|--exp-rast]
    ktpi.R ktpi <feature-file> <dem-folder> <output-folder> [-d <dsize>] [-k|--kernel-size <ksize>] [-x|--exp-rast]
    ktpi.R (kaspSlp | kaspDir | kaspSDir | kaspCDir | kaspSlpSDir | kaspSlpCDir | kaspSlpEle2 | kaspSlpEle2SDir | kaspSlpEle2CDir | kaspSlpLnEle | kaspSlpLnEleSlpSDir | kaspSlpLnEleSlpCDir) <feature-file> <dem-folder> <output-folder> [-d <dsize>] [-k|--kernel-size <ksize>] [-o|--orientation <orient>] [-x|--exp-rast]
    ktpi.R neighbourhood (-c <fcol>) (-r <frow>) (--tile-col-min <cmin>) (--tile-col-max <cmax>) (--tile-row-min <rmin>) (--tile-row-max <rmax>) (--raster-cells <rcell>) (--raster-cell-size <csize>) (-k <ksize>)
    ktpi.R ktpi-cli (--ktpi-function <ktpi-func>)... <feature-folder> <dem-folder> <output-folder> (--tile-col-min <cmin>) (--tile-col-max <cmax>) (--tile-row-min <rmin>) (--tile-row-max <rmax>) (--raster-cells <rcell>) (--raster-cell-size <csize>) (-d <dsize>... [-f <kfrom> -t <kto> -s <kstep>]...) [-o|--orientation <orient>...] [-x|--exp-rast] [-l|--limit-tiles <tiles-csv>]
    ktpi.R ktpi-sqs (--ktpi-feature <ktpi-feat>) (--ktpi-function <ktpi-func>)... (--tile-col-min <cmin>) (--tile-col-max <cmax>) (--tile-row-min <rmin>) (--tile-row-max <rmax>) (--raster-cells <rcell>) (--raster-cell-size <csize>) (-d <dsize>... [-f <kfrom> -t <kto> -s <kstep>]...) [-o|--orientation <orient>...] [-x|--exp-rast] [-l|--limit-tiles <tiles-csv>]
    ktpi.R [-h|--help]
    kpti.R --version
    ktpi.R info

Options:
    -h --help                               show this screen.
    --version                               show version.
    statistic                               runs statistic indices at the defined cell size. ie. statistic dsize=5, will develop statistic indices at the 5m cell size.
    terrain                                 runs terrain indices at the defined cell size. ie. terrain dsize=10, will develop terrain indices at the 10m cell size.
    ktpi                                    runs topographic position indices at the defined cell and kernel neighbourhood size. ie. ktpi dsize=20 kernel-size=800, will develop topographic position indices (sd & mean_diff) for a 20m dem cell size at the 800m kernel neighbourhood.
    kaspSlp                                 runs slope indices at the defined orientation (across, uphill, downhill) at the defined cell and kernel neighbourhood size. ie. ktpi-aspect ktpislp uphill dsize=10 kernel-size=500, will develop slope indices for a 10m dem cell size at the 500m kernel ring for DEM values uphill of the kernel centroid. 
    kaspDir                                 runs direction indices at the defined orientation (across, uphill, downhill) at the defined cell and kernel neighbourhood size.
    kaspSDir                                runs sin direction indices at the defined orientation (across, uphill, downhill) at the defined cell and kernel neighbourhood size.
    kaspCDir                                runs cos direction indices at the defined orientation (across, uphill, downhill) at the defined cell and kernel neighbourhood size.
    kaspSlpSDir                             runs Al Stage slope * sin direction
    kaspSlpCDir                             runs Al Stage slope * cos direction
    kaspSlpEle2                             runs Al Stage slope * dem^2
    kaspSlpEle2SDir                         runs Al Stage slope * dem^2 * sin direction
    kaspSlpEle2CDir                         runs Al Stage slope * dem^2 * sin direction
    kaspSlpLnEle                            runs Al Stage slope * natural log of dem
    kaspSlpLnEleSlpSDir                     runs Al Stage slope * natural log of dem * slp * sin direction
    kaspSlpLnEleSlpCDir                     runs Al Stage slope * natural log of dem * slp * cos direction
    neighbourhood                           gets a list of the neighbouring tiles within a kernel size of a given raster tile and raster dimensions
    ktpi-cli                                creates a list of CLI commands on min/max column/row, dem calculation sizes, kernel from-to-step, orientation, and limited to a set of tiles
    ktpi-sqs                                creates a list of SQS messages on min/max column/row, dem calculation sizes, kernel from-to-step, orientation, and limited to a set of tiles
    feature-file                            input feature raster source tile (TMS standard, <col> & <row> numbers without leading zeros): [./<folder>/<col>/<row>.tif]
    feature-folder                          input feature raster source folder: [./<folder>]
    dem-folder                              input DEM raster source folder: [./<folder>]
    output-folder                           existing output data folder: [./<folder>]
    -d <dsize>, --dem-calc-size <dsize>     DEM cell size to calculate indices. ie. 5 = 5m [DEFAULT = raster cell size, maximum = cell size * tile cells] ( recalculated to be nearest evenly divisible into tile size: for (i in 1:(tilecells)) {if(tilecells%%i == 0) {print(i)}} ).
    -k <ksize>, --kernel-size <ksize>       kernel neighbourhood size, in ground units, to calculate ktpi indices. ie. 50 = 50m [DEFAULT = demCalcSize x 5]
    -x, --exp-rast                          exports indices rasters.
    -c <fcol>, --tile-col <fcol>            tile column
    -r <frow>, --tile-row <frow>            tile row
    -o <orient>, --orientation <orient>     ktpi-aspect kernel orientation: across, uphill, downhill
    -l <tiles>, --limit-tiles <tiles>       csv file of tiles to filter (column of "col/row")
    --raster-cells <rcell>                  raster tile size (cells)
    --raster-cell-size <csize>              raster cell size (m)
    --ktpi-feature <ktpi-feat>              feature type to generate CLI arguments
    --ktpi-function <ktpi-func>             ktpi functions to generate CLI arguments
    --tile-col-min <cmin>                   tile min column value
    --tile-col-max <cmax>                   tile max column value
    --tile-row-min <rmin>                   tile min row value
    --tile-row-max <rmax>                   tile max row value
    -f <kfrom>, --kernel-from <kfrom>       kernel from range
    -t <kto>, --kernel-to <kto>             kernel to ranged
    -s <kstep>, --kernel-step <kstep>       kernel range step
' -> doc
args <- docopt(doc)

if (args$'info') {
    print(.libPaths())
    print(sessionInfo())
    print(version)
}

if (args$'statistic' | args$'terrain' | args$'ktpi' | args$'kaspSlp' | args$'kaspDir' | 
    args$'kaspSDir' | args$'kaspCDir' | args$'kaspSlpSDir' | args$'kaspSlpCDir' | 
    args$'kaspSlpEle2' | args$'kaspSlpEle2SDir' | args$'kaspSlpEle2CDir' | 
    args$'kaspSlpLnEle' | args$'kaspSlpLnEleSlpSDir' | args$'kaspSlpLnEleSlpCDir') {
    # gets the feature raster file path, and the tile and extension
    TMSFolderTileExt <- getTMSFolderZoomColRowExt(args$'feature-file')

    # gets feature neighbouring tile files based on the kernel neighbourhood size
    neighbourFileList <- getTMSTileFileNeighbours(TMSFolderTileExt$fileFolder,
            TMSFolderTileExt$tileCol,
            TMSFolderTileExt$tileRow,
            TMSFolderTileExt$fileExt, args$'kernel-size')

    # merges feature neighbouring tile files
    featureNeighbourRaster <- mergeRasters(neighbourFileList)

    # gets dem neighbouring tile files based on the kernel neighbourhood size
    neighbourFileList <- getTMSTileFileNeighbours(args$'dem-folder',
            TMSFolderTileExt$tileCol,
            TMSFolderTileExt$tileRow,
            TMSFolderTileExt$fileExt, args$'kernel-size')

    # merges dem neighbouring tile files
    demNeighbourRaster <- mergeRasters(neighbourFileList)

    # gets initial indice table with unique featid and cell counts
    indic <- getFeatureIdCount(TMSFolderTileExt$fileFolder,
            TMSFolderTileExt$tileCol,
            TMSFolderTileExt$tileRow,
            TMSFolderTileExt$fileExt)
    indicFeatCountInit <- nrow(indic)

    # runs statistic indices
    if (args$'statistic') {
        ktpiFunction <- "statistic"
        featStat <- statisticIndices(args$'feature-file',
            featureNeighbourRaster,
            demNeighbourRaster,
            args$'output-folder',
            args$'dem-calc-size',
            args$'exp-rast',
            TMSFolderTileExt$tileCol,
            TMSFolderTileExt$tileRow)
        indic <- merge(indic, featStat, by = "featid")
        indicFeatCountPost <- nrow(indic)
    }

    # runs terrain indices
    if (args$'terrain') {
        ktpiFunction <- "terrain"
        featTerr <- terrainIndices(args$'feature-file',
            featureNeighbourRaster,
            demNeighbourRaster,
            args$'output-folder',
            args$'dem-calc-size',
            args$'exp-rast',
            TMSFolderTileExt$tileCol,
            TMSFolderTileExt$tileRow)
        indic <- merge(indic, featTerr, by = "featid")
        indicFeatCountPost <- nrow(indic)
    }

    # runs kernel topographic position indices
    if (args$'ktpi') {
        ktpiFunction <- "ktpi"
        featKtpi <- ktpiIndices(args$'feature-file',
            featureNeighbourRaster,
            demNeighbourRaster,
            args$'output-folder',
            args$'dem-calc-size',
            args$'kernel-size',
            args$'exp-rast',
            TMSFolderTileExt$tileCol,
            TMSFolderTileExt$tileRow)
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
            args$'feature-file',
            featureNeighbourRaster,
            demNeighbourRaster,
            args$'output-folder',
            args$'dem-calc-size',
            args$'kernel-size',
            args$'exp-rast',
            TMSFolderTileExt$tileCol,
            TMSFolderTileExt$tileRow,
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
    outputTableName <- paste(TMSFolderTileExt$'tileCol', TMSFolderTileExt$'tileRow', 
        ktpiFunction, args$'orientation', args$'dem-calc-size', args$'kernel-size', "indices.csv", sep = "_")
    outputTablePath <- paste(args$'output-folder', outputTableName, sep = "/")

    # writes out indices table file
    write.table(indic, file =  outputTablePath, append = FALSE, sep = ",", col.names = TRUE, row.names = FALSE, quote = FALSE)
}

if (args$'neighbourhood') {
    getNeighbourhoodCR(args$'tile-col', args$'tile-row', 
        args$'tile-col-min', args$'tile-col-max', args$'tile-row-min', args$'tile-row-max', 
        args$'raster-cells', args$'raster-cell-size', args$'kernel-size')
}

if (args$'ktpi-cli') {
    tiles <- args$'limit-tiles'
    if (tiles != "none") { 
        tiles <- read.csv(args$'limit-tiles', header=FALSE)$V1 
    }
    createKtpiCLICommands(args$'ktpi-function', args$'feature-folder', args$'dem-folder', args$'output-folder', 
        args$'tile-col-min', args$'tile-col-max', args$'tile-row-min', args$'tile-row-max', 
        args$'raster-cells', args$'raster-cell-size', args$'dem-calc-size', args$'kernel-from', args$'kernel-to', 
        args$'kernel-step', args$'orientation', args$'exp-rast', tiles)
}

if (args$'ktpi-sqs') {
    tiles <- args$'limit-tiles'
    if (tiles != "none") { 
        tiles <- read.csv(args$'limit-tiles', header=FALSE)$V1
    }
    createKtpiSQSMessages(args$'ktpi-feature', args$'ktpi-function', 
        args$'tile-col-min', args$'tile-col-max', args$'tile-row-min', args$'tile-row-max', 
        args$'raster-cells', args$'raster-cell-size', args$'dem-calc-size', args$'kernel-from', args$'kernel-to', args$'kernel-step', 
        args$'orientation', args$'exp-rast', tiles)
}