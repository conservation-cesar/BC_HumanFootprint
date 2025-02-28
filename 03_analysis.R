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

#loading all the resistance files
#Sumamr of files needed:
#Buffered roads
roadsR_buffered
#Cutblocks:
cblock_sf_raster_WP
#Freshwater:
water_buffered


#Disturbance
disturbance_WP<-rast(file.path(spatialOutDir,'disturbance_WP.tif'))
disturbanceB_WP<-raster(file.path(spatialOutDir,'disturbanceB_WP.tif'))

#Assign resistance_surface
#Combine roads and disturbance areas - assign max weight to pixel
disturbanceStack<-rast(list(disturbance_WP,roadsR_buffered,cblock_sf_raster_WP,water_buffered))
resistance_surface_WP<-max(disturbanceStack,na.rm=T)

#saving
resistance_surface_WP<-writeRaster(resistance_surface_WP,file.path(spatialOutDir,'resistance_surface_WP.tif'),overwrite=T)
saveRDS(resistance_surface_WP,file='tmp/resistance_surface_WP')
resistance_surface_WP<-readRDS('tmp/resistance_surface_WP')

#Assign source_surface
source_surface<-rast(list(roadsB_W, #secondary roads as source only, buffered
                          source_cutblock, #cutblocks
                          water_source, #freshwater, buffered
                          source_WP)) #other sources
source_surface<-min(source_surface,na.rm = T)

#Saving
writeRaster(source_surface,file.path(spatialOutDir,'source_surface.tif'),overwrite=T)
saveRDS(source_surface,file='tmp/source_surface.rds')
source_surface<-readRDS('tmp/source_surface.rds')



