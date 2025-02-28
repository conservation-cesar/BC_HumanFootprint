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

#Assign weights to layer - based on age of cutbocks
#this is built off the spreadsheet built off raster's legend in data directory
#More recent cutblocks will have the same resistance level as the current level from the lookup table

#Load the excel file created previously and get the cutblokcs only
AreaDisturbance_LUT<-data.frame(read_excel(file.path(DataDir,'AreaDisturbance_LUT_lookup.xlsx'))) %>%
  filter(grepl("Cutblock",disturb)) %>%
  dplyr::select(ID=disturb_Code,Resistance,SourceWt, BinaryHF)

#Getting the lowest and highest age of the cutblocks
minmax_cutblock_age<-c(
  cellStats(raster(file.path(spatialOutDir,'cblock_sf_raster.tif')),"min"),
  cellStats(raster(file.path(spatialOutDir,'cblock_sf_raster.tif')),"max")
  )


#Create a lookup table
AreaDisturbance_LUT_cblock<-data.frame(Resistance=seq(from=min(AreaDisturbance_LUT$Resistance),max(AreaDisturbance_LUT$Resistance),length.out=10),
           SourceWt=seq(from=max(AreaDisturbance_LUT$SourceWt),min(AreaDisturbance_LUT$SourceWt),length.out=10),
          Age=seq(min(minmax_cutblock_age),max(minmax_cutblock_age),length.out=10),
          BinaryHF=1) %>% mutate_at(c("Resistance",'Age'),round)

#Create a matrix to reclassify the cutblock raster:
AreaDisturbance_LUT_cblock$Age2<- AreaDisturbance_LUT_cblock$Age %>% lag

AreaDisturbance_LUT_cblock_reclass<-AreaDisturbance_LUT_cblock %>% dplyr::select(Age2,Age,Resistance) %>%
  as.matrix()

#Provincial weights
cblock_sf_raster_WP_file <- file.path(spatialOutDir,"cblock_sf_raster_WP.tif")
if (!file.exists(cblock_sf_raster_WP_file)) {
  cblock_sf_raster_WP<-classify(rast(file.path(spatialOutDir,'cblock_sf_raster.tif')),
                                  rcl=AreaDisturbance_LUT_cblock_reclass,
                                  include.lowest=T)

  writeRaster(cblock_sf_raster_WP, filename=file.path(spatialOutDir,'cblock_sf_raster_WP'), format="GTiff", overwrite=TRUE)

 }else{
   cblock_sf_raster_WP<-rast(file.path(spatialOutDir,'cblock_sf_raster_WP.tif'))
 }


##############
#Source  Layer
#Similarly to the above, but now for source weight
AreaSource_LUT_cblock_reclass<-AreaDisturbance_LUT_cblock %>% dplyr::select(Age2,Age,SourceWt) %>%
  as.matrix()

#Provincial source
source_cutblock_file <- file.path(spatialOutDir,"source_cutblock.tif")


if (!file.exists(source_cutblock_file)) {

  source_cutblock<-classify(rast(file.path(spatialOutDir,'cblock_sf_raster.tif')),
                        rcl=AreaSource_LUT_cblock_reclass)
writeRaster(source_cutblock, file.path(spatialOutDir,"source_cutblock.tif"), overwrite=TRUE)

}else{
  source_cutblock<-rast(file.path(spatialOutDir,'source_cutblock.tif'))
}

##################

#Buffering freshwater and reclassifying it to

#Get sf of disturbance and filter for water polygons
#it is easier to buffer polygons than the raster
water_file<-file.path(spatialOutDir,'water_buffered.tif')

water_resistance_wgt<-data.frame(
  water_class=c(3,100,200,300,400,500),
  Resistance=c(4,3,3,2,2,1)
)

if (!file.exists(water_file)) {


disturbance_sfR<-terra::rast(file.path(spatialOutDir,'disturbance_sfR.tif'))


water_r<-terra::mask(disturbance_sfR,
            disturbance_sfR,
            inverse=T,
            maskvalue=3)

#buffering freshwater from 100 to 500 from shore
water_bf100<-buffer(water_r,width=100,background=NA)
water_bf200<-buffer(water_r,width=200,background=NA)
water_bf300<-buffer(water_r,width=300,background=NA)
water_bf400<-buffer(water_r,width=400,background=NA)
water_bf500<-buffer(water_r,width=500,background=NA)

#Rreclasfiying each portion of the buffer for easy identification and classification for resistance weighting
water_bf100<-classify(water_bf100,matrix(data=c(0,1,100),ncol=3),include.lowest=T,others=NA)
water_bf200<-classify(water_bf200,matrix(data=c(0,1,200),ncol=3),include.lowest=T,others=NA)
water_bf300<-classify(water_bf300,matrix(data=c(0,1,300),ncol=3),include.lowest=T,others=NA)
water_bf400<-classify(water_bf400,matrix(data=c(0,1,400),ncol=3),include.lowest=T,others=NA)
water_bf500<-classify(water_bf500,matrix(data=c(0,1,500),ncol=3),include.lowest=T,others=NA)


#Saving for later:

writeRaster(water_bf100,
            filename=file.path(spatialOutDir,'water_bf100.tif'), overwrite=TRUE)
writeRaster(water_bf200,
            filename=file.path(spatialOutDir,'water_bf200.tif'), overwrite=TRUE)
writeRaster(water_bf300,
            filename=file.path(spatialOutDir,'water_bf300.tif'), overwrite=TRUE)
writeRaster(water_bf400,
            filename=file.path(spatialOutDir,'water_bf400.tif'), overwrite=TRUE)
writeRaster(water_bf500,
            filename=file.path(spatialOutDir,'water_bf500.tif'), overwrite=TRUE)


water_bf100<-rast(file.path(spatialOutDir,'water_bf100.tif'))
water_bf200<-rast(file.path(spatialOutDir,'water_bf200.tif'))
water_bf300<-rast(file.path(spatialOutDir,'water_bf300.tif'))
water_bf400<-rast(file.path(spatialOutDir,'water_bf400.tif'))
water_bf500<-rast(file.path(spatialOutDir,'water_bf500.tif'))


water_buffered<-mosaic(water_r,
                    water_bf100,
                    water_bf200,
                    water_bf300,
                    water_bf400,
                    water_bf500,fun=min)


water_buffered<-classify(
  water_buffered,
  water_resistance_wgt
  )


writeRaster(water_buffered,
            filename=file.path(spatialOutDir,'water_buffered.tif'),
            overwrite=T)

saveRDS(water_buffered,file='tmp/water_buffered.rds')

water_buffered<-readRDS(file='tmp/water_buffered')


#Source raster:
water_source<-subst(water_buffered,from=c(4,3,2,1),to=c(0,0.75,0.5,1),others=NA)


writeRaster(water_source,
            filename=file.path(spatialOutDir,'water_source.tif'),
            overwrite=T)

saveRDS(water_source,file='tmp/water_source.rds')


}else{

  water_buffered<-readRDS(file='tmp/water_buffered.rds')
  water_source<-readRDS(file='tmp/water_source.rds')

}




