suppressMessages(library(raster, quietly = TRUE))
suppressMessages(library(rgdal, quietly = TRUE))
suppressMessages(library(jsonlite))

# gets tile number from tile file path "/<folder>/<col>/<row>.jpg"
getTMSFolderZoomColRowExt <- function(filePath) {
    # filePath <- "/topo/feat/34/56.jpg"
    # parse the path by folder structure: topo feat col row.jpg
    filePathPrs <- unlist(strsplit(filePath,"[// /\\]"))
    # get the folder path: topo/feat/
    fileFolder <- filePathPrs[1]
    for (i in 2:(length(filePathPrs)-2)) {
        fileFolder <- paste(fileFolder, filePathPrs[i], sep = "/")
    }
    # fileFolder <- paste(fileFolder, "/", sep = "")
    # tile row is the second last parse: col
    tileCol <- as.integer(filePathPrs[length(filePathPrs)-1])
    # filename.ext is the last parse: row.jpg
    fileWExt <- filePathPrs[length(filePathPrs)]
    # parse the filename.ext by .: row jpg
    fileWExtPrs <- unlist(strsplit(fileWExt,"[//.]"))
    # tile row is the first parse: row
    tileRow <- as.integer(fileWExtPrs[1])
    # file extension is the last parse: .jpg
    fileExt <- paste("." , fileWExtPrs[length(fileWExtPrs)], sep = "")

    return(list(fileFolder = fileFolder,
        tileCol = tileCol,
        tileRow = tileRow,
        fileExt = fileExt))
}

# get neighbouring raster images within a kernelSize
getTMSTileFileNeighbours <- function(fileFolder, tileCol, tileRow, fileExt, kernelSize) {
    # gets filename
    filePath <- file.path(fileFolder, tileCol, tileRow)
    filePath <- paste(filePath, fileExt, sep = "")
    # initializes neighbour list
    neighbourFileList <- c(filePath)
    # gets raster
    r <- raster(filePath)
    # gets the smallest dimension (x OR y) of the current tile
    xDim <- ncol(r) * xres(r)
    yDim <- nrow(r) * xres(r)
    minDim <- xDim
    if (minDim > yDim) minDim <- yDim

    # gets default kernelSize if not defined
    if (is.null(kernelSize)) {
        kernelSize <- minDim
    } else {
        kernelSize <- as.integer(kernelSize)
    }

    # gets the number of tile rings to cover the buffer kernelSize
    tileRing <- ceiling (kernelSize / minDim)

    # gets all the tiles in the kernelSize
    # iterates from current tile column - tileRing to current tile column + tileRing
    for (col in (-1 * tileRing):tileRing) {
        neighbourCol <- tileCol + col
        # iterates from current tile row - tileRing to current tile row + tileRing
        for (row in (-1 * tileRing):tileRing) {
            neighbourRow <- tileRow + row
            neighbour <- file.path(fileFolder, neighbourCol, neighbourRow)
            neighbour <- paste(neighbour, fileExt, sep = "")
            # print(neighbour)
            # adds neighbour to list if neighbour col or row >=0, there are no negative col/row tiles
            if (neighbourCol >= 0 & neighbourRow >= 0) {
                neighbourFileList <- c(neighbourFileList, neighbour)
            }
        }
    }
    # removes duplicate neighbours (ie. current tile)
    neighbourFileList <- sort(unique(neighbourFileList))
    # return list of tile file neighbours
    return(neighbourFileList)
}

# merges neighbour rasters in a list
mergeRasters <- function(neighbourFileList) {
    # initializes mergedNeighbourRasters raster
    mergedNeighbourRasters <- raster(neighbourFileList[1])
    # merges all other rasters
    for (file in neighbourFileList[2:length(neighbourFileList)]) {
        tryCatch({
            r <- raster(file)
            mergedNeighbourRasters <- merge(mergedNeighbourRasters, r)
        }, warning = function(w) {
            print(w)
        }, error = function(e) {
            print(e)
        })
    }
    # return merged neighbour raster
    return(mergedNeighbourRasters)
}

