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

#Clean Disturbance  Layer

#Assign weights to layer - based on values in spreadsheet built off raster's legend in data directory
AreaDisturbance_LUT<-data.frame(read_excel(file.path(DataDir,'AreaDisturbance_LUT_lookup.xlsx'))) %>%
  dplyr::select(ID=disturb_Code,Resistance,SourceWt, BinaryHF)

#Provincial weights
disturbance_WP_file <- file.path(spatialOutDir,"disturbance_WP.tif")
if (!file.exists(disturbance_WP_file)) {
  disturbance_WP<-subs(raster(file.path(spatialOutDir,'disturbance_sfR.tif')), AreaDisturbance_LUT, by='ID',which='Resistance')
  writeRaster(disturbance_WP, filename=file.path(spatialOutDir,'disturbance_WP'), format="GTiff", overwrite=TRUE)

 }else{
   disturbance_WP<-raster(file.path(spatialOutDir,'disturbance_WP.tif'))
 }



#Binary Version
disturbanceB_WP_file <- file.path(spatialOutDir,"disturbanceB_WP.tif")
if (!file.exists(disturbanceB_WP_file)) {

disturbanceB_WP<-subs(raster(file.path(spatialOutDir,'disturbance_sfR.tif')), AreaDisturbance_LUT, by='ID',which='BinaryHF')
disturbanceB_WP[disturbanceB_WP==0]<-NA
writeRaster(disturbanceB_WP, filename=file.path(spatialOutDir,'disturbanceB_WP'), format="GTiff", overwrite=TRUE)

}else{
  disturbanceB_WP<-raster(file.path(spatialOutDir,'disturbanceB_WP.tif'))

}

#May add decay associated with roads...

##############
#Source  Layer
#Assign source weights to layer - based on values in spreadsheet built off raster's legend
#uses same layer disturbance layer but assigns different values

#Provincial source
source_WP_file <- file.path(spatialOutDir,"source_WP.tif")
if (!file.exists(source_WP_file)) {

source_WP<-subs(raster(file.path(spatialOutDir,'disturbance_sfR.tif')), AreaDisturbance_LUT, by='ID',which='SourceWt')
writeRaster(source_WP, filename=file.path(spatialOutDir,'source_WP'), format="GTiff", overwrite=TRUE)

}else{
  source_WP<-raster(file.path(spatialOutDir,'source_WP.tif'))
}
##################
##Clipping to AOI
#AOI weights

disturbance_R_AOI_file <- file.path(spatialOutDir,"Prov_HumanDisturb.tif")

if (!file.exists(disturbance_R_AOI_file)) {
AOI_rast<-terra::rast(file.path(spatialOutDir,"BCr.tif"))
disturbance_R_AOI<-terra::rast(file.path(spatialOutDir,'disturbance_sfR.tif')) %>%
  #crop(AOI) %>%
  terra::mask(AOI_rast,filename=file.path(spatialOutDir,'Prov_HumanDisturb.tif'),
              overwrite=TRUE)
#writeRaster(disturbance_R_AOI, filename=file.path(spatialOutDir,'Prov_HumanDisturb'), format="GTiff", overwrite=TRUE)
disturbance_W<-terra::subst(disturbance_R_AOI, from=AreaDisturbance_LUT$ID,to=AreaDisturbance_LUT$Resistance,
                            filename=file.path(spatialOutDir,'Prov_HumanDisturb_W.tif'),overwrite=TRUE)
#writeRaster(disturbance_W, filename=file.path(spatialOutDir,'Prov_HumanDisturb_W'), format="GTiff", overwrite=TRUE)

}else{
disturbance_R_AOI<-raster(file.path(spatialOutDir,'Prov_HumanDisturb.tif'))
disturbance_W<-raster(file.path(spatialOutDir,"Prov_HumanDisturb_W.tif"))
}
#AOI source
source_R_AOI<-terra::rast(file.path(spatialOutDir,'Prov_HumanDisturb.tif'))

source_W_file <- file.path(spatialOutDir,"source_W.tif")

if (!file.exists(source_W_file)) {

  #source_W<-subst(disturbance_R_AOI, AreaDisturbance_LUT, by='ID',which='SourceWt')
source_W<-subst(source_R_AOI, from=AreaDisturbance_LUT$ID,to=AreaDisturbance_LUT$SourceWt,
                filename=file.path(spatialOutDir,"source_W.tif"),overwrite=TRUE)

#writeRaster(file.path(spatialOutDir,"source_W"), format="GTiff", overwrite=TRUE)
}else{
  source_W<-raster(file.path(spatialOutDir,"source_W.tif"))
}

