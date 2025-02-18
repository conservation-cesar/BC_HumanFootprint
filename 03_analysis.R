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

roads_WP<-raster(file.path(spatialOutDir,'roads_WP.tif'))
disturbance_WP<-raster(file.path(spatialOutDir,'disturbance_WP.tif'))
disturbanceB_WP<-raster(file.path(spatialOutDir,'disturbanceB_WP.tif'))

#Assign resistance_surface
#Combine roads and disturbance areas - assign max weight to pixel
disturbanceStack<-stack(roads_WP,disturbance_WP)
resistance_surface_WP<-max(disturbanceStack,na.rm=TRUE)

#saving
resistance_surface_WP<-writeRaster(resistance_surface_WP,file.path(spatialOutDir,'resistance_surface_WP.tif'),overwrite=T)
saveRDS(resistance_surface_WP,file='tmp/resistance_surface_WP')
resistance_surface_WP<-readRDS('tmp/resistance_surface_WP')

#Assign source_surface

#Make binary HF
#Buffer roads by 500m
roadsB_W<-terra::rast(file.path(spatialOutDir,'roadsB_W.tif'))
roadsB_W[roadsB_W == 0] <- NA
#writeRaster(roadsB_W, filename=file.path(spatialOutDir,'roadsB_W'), format="GTiff", overwrite=TRUE)
roadsB_buff <- terra::buffer(roadsB_W, width=500)
terra::writeRaster(roadsB_buff, filename=file.path(spatialOutDir,'roadsB_buff.tif'),overwrite=TRUE)
roadsB_buff<-rast(file.path(spatialOutDir,'roadsB_buff.tif'))

roadsB_W_S <- read_stars(file.path(spatialOutDir,'roadsB_W.tif'))
roadsB_W_S_sf<-st_as_sf(roadsB_W_S, as_points=FALSE, na.rm=TRUE)
write_sf(roadsB_W_S_sf, file.path(spatialOutDir,"roadsB_W_S_sf.gpkg"), overwrite=TRUE)

roadsB_W_S_sf<-read_sf(file.path(spatialOutDir,'roadsB_W_S_sf.gpkg'))

roadsB_W_S_sf_U<-st_union(roadsB_W_S_sf, by_feature=FALSE)
write_sf(roadsB_W_S_sf_U, file.path(spatialOutDir,"roadsB_W_S_sf_U.gpkg"), overwrite=TRUE)

roadsB_W_S_sf_U<-read_sf(file.path(spatialOutDir,'roadsB_W_S_sf_U.gpkg'))
roadsB_S_buff<-st_buffer(roadsB_W_S_sf_U, 500)

write_sf(roadsB_S_buff, file.path(spatialOutDir,"roadsB_S_buff.gpkg"), overwrite=TRUE)


HumanFPStack<-stack(roadsB_buff,disturbanceB_WP)
HumanFP_Binary<-max(HumanFPStack,na.rm=TRUE)
writeRaster(HumanFP_Binary, filename=file.path(spatialOutDir,'HumanFP_Binary.tif'), format="GTiff", overwrite=TRUE)

#########
resistance_surface<-terra::rast(file.path(spatialOutDir,"resistance_surface_WP.tif")) %>%
  #mask(AOI) %>%
  terra::mask(terra::rast(file.path(spatialOutDir,"BCr.tif")))


#Omniscape does not accept resistance values of zero or less
#need to reclassify raster to have a minimum value of 1
resistance_surface<-
  terra::classify(resistance_surface,matrix(c(0,1),ncol=2,byrow = T))

#Assign source_surface
source_surface<-terra::rast(file.path(spatialOutDir,"source_WP.tif")) %>%
  #mask(AOI) %>%
  terra::mask(terra::rast(file.path(spatialOutDir,"BCr.tif")))