# initializes indice table with unique features and cell count
getFeatureIdCount <- function(fileFolder, tileCol, tileRow, fileExt) {
    # gets filename
    filePath <- file.path(fileFolder, tileCol, tileRow)
    filePath <- paste(filePath, fileExt, sep = "")
    # gets raster
    feat <- raster(filePath)
    # gets the tile number from the column_row
    tile <- paste(tileCol, tileRow, sep = "/")
    # initializes the indices dataframe for the tile
    indic <- data.frame(featid = integer(length(unique(feat))), tile = character(length(unique(feat))))
    # populates feature statistics with the unique zone in the tile
    indic$featid <- unique(feat)
    # populates feature statistics with the tile number
    indic$tile <- tile
    # calculates the cell frequency for every feature in the tile
    featidFreq <- freq(feat, merge=TRUE)
    # creates field names 'zone' and 'count_tile_<dem resolution>' in feature frequency dataframe
    colnames(featidFreq) <- c("featid", paste("cells", xres(feat), sep = "_"))
    # merges dataframes indices and feature frequency
    indic <- merge(indic, featidFreq, by = "featid")
    # return indice table
    return(indic)
}

# calculates the nearest raster cell calculation size to the requested calcSize which is a function of the size of the input raster
reCalculateDemCalcSize <- function(feat, calcSize){
    # recalculates calcSize if too small, too big, or not evenly divisible into raster size
    # TO DO: there is probably a better way of handling this see: https://github.com/tesera/ktpi/issues/11
    featSize <- xres(feat)
    if (calcSize < featSize) calcSize <- featSize
    featDim <- ncol(feat)
    if (calcSize > as.integer(featSize * featDim)) calcSize <- as.integer(featSize * featDim)
    if (as.integer(featDim*featSize)%%calcSize != 0) {
        calcSizeNeg <- calcSize
        calcSizePos <- calcSize
        repeat {
            calcSizeNeg <- calcSizeNeg - 1
            if (as.integer(featDim*featSize)%%calcSizeNeg==0) break;
            calcSizePos <- calcSizePos + 1
            if (as.integer(featDim*featSize)%%calcSizePos==0) break;
        }
        if (as.integer(featDim*featSize)%%calcSizeNeg == 0) {
            calcSize <- calcSizeNeg
        } else {
            calcSize <- calcSizePos
        }
    }

    return(calcSize)
}

# set the output data folder
createFolder <- function(folderPath, newFolder) {
    # check if folder path exists
    newPath <- paste(folderPath, newFolder, sep = '/')
    if (file.exists(newPath)) {
    } else {
        dir.create(file.path(folderPath, newFolder))
    }
}

# get neighbouring raster images within a kernelSize, and within a min&max col&row
getNeighbourhoodCR <- function(tileCol, tileRow, minCol, maxCol, minRow, maxRow, 
    rasterCells, rasterCellSize, kernelSize) {
    tileCol <- as.integer(tileCol)
    tileRow <- as.integer(tileRow)
    minCol <- as.integer(minCol)
    maxCol <- as.integer(maxCol)
    minRow <- as.integer(minRow)
    maxRow <- as.integer(maxRow)
    # initializes neighbour list
    neighbourhoodCR <- c()
    # gets the raster dimension
    rasterSize <- as.integer(rasterCells) * as.integer(rasterCellSize)
    # gets the number of tile rings to cover the buffer kernelSize
    tileRing <- ceiling (as.integer(kernelSize) / rasterSize)

    # gets all the row,col in the kernelSize
    # iterates from current tile column - tileRing to current tile column + tileRing
    for (col in (-1 * tileRing):tileRing) {
        neighbourCol <- as.integer(tileCol) + col
        # iterates from current tile row - tileRing to current tile row + tileRing
        for (row in (-1 * tileRing):tileRing) {
            neighbourRow <- as.integer(tileRow) + row
            # adds neighbour to list if neighbour col or row >= min col or row AND col or row <= max col or row
            if ((neighbourCol >= minCol & neighbourCol <= maxCol & neighbourRow >= minRow & neighbourRow <= maxRow)) {
                neighbour <- paste(neighbourCol, neighbourRow, sep = "/")
                neighbourhoodCR <- c(neighbourhoodCR, neighbour)
            }
        }
    }
    neighbourhoodCRchar <- paste(as.character(neighbourhoodCR), collapse = ";")
    # return data frame of tile file neighbours
    return(neighbourhoodCRchar)
}

