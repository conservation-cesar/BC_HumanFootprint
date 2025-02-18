library("rgee")
library(reticulate)
library(geojsonio)


py_install("geemap")
rgee::ee_install_upgrade()
library(rgeeExtra)
