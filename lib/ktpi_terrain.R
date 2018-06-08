suppressMessages(library(rgdal, quietly = TRUE))
suppressMessages(library(raster, quietly = TRUE))
suppressMessages(library(stringr, quietly = TRUE))

statisticIndices <- function(featureFolder, tileCol, tileRow, extension, featureNeighbourRaster, demNeighbourRaster, outputFolder, 
    demCalcSize, exportRasters) {
    # gets feature raster
    feat <- paste(featureFolder, "/", tileCol, "/", tileRow, extension, sep="")
    feat <- raster(feat)
    # copies feature raster for extent
    featExt <- feat
    # initializes the feature statistics for the featureFile
    featStat <- data.frame(trFeatId = integer(length(unique(feat))))
    # populates feature statistics with the unique feat in the featureFile
    featStat$trFeatId <- unique(feat)
    featSize <- xres(feat)

    # gets default demCalcSize if not defined or sets as integer
    if (is.null(demCalcSize)) {
        demCalcSize <- featSize
    } else {
        demCalcSize <- as.integer(demCalcSize)
    }

    # demCalcSize cannot be smaller than featSize
    if (demCalcSize < featSize) {
        demCalcSize <- featSize
    }

    # gets neighbourhood rasters
    feat <- featureNeighbourRaster
    dem <- demNeighbourRaster

    # calculate the dem aggregate/disaggregate factor for the analysis demCalcSize
    dem2FeatFactor <- as.integer(demCalcSize/featSize)
    if (dem2FeatFactor > 1.0) {
        dem <- aggregate(dem, fact=c(dem2FeatFactor, dem2FeatFactor))
        dem <- disaggregate(dem, fact=c(dem2FeatFactor, dem2FeatFactor))
    }

    # calculates cell statistics for every feature in the neighbourhood
    for (func in c("min", "max", "mean", "sd")) {
        res <- zonal(dem, feat, fun = func, digits = 3, na.rm = TRUE)
        colnames(res) <- c("trFeatId", paste("trStC", demCalcSize, str_to_title(func), sep = ""))
        # merges the statistic into the feature statistics for the featureFile
        featStat <- merge(featStat, res, by = "trFeatId", quotes = FALSE)
        if (exportRasters) {
            # puts the folder structure trStC/{min,max,mean,sd}/{demCalcSize}/{Col}/{Row}.tif
            createFolder(outputFolder, 'trStC')
            createFolder(paste(outputFolder, 'trStC', sep = '/'), demCalcSize)
            createFolder(paste(outputFolder, 'trStC', demCalcSize, sep = '/'), func)
            createFolder(paste(outputFolder, 'trStC', demCalcSize, func, sep = '/'), tileCol)
            # gets the export folder and filename
            exportFolder <- paste(outputFolder, "trStC", demCalcSize, func, tileCol, sep = "/")
            exportFileFunc <- paste(exportFolder, "/", tileRow, ".tif", sep = "")
            featExtSubs <- subs(featExt, data.frame(res))
            # puts export raster
            writeRaster(featExtSubs, exportFileFunc, overwrite = TRUE)
        }
    }
    return(featStat)
}

terrainIndices <- function(featureFolder, tileCol, tileRow, extension, featureNeighbourRaster, demNeighbourRaster, outputFolder, 
    demCalcSize, exportRasters) {
    # gets feature raster
    feat <- paste(featureFolder, "/", tileCol, "/", tileRow, extension, sep="")
    feat <- raster(feat)
    # copies feature raster for extent
    featExt <- feat
    # initializes the feature statistics for the tile
    featTerr<- data.frame(trFeatId = integer(length(unique(feat))))
    # populates feature statistics with the unique feat in the tile
    featTerr$trFeatId <- unique(feat)
    featSize <- xres(feat)

    # gets default demCalcSize if not defined or sets as integer, minimum equal to featSize
    if (is.null(demCalcSize)) {
        demCalcSize <- featSize
    } else {
        demCalcSize <- as.integer(demCalcSize)
    }

    # demCalcSize cannot be smaller than featSize
    if (demCalcSize < featSize) {
        demCalcSize <- featSize
    }

    # recalculates demCalcSize if too small, too big, or not evenly divisible into raster size
    demCalcSize <- reCalculateDemCalcSize(feat, demCalcSize)

    # gets neighbourhood rasters
    feat <- featureNeighbourRaster
    dem <- demNeighbourRaster

    # calculate the dem aggregate/disaggregate factor for the analysis demCalcSize
    dem2FeatFactor <- as.integer(demCalcSize/featSize)
    # aggregates dem to larger size
    if (dem2FeatFactor > 1.0) {
        dem <- aggregate(dem, fact = c(dem2FeatFactor, dem2FeatFactor))
    }

    # calculate the terrain indices: aspect, slope, flow, etc statistics
    terrainFunc <- c("slope", "aspect", "tri", "tpi", "roughness")
    demTerrain <- terrain(dem, opt = terrainFunc, unit = "degrees", neighbors = 8)
    if (exportRasters) {
        # puts the folder structure trTe/{aspect,flowdir,roughness,slope,tpi,tri}/{demCalcSize}/{Col}/{Row}.tif
        createFolder(outputFolder, 'trTe')
        for (i in 1:length(terrainFunc)) {
            func <- terrainFunc[i]
            createFolder(paste(outputFolder, 'trTe', sep = '/'), demCalcSize)
            createFolder(paste(outputFolder, 'trTe', demCalcSize, sep = '/'), func)
            createFolder(paste(outputFolder, 'trTe', demCalcSize, func, sep = '/'), tileCol)
            # gets the export folder and filename
            exportFolder <- paste(outputFolder, "trTe", demCalcSize, func, tileCol, sep = "/")
            exportFileFunc <- paste(exportFolder, "/", tileRow, ".tif", sep = "")
            # crops the dem tpi to the original feat extent
            demTerrainExt <- crop(demTerrain, featExt)
            demTerrainFunc <<- eval(parse(text = paste("demTerrainExt$", func, sep = "")))
            # puts export raster
            writeRaster(demTerrainFunc, exportFileFunc, overwrite = TRUE)
        }
    }
    # disaggregates dem to smaller size to match feature
    if (dem2FeatFactor > 1.0) {
        demTerrain <- disaggregate(demTerrain, fact=c(dem2FeatFactor, dem2FeatFactor))
    }
    # summarize the terrain indices for every feature in neighbourhood
    featTerrain <- zonal(demTerrain, feat, digits=3, na.rm=TRUE)
    # suffix terrain indices with raster size
    colnames(featTerrain) <- paste("trTe", str_to_title(colnames(featTerrain)), demCalcSize, sep = "")
    # merges the terrain into the feature terrain for the tile
    featTerr <- merge(featTerr, featTerrain, by.x = "trFeatId", by.y = paste("trTeZone", demCalcSize, sep = ""))

    return(featTerr)
}