getNeighbours <- function(prepend = "", tilecol = NULL, tilerow = NULL, append = "", tilecolmin = NULL, tilecolmax = NULL, tilerowmin = NULL, tilerowmax = NULL, rastercells = NULL, rastercellsize = NULL, neighbourhood = NULL, tiles) {
  tilecol <- as.integer(tilecol)
  tilerow <- as.integer(tilerow)
  tilecolmin <- as.integer(tilecolmin)
  tilecolmax <- as.integer(tilecolmax)
  tilerowmin <- as.integer(tilerowmin)
  tilerowmax <- as.integer(tilerowmax)

  if (is.null(neighbourhood)) {
    tilering <- 1
  } else {
    rastercells <- as.integer(rastercells)
    rastercellsize <- as.numeric(rastercellsize)
    neighbourhood <- as.integer(neighbourhood)
    rastersize <- rastercells * rastercellsize
    tilering <- ceiling (neighbourhood / rastersize)
  }

  neighbourList <- c()

  for (col in (-1 * tilering):tilering) {
    neighbourcol <- tilecol + col
    for (row in (-1 * tilering):tilering) {
      neighbourrow <- as.integer(tilerow) + row
      if ((neighbourcol >= tilecolmin && neighbourcol <= tilecolmax && neighbourrow >= tilerowmin && neighbourrow <= tilerowmax)) {
        tile <- paste(neighbourcol, neighbourrow, sep="/")
        if (any(tile==tiles) | tiles == "none" ) { 
          neighbour <- paste(prepend, neighbourcol, "/", neighbourrow, append, sep = "")
          neighbourList <- c(neighbourList, neighbour)
        }
      }
    }
  }
  return (neighbourList)
}

# get min values for every column in indic
getIndicColMinVal <- function(indic) sapply(indic, min, na.rm = TRUE)

# get max values for every column in indic
getIndicColMaxVal <- function(indic) sapply(indic, max, na.rm = TRUE)

# get mean values for every column in indic
getIndicColMeanVal <- function(indic) sapply(indic, mean, na.rm = TRUE)

# get stdev values for every column in indic
getIndicColStdevVal <- function(indic) sapply(indic, sd, na.rm = TRUE)

