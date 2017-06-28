mydata = read.csv("mountain.csv")
mymatrix = as.matrix(mydata)
rasterextent <- extent(c(500245,500490,5600245,5600490))
extent(myraster) <- rasterextent
crs(myraster) <- "+proj=utm +zone=12 +ellps=GRS80 +datum=NAD83 +units=m +no_defs"
writeRaster(myraster, filename="mountain.tif", format="GTiff")