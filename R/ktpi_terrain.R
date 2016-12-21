library(rgdal, quietly = TRUE)
library(raster, quietly = TRUE)

statisticIndices <- function(featureFile, featureNeighbourRaster, demNeighbourRaster, outputFolder, 
    demCalcSize, exportRasters, tileCol, tileRow) {
    # gets feature raster
    feat <- raster(featureFile)
    # copies feature raster for extent
    featExt <- feat
    # initializes the feature statistics for the featureFile
    featStat <- data.frame(featid = integer(length(unique(feat))))
    # populates feature statistics with the unique feat in the featureFile
    featStat$featid <- unique(feat)
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
        colnames(res) <- c("featid", paste("tr_st", func, demCalcSize, sep = "_"))
        # merges the statistic into the feature statistics for the featureFile
        featStat <- merge(featStat, res, by = "featid", quotes = FALSE)
        if (exportRasters) {
            # puts the folder structure tr_st/{min,max,mean,sd}/{demCalcSize}/{Col}/{Row}.tif
            createFolder(outputFolder, 'tr_st')
            createFolder(paste(outputFolder, 'tr_st', sep = '/'), func)
            createFolder(paste(outputFolder, 'tr_st', func, sep = '/'), demCalcSize)
            createFolder(paste(outputFolder, 'tr_st', func, demCalcSize, sep = '/'), tileCol)
            # gets the export folder and filename
            exportFolder <- paste(outputFolder, "tr_st", func, demCalcSize, tileCol, sep = "/")
            exportFileFunc <- paste(exportFolder, "/", tileRow, ".tif", sep = "")
            featExtSubs <- subs(featExt, data.frame(res))
            # puts export raster
            writeRaster(featExtSubs, exportFileFunc, overwrite = TRUE)
        }
    }
    return(featStat)
}

terrainIndices <- function(featureFile, featureNeighbourRaster, demNeighbourRaster, outputFolder, 
    demCalcSize, exportRasters, tileCol, tileRow) {
    # gets feature raster
    feat <- raster(featureFile)
    # copies feature raster for extent
    featExt <- feat
    # initializes the feature statistics for the tile
    featTerr<- data.frame(featid = integer(length(unique(feat))))
    # populates feature statistics with the unique feat in the tile
    featTerr$featid <- unique(feat)
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
        # puts the folder structure tr_te/{aspect,flowdir,roughness,slope,tpi,tri}/{demCalcSize}/{Col}/{Row}.tif
        createFolder(outputFolder, 'tr_te')
        for (i in 1:length(terrainFunc)) {
            func <- terrainFunc[i]
            createFolder(paste(outputFolder, 'tr_te', sep = '/'), func)
            createFolder(paste(outputFolder, 'tr_te', func, sep = '/'), demCalcSize)
            createFolder(paste(outputFolder, 'tr_te', func, demCalcSize, sep = '/'), tileCol)
            # gets the export folder and filename
            exportFolder <- paste(outputFolder, "tr_te", func, demCalcSize, tileCol, sep = "/")
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
    colnames(featTerrain) <- paste("tr_te", colnames(featTerrain), demCalcSize, sep = "_")
    # merges the terrain into the feature terrain for the tile
    featTerr <- merge(featTerr, featTerrain, by.x = "featid", by.y = paste("tr_te_zone", demCalcSize, sep = "_"))

    return(featTerr)
}

ktpiIndices <- function(featureFile, featureNeighbourRaster, demNeighbourRaster, outputFolder, 
    demCalcSize, kernelSize, exportRasters, tileCol, tileRow) {
    # gets feature raster
    feat <- raster(featureFile)
    # copies feature raster for extent
    featExt <- feat
    # initializes feat datastore
    featTpii<- data.frame(featid = integer(length(unique(feat))))
    # populates feat datastore with unique ids
    featTpii$featid <- unique(feat)
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
            func <- "mean_diff"
        }
        if (exportRasters) {
            # puts folder structure tr_tp/{mean_diff,sd}/{demCalcSize}/{kernelSize}/{Col}/{Row}.tif
            createFolder(outputFolder, 'tr_tp')
            createFolder(paste(outputFolder, 'tr_tp', sep = '/'), func)
            createFolder(paste(outputFolder, 'tr_tp', func, sep = '/'), demCalcSize)
            createFolder(paste(outputFolder, 'tr_tp', func, demCalcSize, sep = '/'), kernelSize)
            createFolder(paste(outputFolder, 'tr_tp', func, demCalcSize, kernelSize, sep = '/'), tileCol)
            # gets the export folder and filename
            exportFolder <- paste(outputFolder, "tr_tp", func, demCalcSize, kernelSize, tileCol, sep = "/")
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
        alias <- sprintf("%s_%dm_%dm_%d_%s", "tr_tp", demCalcSize, kernelSize, kernelDim, func)
        colnames(featTpi) <- c("featid", alias)
        # merges the results into the previous neighbourhood iterations
        featTpii <- merge(featTpii, featTpi, by = "featid")
    }

    return(featTpii)
}
