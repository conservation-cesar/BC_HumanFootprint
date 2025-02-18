# Copyright 2021 Province of British Columbia
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

source('header.R')
#The first two config rgee scripts are meant to set up the Google Earth Engine in R,
#including installing python, locating it,  and setting up authentication
#Users will need a gmail account to be able to load earth engine.
#Setting up GEE may require a few restarts of the machine, so users might need to run the 'header.R' script again

#Installing miniconda might be needed before proceeding

reticulate::install_miniconda()

#Miniconda should be in the correct path automatically and following steps should run wihtout major problems
#This step will also prompt a restart of r session; it is suggested to restart the session
source('00_rgee_config1.R')


#The following produces a Dynamic World map of basic landscape cover that are meant to
#replace the basic thematic mapping used by the Human Footprint Layer
#Reload the header.R first after the session re-start
source('header.R')
source('00_rgee_config3.R')

#only run load if neccessary - clean
source("01_load.R")
#Clips input to AOI - current options include:
AOI <- readRDS('tmp/BC') #Province
#AOI <- ws %>% #Watershed
#  filter(SUB_SUB_DRAINAGE_AREA_NAME == "Bulkley")
#AOI <- EcoRegions %>% #EcoRegion
#  filter(ECOREGION_NAME == "EASTERN HAZELTON MOUNTAINS")

#clean will clip to AOI
source("02_clean_Area.R")
source("02_clean_Roads.R",catch.aborts = TRUE)

source("03_analysis.R")
#run it you want to use for doing binary intact lands
source("03_analysis_BinaryIntact.R")

source("04_output.R")