ktpiIndices <- function(featureFolder, tileCol, tileRow, extension, featureNeighbourRaster, demNeighbourRaster, outputFolder, 
    demCalcSize, kernelSize, exportRasters) {
    # gets feature raster
    feat <- paste(featureFolder, "/", tileCol, "/", tileRow, extension, sep="")
    feat <- raster(feat)
    # copies feature raster for extent
    featExt <- feat
    # initializes feat datastore
    featTpii<- data.frame(trFeatId = integer(length(unique(feat))))
    # populates feat datastore with unique ids
    featTpii$trFeatId <- unique(feat)
    # gets feat raster cell size
    featSize <- xres(feat)

    # gets default demCalcSize if not defined or sets as integer
    if (is.null(demCalcSize)) {
        demCalcSize <- featSize
    } else {
        demCalcSize <- as.integer(demCalcSize)
    }

    # recalculates demCalcSize if too small, too big, or not evenly divisible into raster size
    demCalcSize <- reCalculateDemCalcSize(feat, demCalcSize)

    # gets neighbourhood rasters
    feat <- featureNeighbourRaster
    dem <- demNeighbourRaster

    # calculates the dem aggregate/disaggregate factor
    dem2FeatFactor <- demCalcSize/featSize
    # aggregates dem to larger size
    if (dem2FeatFactor > 1.0) {
        dem <- aggregate(dem, fact=c(dem2FeatFactor, dem2FeatFactor))
    }

    # sets default kernelSize if not defined or sets as integer
    # SHOULD CHANGE kernelSize to neighbourhoodSize
    if (is.null(kernelSize)) {
        kernelSize <- demCalcSize * 5
    } else {
        kernelSize <- as.integer(kernelSize)
    }

    # calculate the nearest kernel size to the neighbourhood size
    kernelDim <- floor((kernelSize * 2) / demCalcSize)
    kernelDim <- kernelDim - (kernelDim %% 2 - 1)
    # defines the kernel matrix
    kernelWindow <- matrix(1, nrow = kernelDim, ncol = kernelDim)
    # calculates the dem topographic position indices within the neighbourhood: mean and the standard deviation
    for (func in c("mean", "sd")) {
        demTpi <- focal(dem, w = kernelWindow, fun = get(func), na.rm = TRUE)
        # calculates the mean difference
        if (func == "mean") {
            # calculates difference between dem and average neighbourhood dem
            demTpi <- overlay(dem, demTpi, fun = function(x,y){(x-y)})
            func <- "MnDif"
        }
        if (exportRasters) {
            # puts folder structure tr_tp/{mean_diff,sd}/{demCalcSize}/{kernelSize}/{Col}/{Row}.tif
            createFolder(outputFolder, 'trTp')
            createFolder(paste(outputFolder, 'trTp', sep = '/'), demCalcSize)
            createFolder(paste(outputFolder, 'trTp', demCalcSize, sep = '/'), func)
            createFolder(paste(outputFolder, 'trTp', demCalcSize, func, sep = '/'), kernelSize)
            createFolder(paste(outputFolder, 'trTp', demCalcSize, func, kernelSize, sep = '/'), tileCol)
            # gets the export folder and filename
            exportFolder <- paste(outputFolder, "trTp", demCalcSize, func, kernelSize, tileCol, sep = "/")
            exportFileFunc <- paste(exportFolder, "/", tileRow, ".tif", sep = "")
            # crops the dem tpi to the original feat extent
            demTpiExt <- crop(demTpi, featExt)
            # puts export raster
            writeRaster(demTpiExt, exportFileFunc, overwrite = TRUE)
        }
        # disaggregates dem to smaller size to match feature
        if (dem2FeatFactor > 1.0) {
            demTpi <- disaggregate(demTpi, fact = c(dem2FeatFactor, dem2FeatFactor))
        } else if (dem2FeatFactor == 1.0) {
            demTpi <- demTpi
        }

        # crop disaggregated dem to match feature
        demTpi <- crop(demTpi, feat)

        # summarizes the tpi within the neighbourhood for every feat
        featTpi <- zonal(demTpi, feat, digits = 0, na.rm = TRUE)
        # adds new column based on the dem size, neighbourhood size, kernel size, and function
        alias <- sprintf("%sC%d%sK%d", "trTp", demCalcSize, str_to_title(func), kernelSize)
        colnames(featTpi) <- c("trFeatId", alias)
        # merges the results into the previous neighbourhood iterations
        featTpii <- merge(featTpii, featTpi, by = "trFeatId")
    }

    return(featTpii)
}
