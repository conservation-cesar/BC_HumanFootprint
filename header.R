library(sf)
library(dplyr)
library(readr)
library(raster)
library(bcmaps)
#library(rgdal)
library(fasterize)
library(readxl)
library(mapview)
library(WriteXLS)
library(foreign)
library(ggplot2)
library(ggnewscale)
library(viridis)
library(stars)
library(RCurl)
library(terra)
library(reticulate)
library(rgee)
library(remotes)
#remotes::install_github("r-earthengine/rgeeExtra")
library(rgeeExtra)
library(geojsonio)
library('future')
library(googledrive)





OutDir <- 'out'
dataOutDir <- file.path(OutDir,'data')
tileOutDir <- file.path(dataOutDir,'tile')
figsOutDir <- file.path(OutDir,'figures')
spatialOutDir <- file.path(OutDir,'spatial')
SpatialDir <- file.path('data','spatial')
rgee_Dir<-file.path('data','rgee_exports')
DataDir <- 'data'
#Change this to a local path for storing footprint data as input to conservation connectivity model
CorrDir<- file.path('H:/GitHub/BC_ConservationConnectivity/out/spatial/ConnData')
#Local directory of GIS files such as HillShade for plotting
GISLibrary<- file.path('/Users/darkbabine/ProjectLibrary/Library/GISFiles/BC')
####Replace with your own path for r-miniconda####

#r-miniconda needs to be installed first
RETICULATE_PYTHON<-reticulate::conda_list()[1,2]
envname_c <- "C:/Users/cestevo/rgee"
#EARTHENGINE_ENV<-Sys.setenv("EARTHENGINE_ENV"=envname_c)
#RETICULATE_PYTHON<-file.path("C:/Users/cestevo/AppData/Local/r-miniconda/")

###Add your own path for a virtual env; might not be necessary

dir.create(envname_c)
dir.create(file.path(OutDir), showWarnings = FALSE)
dir.create(file.path(dataOutDir), showWarnings = FALSE)
dir.create(file.path(tileOutDir), showWarnings = FALSE)
dir.create(file.path(figsOutDir), showWarnings = FALSE)
dir.create(DataDir, showWarnings = FALSE)
dir.create("tmp", showWarnings = FALSE)
dir.create("tmp/AOI", showWarnings = FALSE)
dir.create(file.path(spatialOutDir), showWarnings = FALSE)
dir.create(file.path(SpatialDir), showWarnings = FALSE)
dir.create(file.path(rgee_Dir), showWarnings=FALSE)





