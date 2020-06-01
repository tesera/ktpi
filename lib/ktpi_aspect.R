suppressMessages(library(rgdal, quietly = TRUE))
suppressMessages(library(raster, quietly = TRUE))

kaspIndices <- function(func = c("kaspSlp", "kaspDir", 
    "kaspSDir", "kaspCDir", "kaspSlpSDir", "kaspSlpCDir",
    "kaspSlpEle2", "kaspSlpEle2SDir", "kaspSlpEle2CDir",
    "kaspSlpLnEle", "kaspSlpLnEleSlpSDir", "kaspSlpLnEleSlpCDir"),
    featureFolder, tileCol, tileRow, extension, featureNeighbourRaster, demNeighbourRaster, outputFolder, 
    demCalcSize, kernelSize, exportRasters,
    orientation = c("across", "uphill", "downhill")) {

    # gets feature raster
    feat <- paste(featureFolder, "/", tileCol, "/", tileRow, extension, sep="")
    feat <- raster(feat)
    # copies feature raster for extent
    featExt <- feat
    # initializes feat datastore
    featKaspi<- data.frame(featid = integer(length(unique(feat))))
    # populates feat datastore with unique ids
    featKaspi$featid <- unique(feat)
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
    dem2FeatFactor <- as.integer(demCalcSize/featSize)
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

    # define the kernel matrix ring needed for the focal function
    kaspRingMatrix <- function(kernelDim) {
        # ie. kernelDim=7, set a matrix of boundary values =1

        ringMatrix <- matrix(0, nrow = kernelDim, ncol = kernelDim)
        ringMatrix[c(1,kernelDim), ] <- 1
        ringMatrix[ ,c(1,kernelDim)] <- 1
        ringMatrix[(kernelDim+1)/2,(kernelDim+1)/2] <- 1
        # 1 1 1 1 1 1 1
        # 1 0 0 0 0 0 1
        # 1 0 0 0 0 0 1
        # 1 0 0 1 0 0 1
        # 1 0 0 0 0 0 1
        # 1 0 0 0 0 0 1
        # 1 1 1 1 1 1 1
        return(ringMatrix) # a matrix of boundary values =1, and the inside =0
    }

    # get the matrix offset coordinates from the centroid
    kaspRingCentroidXYoffsetMatrix <- function(ringMatrix, kernelDim) {
        # ie. kernelDim=7, set the boundary value based on the distance from the centroid
        kernelDim <- sqrt(length(ringMatrix))
        rc <- rep(list(),2) # list of 2 values
        offsetMatrix <- matrix(rc, nrow = kernelDim, ncol = kernelDim) # create a 7x7 matrix of lists of 2 values
        for (i in 1:kernelDim) { # 1-7, set the values of the cells to the absolute x & y offset from the centre cell
            for (j in 1:kernelDim) { # 1-7
                offsetMatrix[[i,j]] <- c(abs(i-(kernelDim+1)/2),abs((kernelDim+1)/2-j))# 7x7 matrix of lists of x & y dimensions from center cell
                if (i > (kernelDim+1)/2) offsetMatrix[[i,j]][1] <- offsetMatrix[[i,j]][1] * -1
                if (j < (kernelDim+1)/2) offsetMatrix[[i,j]][2] <- offsetMatrix[[i,j]][2] * -1
            }
        }
        #  3,-3  3,-2  3,-1  3,0  3,1  3,2  3,3
        #  2,-3  2,-2  2,-1  2,0  2,1  2,2  2,3
        #  1,-3  1,-2  1,-1  1,0  1,1  1,2  1,3
        #  0,-3  0,-2  0,-1  0,0  0,1  0,2  0,3
        # -1,-3 -1,-2 -1,-1 -1,0 -1,1 -1,2 -1,3
        # -2,-3 -2,-2 -2,-1 -2,0 -2,1 -2,2 -2,3
        # -3,-3 -3,-2 -3,-1 -3,0 -3,1 -3,2 -3,3
        return(offsetMatrix)
    }

    # get the weighted distance of each ring cell from the centroid
    kaspRingWeightMatrix <- function(offsetMatrix, ringMatrix, kernelDim) {
        weightMatrix <- matrix(0, nrow = kernelDim, ncol = kernelDim)
        for (i in 1:kernelDim) { # 1-7, set the values of the matrix based on the distance to the centre cell
            for (j in 1: kernelDim) { # 1-7
                weightMatrix[i,j] <- ringMatrix[i,j] * ((kernelDim-1)/2) / ((offsetMatrix[[i,j]][1])^2+(offsetMatrix[[i,j]][2])^2)^(1/2) # 7x7 matrix of distances from center cell
                # weightMatrix[i,j] <- ringMatrix[i,j] * ((offsetMatrix[[i,j]][1])^2+(offsetMatrix[[i,j]][2])^2)^(1/2) # 7x7 matrix of distances from center cell
            }
        }
        weightMatrix[((kernelDim+1)/2),((kernelDim+1)/2)] <- 1 # set the matrix centre cell value to 0
        # ? ? ? ? ? ? ?
        # ? 0 0 0 0 0 ?
        # ? 0 0 0 0 0 ?
        # ? 0 0 1 0 0 ?
        # ? 0 0 0 0 0 ?
        # ? 0 0 0 0 0 ?
        # ? ? ? ? ? ? ?
        return(weightMatrix)
    }

    # set the kernel ring matrix cells to 1, non-ring to 0
    ringMatrix <- kaspRingMatrix(kernelDim)

    # get the kernel ring matrix cells offset coordinates from the centroid
    offsetMatrix <- kaspRingCentroidXYoffsetMatrix(ringMatrix, kernelDim)

    # get the kernel ring matrix cells weighted distance from the centroid
    weightMatrix <- kaspRingWeightMatrix(offsetMatrix, ringMatrix, kernelDim)
    weightVector <- as.vector(weightMatrix)

    kaspSlpPcnt <- function(x) {
        elevDiff <- c()
        demRingVector <- as.vector(x)
        centroid <- x[(length(x)+1)/2]
        if (orientation == "uphill") {
            elevDiff <- demRingVector - centroid
            elevDiff <- elevDiff * weightVector
            elevDiffMax <- max(elevDiff)
            demRingVectorItem <- which.max(elevDiff)
            slope <- elevDiffMax/distanceVector[demRingVectorItem]
        }
        if (orientation == "downhill") {
            elevDiff <- centroid - demRingVector
            elevDiff <- elevDiff * weightVector
            elevDiffMax <- max(elevDiff)
            demRingVectorItem <- which.max(elevDiff)
            slope <- elevDiffMax/distanceVector[demRingVectorItem]
        }
        if (orientation == "across") {
            demRingVectorRev <- rev(demRingVector)
            elevDiff <- demRingVectorRev - demRingVector
            elevDiff <- elevDiff * weightVector
            elevDiffMax <- max(elevDiff)
            demRingVectorItem <- which.max(elevDiff)
            slope <- elevDiffMax/(distanceVector[demRingVectorItem]*2)
        }
        return(slope)
    }

    # get the distance of each ring cell from the centroid
    kaspDistMatrix <- function(offsetMatrix, ringMatrix, kernelDim) {
        distanceMatrix <- matrix(0, nrow = kernelDim, ncol = kernelDim)
        for (i in 1:kernelDim) { # 1-7, set the values of the matrix based on the distance to the centre cell
            for (j in 1: kernelDim) { # 1-7
                distanceMatrix[i,j] <- ringMatrix[i,j] * ((offsetMatrix[[i,j]][1])^2+(offsetMatrix[[i,j]][2])^2)^(1/2) * xres(dem) # 7x7 matrix of distances from center cell
            }
        }
        distanceMatrix[((kernelDim+1)/2),((kernelDim+1)/2)] <- 0 # set the matrix centre cell value to 0
        # ? ? ? ? ? ? ?
        # ? 0 0 0 0 0 ?
        # ? 0 0 0 0 0 ?
        # ? 0 0 0 0 0 ?
        # 1 0 0 0 0 0 ?
        # ? 0 0 0 0 0 ?
        # ? ? ? ? ? ? ?
        return(distanceMatrix)
    }

    if (func == "kaspSlp" | func == "kaspSlpEle2" | func == "kaspSlpSDir" | func == "kaspSlpCDir" | 
        func == "kaspSlpLnEle" | func == "kaspSlpLnEleSlpSDir" | func == "kaspSlpLnEleSlpCDir" | 
        func == "kaspSlpEle2SDir" | func == "kaspSlpEle2CDir") {

        # get the kernel ring matrix cells distance from the centroid
        distanceMatrix <- kaspDistMatrix(offsetMatrix, ringMatrix, kernelDim)
        distanceVector <- as.vector(t(distanceMatrix))

        kaspSlp <- focal(dem, w = ringMatrix, fun = kaspSlpPcnt)
    }

    kaspDirdeg <- function(x) {
        elevDiff <- c()
        demRingVector <- as.vector(x)
        centroid <- x[(length(x)+1)/2]
        if (orientation == "uphill") {
            elevDiff <- demRingVector - centroid # highest ring elevation minus centroid elevation
        }
        if (orientation == "downhill") {
            elevDiff <- centroid - demRingVector # centroid elevation minus lowest ring elevation
        }
        if (orientation == "across") {
            demRingVectorRev <- rev(demRingVector)
            elevDiff <- demRingVector - demRingVectorRev # elevations on one side of ring minus elevations on the other side of ring
        }
        elevDiff <- elevDiff * weightVector
        elevDiffMax <- max(elevDiff)
        demRingVectorItem <- which.max(elevDiff) # select the maximum elevation difference (greatest from lowest to highest), ie. upslope
        direction <- directionVectorRev[demRingVectorItem] # direction looking downslope
        return(direction)
    }

    # get the directions of each ring cell from the centroid
    kaspDirMatrix <- function(offsetMatrix, ringMatrix, kernelDim) {
        directionMatrix <- matrix(0, nrow = kernelDim, ncol = kernelDim)
        for (i in 1:kernelDim) { # 1-7, set the values of the cells to the x & y offset from the centre cell
            for (j in 1:kernelDim) { # 1-7
                direction <- atan(offsetMatrix[[i,j]][2]/offsetMatrix[[i,j]][1])*180/pi
                if (i > (kernelDim+1)/2) { direction <- 180 + direction }
                if ((i <= (kernelDim+1)/2) && (j < (kernelDim+1)/2)) { direction <- direction + 360 }
                directionMatrix[i,j] <- direction
                directionMatrix[i,j] <- ringMatrix[i,j] * directionMatrix[i,j]
            }
        }
        directionMatrix[((kernelDim+1)/2),((kernelDim+1)/2)] <- 0 # set the matrix centre cell value to 0
        # 315  ...  ...    0  ...  ...   45
        # ...  315  ...    0  ...   45  ...
        # ...  ...  315    0   45  ...  ...
        # 270  270  270   NA   90   90   90
        # ...  ...  225  180  135  ...  ...
        # ...  225  ...  180  ...  135  ...
        # 225  ...  ...  180  ...  ...  135
        # return(directionMatrix)
        return(directionMatrix)
    }

    if (func == "kaspDir") {

        # get the kernel ring matrix cells direction from the centroid 
        directionMatrix <- kaspDirMatrix(offsetMatrix, ringMatrix, kernelDim)
        directionVector <- as.vector(t(directionMatrix)) # from centroid to ring
        directionVectorRev <- rev(directionVector) # from ring to centroid

        kaspDir <- focal(dem, w = ringMatrix, fun = kaspDirdeg)
    }

    kaspSinDir <- function(x) {
        elevDiff <- c()
        demRingVector <- as.vector(x)
        centroid <- x[(length(x)+1)/2]
        if (orientation == "uphill") {
            elevDiff <- demRingVector - centroid # centroid elevation minus lowest ring elevation
        }
        if (orientation == "downhill") {
            elevDiff <- centroid - demRingVector # centroid elevation minus lowest ring elevation
        }
        if (orientation == "across") {
            demRingVectorRev <- rev(demRingVector)
            elevDiff <- demRingVector - demRingVectorRev # elevations on one side of ring minus elevations on the other side of ring
        }
        elevDiff <- elevDiff * weightVector
        elevDiffMax <- max(elevDiff)
        demRingVectorItem <- which.max(elevDiff) # select the maximum elevation difference (greatest from lowest to highest), ie. upslope
        SDir <- sinVectorRev[demRingVectorItem] # direction looking downslope
        return(SDir)
    }

    # get the sin of each ring cell from the centroid
    kaspSinDirMatrix <- function(offsetMatrix, ringMatrix, kernelDim) {
        sinMatrix <- matrix(0, nrow = kernelDim, ncol = kernelDim)
        for (i in 1:kernelDim) { # 1-7, set the values of the cells to the x & y offset from the centre cell
            for (j in 1:kernelDim) { # 1-7
                SDir <- offsetMatrix[[i,j]][2]/(((offsetMatrix[[i,j]][1])^2+(offsetMatrix[[i,j]][2])^2)^(1/2))
                sinMatrix[i,j] <- SDir
                sinMatrix[i,j] <- ringMatrix[i,j] * sinMatrix[i,j]
            }
        }
        sinMatrix[((kernelDim+1)/2),((kernelDim+1)/2)] <- 0 # set the matrix centre cell value to 0
        return(sinMatrix)
    }

    if (func == "kaspSDir" | func == "kaspSlpSDir" | func == "kaspSlpLnEleSlpSDir" | func == "kaspSlpEle2SDir") {

        # get the kernel ring matrix cells sin of the direction from the centroid
        sinMatrix <- kaspSinDirMatrix(offsetMatrix, ringMatrix, kernelDim)
        sinVector <- as.vector(t(sinMatrix)) # from centroid to ring
        sinVectorRev <- rev(sinVector) # from ring to centroid

        kaspSDir <- focal(dem, w = ringMatrix, fun = kaspSinDir)
    }

    kaspCosDir <- function(x) {
        elevDiff <- c()
        demRingVector <- as.vector(x)
        centroid <- x[(length(x)+1)/2]
        if (orientation == "uphill") {
            elevDiff <- demRingVector - centroid # centroid elevation minus lowest ring elevation
        }
        if (orientation == "downhill") {
            elevDiff <- centroid - demRingVector # centroid elevation minus lowest ring elevation
        }
        if (orientation == "across") {
            demRingVectorRev <- rev(demRingVector)
            elevDiff <- demRingVector - demRingVectorRev # elevations on one side of ring minus elevations on the other side of ring
        }
        elevDiff <- elevDiff * weightVector
        elevDiffMax <- max(elevDiff)
        demRingVectorItem <- which.max(elevDiff) # select the maximum elevation difference (greatest from lowest to highest), ie. upslope
        CDir <- cosVectorRev[demRingVectorItem] # direction looking downslope
        return(CDir)
    }

    # get the cos of each ring cell from the centroid
    kaspCosDirMatrix <- function(offsetMatrix, ringMatrix, kernelDim) {
        cosMatrix <- matrix(0, nrow = kernelDim, ncol = kernelDim)
        for (i in 1:kernelDim) { # 1-7, set the values of the cells to the x & y offset from the centre cell
            for (j in 1:kernelDim) { # 1-7
                CDir <- offsetMatrix[[i,j]][1]/(((offsetMatrix[[i,j]][1])^2+(offsetMatrix[[i,j]][2])^2)^(1/2))
                cosMatrix[i,j] <- CDir
                cosMatrix[i,j] <- ringMatrix[i,j] * cosMatrix[i,j]
            }
        }
        cosMatrix[((kernelDim+1)/2),((kernelDim+1)/2)] <- 0 # set the matrix centre cell value to 0
        return(cosMatrix)
    }

    if (func == "kaspCDir" | func == "kaspSlpCDir" | func == "kaspSlpLnEleSlpCDir" | func == "kaspSlpEle2CDir") {

        # get the kernel ring matrix cells cosine of the direction from the centroid
        cosMatrix <- kaspCosDirMatrix(offsetMatrix, ringMatrix, kernelDim)
        cosVector <- as.vector(t(cosMatrix)) # from centroid to ring
        cosVectorRev <- rev(cosVector) # from ring to centroid

        kaspCDir <- focal(dem, w = ringMatrix, fun = kaspCosDir)
    }

    if (func == "kaspSlp") {
        demKasp <- kaspSlp
        func <- "Slp"
    }

    if (func == "kaspDir") {
        demKasp <- kaspDir
        func <- "Dir"
    }

    if (func == "kaspSDir") {
        demKasp <- kaspSDir
        func <- "SDir"
    }

    if (func == "kaspCDir") {
        demKasp <- kaspCDir
        func <- "CDir"
    }

    if (func == "kaspSlpSDir") {
        demKasp <- kaspSlp * kaspSDir
        func <- "SlSDr"
    }

    if (func == "kaspSlpCDir") {
        demKasp <- kaspSlp * kaspCDir
        func <- "SlCDr"
    }

    if (func == "kaspSlpEle2") {
        demKasp <- kaspSlp * dem^2
        func <- "SlE2"
    }

    if (func == "kaspSlpEle2SDir") {
        demKasp <- kaspSlp * dem^2 * kaspSDir
        func <- "SlEl2SDr"
    }

    if (func == "kaspSlpEle2CDir") {
        demKasp <- kaspSlp * dem^2 * kaspCDir
        func <- "SlEl2CDr"
    }

    if (func == "kaspSlpLnEle") {
        demKasp <- kaspSlp * log( dem + 1 )
        func <- "SlLnEl"
    }

    if (func == "kaspSlpLnEleSlpSDir") {
        demKasp <- kaspSlp * log( dem + 1 ) * kaspSlp * kaspSDir
        func <- "SlLnElSlSDr"
    }

    if (func == "kaspSlpLnEleSlpCDir") {
        demKasp <- kaspSlp * log( dem + 1 ) * kaspSlp * kaspCDir
        func <- "SlLnElSlCDr"
    }

    if (exportRasters) {
        # puts folder structure kasp/{mean_diff,sd}/{demCalcSize}/{kernelSize}/{Zoom}/{Row}/{Col}
        createFolder(outputFolder, 'tr_ka')
        createFolder(paste(outputFolder, 'tr_ka', sep = '/'), demCalcSize)
        createFolder(paste(outputFolder, 'tr_ka', demCalcSize, sep = '/'), orientation)
        createFolder(paste(outputFolder, 'tr_ka', demCalcSize, orientation, sep = '/'), func)
        createFolder(paste(outputFolder, 'tr_ka', demCalcSize, orientation, func, sep = '/'), kernelSize)
        createFolder(paste(outputFolder, 'tr_ka', demCalcSize, orientation, func, kernelSize, sep = '/'), tileCol)
        # gets the export folder and filename
        exportFolder <- paste(outputFolder, "tr_ka", demCalcSize, orientation, func, kernelSize, tileCol, sep = "/")
        exportFileFunc <- paste(exportFolder, "/", tileRow, ".tif", sep = "")
        # crops the dem tpi to the original feat extent
        demKaspExt <- crop(demKasp, featExt)
        # puts export raster
        writeRaster(demKaspExt, exportFileFunc, overwrite = TRUE)
    }

    # disaggregates dem to smaller size to match feature
    if (dem2FeatFactor > 1.0) {
        demKasp <- disaggregate(demKasp, fact = c(dem2FeatFactor, dem2FeatFactor))
    } else if (dem2FeatFactor == 1.0) {
        demKasp <- demKasp
    }

    # crop disaggregated dem to match feature
    demKasp <- crop(demKasp, feat)

    # summarizes the tpi within the neighbourhood for every feat
    featKasp <- zonal(demKasp, feat, digits = 0, na.rm = TRUE)
    # adds new column based on the dem size, neighbourhood size, kernel size, and function
    if (orientation == "uphill") { orientation <- "up" }
    if (orientation == "downhill") { orientation <- "dwn" }
    if (orientation == "across") { orientation <- "acr" }
    alias <- sprintf("%sC%d%sK%dO%s", "trKa", demCalcSize, func, kernelSize, orientation)
    colnames(featKasp) <- c("featid", alias)
    # merges the results into the previous neighbourhood iterations
    featKaspi <- merge(featKaspi, featKasp, by = "featid")

    return(featKaspi)
}