# create all the ktpi CLI arguments based on the user request
createKtpiCLICommands <- function(ktpiFunction, featureFolder, demFolder, extension, outputFolder, 
    tileColMin, tileColMax, tileRowMin, tileRowMax, rasterCells, rasterCellSize, 
    demCalcSize, kernelFrom, kernelTo, kernelStep, orientations, exportRasters = FALSE, tilesfile, tiles) {
    ktpiScr <- "./ktpi.R"
    kernelFrom <- as.integer(kernelFrom)
    kernelTo <- as.integer(kernelTo)
    kernelStep <- as.integer(kernelStep)
    if (exportRasters) { exportRasters <- "--exp-rast" } else { exportRasters <- "" }
    sizeCount <- length(demCalcSize)
    i <- 0
    ktpiCLICommands <- c()
    for (func in ktpiFunction) {
        for (col in tileColMin:tileColMax) {
            for (row in tileRowMin:tileRowMax) {
                if (tiles == "none" | paste(col, row, sep="/") %in% tiles) { 
                    CR <- paste(col, row, sep = "/")
                    featureFile <- paste(featureFolder, "/", CR, ".tif", sep = "")
                    if (func == "statistic" | func == "terrain") {
                        for (size in unique(demCalcSize)){
                            # additionalArgs <- paste("-d", size, exportRasters, sep = " ")
                            # ktpiCLICommand <- paste(ktpiScr, func, featureFile, demFolder, outputFolder, additionalArgs)
                            ktpiCLICommand <- paste("ktpi.R", func, "-p", featureFolder, "-q", demFolder, "-c", col, "-r", row, "-a", extension, "-w", tileColMin, "-x", tileColMax, "-y", tileRowMin, "-z", tileColMax, "-m", rasterCellSize, "-n", rasterCells, "-d", size, "-l", tilesfile, "-u", outputFolder, exportRasters)
                            ktpiCLICommands <- c(ktpiCLICommands, ktpiCLICommand)
                        }
                    }
                    if (func == "ktpi") {
                        for (size in 1:sizeCount) {
                            kernels <- seq(kernelFrom[size], kernelTo[size], by = kernelStep[size])
                            for (kernel in kernels) {
                                # additionalArgs <- paste("-d", demCalcSize[size], "-k", kernel, exportRasters, sep = " ")
                                # ktpiCLICommand <- paste(ktpiScr, func, featureFile, demFolder, outputFolder, additionalArgs)
                                ktpiCLICommand <- paste("ktpi.R", func, "-p", featureFolder, "-q", demFolder, "-c", col, "-r", row, "-a", extension, "-w", tileColMin, "-x", tileColMax, "-y", tileRowMin, "-z", tileColMax, "-m", rasterCellSize, "-n", rasterCells, "-d", demCalcSize[size], "-k", kernel, "-l", tilesfile, "-u", outputFolder, exportRasters)
                                ktpiCLICommands <- c(ktpiCLICommands, ktpiCLICommand)
                            }
                        }
                    }
                    if (func == "kaspSlp" | func == "kaspDir" | 
                        func == "kaspSDir" | func == "kaspCDir" | func == "kaspSlpSDir" | func == "kaspSlpCDir" | 
                        func == "kaspSlpEle2" | func == "kaspSlpEle2SDir" | func == "kaspSlpEle2CDir" | 
                        func == "kaspSlpLnEle" | func == "kaspSlpLnEleSlpSDir" | func == "kaspSlpLnEleSlpCDir") {
                        for (size in 1:sizeCount) {
                            kernels <- seq(kernelFrom[size], kernelTo[size], by = kernelStep[size])
                            for (kernel in kernels) {
                                neighbourhoodCR <- getNeighbourhoodCR(col, row, tileColMin, tileColMax, tileRowMin, tileRowMax, 
                                    rasterCells, rasterCellSize, kernel)
                                for (orient in orientations) {
                                    # orientation <- paste("-o", orient, sep = " ")
                                    # additionalArgs <- paste("-d", demCalcSize[size], "-k", kernel, orientation, exportRasters, sep = " ")
                                    # ktpiCLICommand <- paste(ktpiScr, func, featureFile, demFolder, outputFolder, additionalArgs)
                                    ktpiCLICommand <- paste("ktpi.R", func, "-p", featureFolder, "-q", demFolder, "-c", col, "-r", row, "-a", extension, "-w", tileColMin, "-x", tileColMax, "-y", tileRowMin, "-z", tileColMax, "-m", rasterCellSize, "-n", rasterCells, "-d", demCalcSize[size], "-k", kernel, "-o", orient, "-l", tilesfile, "-u", outputFolder, exportRasters)
                                    ktpiCLICommands <- c(ktpiCLICommands, ktpiCLICommand)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    write.table(ktpiCLICommands, sep = ",", append = TRUE, row.names = FALSE, col.names = FALSE, quote = FALSE)
}

# create all the ktpi CLI arguments based on the user request
createKtpiJSONMessages <- function(ktpiFunction, featureFolder, demFolder, extension, outputFolder, 
    tileColMin, tileColMax, tileRowMin, tileRowMax, rasterCells, rasterCellSize, 
    demCalcSize, kernelFrom, kernelTo, kernelStep, orientations, exportRasters = FALSE, tilesfile, tiles) {
    kernelFrom <- as.integer(kernelFrom)
    kernelTo <- as.integer(kernelTo)
    kernelStep <- as.integer(kernelStep)
    if (exportRasters) { exportRasters <- "--exp-rast" } else { exportRasters <- "" }
    sizeCount <- length(demCalcSize)
    i <- 0
    ktpiJSONMessages <- data.frame(getdata = character(0), runcommand = character(0), stringsAsFactors = FALSE)
    for (func in ktpiFunction) {
        for (col in tileColMin:tileColMax) {
            for (row in tileRowMin:tileRowMax) {
                if (tiles == "none" | paste(col, row, sep="/") %in% tiles) {
                    CR <- paste(col, row, sep = "/")
                    featureFile <- paste(featureFolder, CR, extension, sep = "")
                    if (func == "statistic" | func == "terrain") {
                        for (size in unique(demCalcSize)) {
                            kernel <- 1
                            ktpiJSONMessage <- data.frame(getdata = character(1), runcommand = character(1), stringsAsFactors = FALSE)
                            # ktpi.R neighbours -p ../test/exp-input/features/ -c 3 -r 4 -a .tif -w 2 -x 4 -y 3 -z 5 -m 1 -n 2000 -k 100 -l tiles.txt
                            featureNeighbourCmd <- paste("ktpi.R neighbours -p", featureFolder, "-c", col, "-r", row, "-a", extension, "-w", tileColMin, "-x", tileColMax, "-y", tileRowMin, "-z", tileRowMax, "-m", rasterCellSize, "-n", rasterCells, "-k", kernel, "-l", tilesfile, sep = " ")
                            demNeighbourCmd <- paste("ktpi.R neighbours -p", demFolder, "-c", col, "-r", row, "-a", extension, "-w", tileColMin, "-x", tileColMax, "-y", tileRowMin, "-z", tileRowMax, "-m", rasterCellSize, "-n", rasterCells, "-k", kernel, "-l", tilesfile, sep = " ")
                            ktpiJSONMessage$getdata <- list(c(featureNeighbourCmd, demNeighbourCmd))
                            # ktpi.R statistic -p ../test/exp-input/features/ -q ../test/exp-input/dems/ -c 3 -r 4 -a .tif -w 1 -x 99 -y 1 -z 99 -m 1 -n 2000 -d 5 -l tiles.txt -u ../
                            runCmd <- paste("ktpi.R", func, "-p", featureFolder, "-q", demFolder, "-c", col, "-r", row, "-a", extension, "-w", tileColMin, "-x", tileColMax, "-y", tileRowMin, "-z", tileColMax, "-m", rasterCellSize, "-n", rasterCells, "-d", size, "-l", tilesfile, "-u", outputFolder, exportRasters)
                            ktpiJSONMessage$runcommand <- c(runCmd)
                            ktpiJSONMessages <- rbind(ktpiJSONMessages, ktpiJSONMessage)
                        }
                    }
                    if (func == "ktpi") {
                        for (size in 1:sizeCount) {
                            kernels <- seq(kernelFrom[size], kernelTo[size], by = kernelStep[size])
                            for (kernel in kernels) {
                                ktpiJSONMessage <- data.frame(getdata = character(1), runcommand = character(1), stringsAsFactors = FALSE)
                                # ktpi.R neighbours -p ../test/exp-input/features/ -c 3 -r 4 -a .tif -w 2 -x 4 -y 3 -z 5 -m 1 -n 2000 -k 100 -l tiles.txt
                                featureNeighbourCmd <- paste("ktpi.R neighbours -p", featureFolder, "-c", col, "-r", row, "-a", extension, "-w", tileColMin, "-x", tileColMax, "-y", tileRowMin, "-z", tileRowMax, "-m", rasterCellSize, "-n", rasterCells, "-k", kernel, "-l", tilesfile, sep = " ")
                                demNeighbourCmd <- paste("ktpi.R neighbours -p", demFolder, "-c", col, "-r", row, "-a", extension, "-w", tileColMin, "-x", tileColMax, "-y", tileRowMin, "-z", tileRowMax, "-m", rasterCellSize, "-n", rasterCells, "-k", kernel, "-l", tilesfile, sep = " ")
                                ktpiJSONMessage$getdata <- list(c(featureNeighbourCmd, demNeighbourCmd))
                                # additionalArgs <- paste("-d", demCalcSize[size], "-k", kernel, exportRasters, "-l", tilesfile, sep = " ")
                                # runCmd <- paste(ktpiScr, func, featureFile, demFolder, outputFolder, additionalArgs)
                                # ktpi.R ktpi -p ../test/exp-input/features/ -q ../test/exp-input/dems/ -c 3 -r 4 -a .tif -w 1 -x 99 -y 1 -z 99 -m 1 -n 2000 -d 5 -k 100 -l tiles.txt -u ../
                                runCmd <- paste("ktpi.R", func, "-p", featureFolder, "-q", demFolder, "-c", col, "-r", row, "-a", extension, "-w", tileColMin, "-x", tileColMax, "-y", tileRowMin, "-z", tileColMax, "-m", rasterCellSize, "-n", rasterCells, "-d", demCalcSize[size], "-k", kernel, "-l", tilesfile, "-u", outputFolder, exportRasters)
                                ktpiJSONMessage$runcommand <- c(runCmd)
                                ktpiJSONMessages <- rbind(ktpiJSONMessages, ktpiJSONMessage)
                            }
                        }
                    }
                    if (func == "kaspSlp" | func == "kaspDir" | 
                        func == "kaspSDir" | func == "kaspCDir" | func == "kaspSlpSDir" | func == "kaspSlpCDir" | 
                        func == "kaspSlpEle2" | func == "kaspSlpEle2SDir" | func == "kaspSlpEle2CDir" | 
                        func == "kaspSlpLnEle" | func == "kaspSlpLnEleSlpSDir" | func == "kaspSlpLnEleSlpCDir") {
                        for (size in 1:sizeCount) {
                            kernels <- seq(kernelFrom[size], kernelTo[size], by = kernelStep[size])
                            for (kernel in kernels) {
                                neighbourhoodCR <- getNeighbourhoodCR(col, row, tileColMin, tileColMax, tileRowMin, tileRowMax, 
                                    rasterCells, rasterCellSize, kernel)
                                for (orient in orientations) {
                                    # orientation <- paste("-o", orient, sep = " ")
                                    ktpiJSONMessage <- data.frame(getdata = character(1), runcommand = character(1), stringsAsFactors = FALSE)
                                    # ktpi.R neighbours -p ../test/exp-input/features/ -c 3 -r 4 -a .tif -w 2 -x 4 -y 3 -z 5 -m 1 -n 2000 -k 100 -l tiles.txt
                                    featureNeighbourCmd <- paste("ktpi.R neighbours -p", featureFolder, "-c", col, "-r", row, "-a", extension, "-w", tileColMin, "-x", tileColMax, "-y", tileRowMin, "-z", tileRowMax, "-m", rasterCellSize, "-n", rasterCells, "-k", kernel, "-l", tilesfile, sep = " ")
                                    demNeighbourCmd <- paste("ktpi.R neighbours -p", demFolder, "-c", col, "-r", row, "-a", extension, "-w", tileColMin, "-x", tileColMax, "-y", tileRowMin, "-z", tileRowMax, "-m", rasterCellSize, "-n", rasterCells, "-k", kernel, "-l", tilesfile, sep = " ")
                                    ktpiJSONMessage$getdata <- list(c(featureNeighbourCmd, demNeighbourCmd))
                                    # additionalArgs <- paste("-d", demCalcSize[size], "-k", kernel, orientation, exportRasters, "-l", tilesfile, sep = " ")
                                    # runCmd <- paste(ktpiScr, func, featureFile, demFolder, outputFolder, additionalArgs)
                                    # ktpi.R kaspSlp -p ../test/exp-input/features/ -q ../test/exp-input/dems/ -c 3 -r 4 -a .tif -w 1 -x 99 -y 1 -z 99 -m 1 -n 2000 -d 5 -k 100 -o across -l tiles.txt -u ../
                                    runCmd <- paste("ktpi.R", func, "-p", featureFolder, "-q", demFolder, "-c", col, "-r", row, "-a", extension, "-w", tileColMin, "-x", tileColMax, "-y", tileRowMin, "-z", tileColMax, "-m", rasterCellSize, "-n", rasterCells, "-d", demCalcSize[size], "-k", kernel, "-o", orient, "-l", tilesfile, "-u", outputFolder, exportRasters)
                                    ktpiJSONMessage$runcommand <- c(runCmd)
                                    ktpiJSONMessages <- rbind(ktpiJSONMessages, ktpiJSONMessage)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    writeLines(toJSON(ktpiJSONMessages, pretty = TRUE))
}
