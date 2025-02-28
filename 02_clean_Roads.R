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

#Roads - clean and split into low, medium, high use
#If roads raster is already made then skip this section
roads_file <- file.path(spatialOutDir,"roadsSR.tif")
if (!file.exists(roads_file)) {
  #Check the types
  unique(roads_sf_in$DRA_ROAD_CLASS)
  unique(roads_sf_in$DRA_ROAD_SURFACE)
  unique(roads_sf_in$OG_DEV_PRE06_PETRLM_DEVELOPMENT_ROAD_TYPE)


  ### Check Petro roads
  #Appears petro roads are typed with SURFACE and CLASSS
  table(roads_sf_in$DRA_ROAD_SURFACE,roads_sf_in$OG_DEV_PRE06_PETRLM_DEVELOPMENT_ROAD_TYPE)
  table(roads_sf_in$DRA_ROAD_CLASS,roads_sf_in$OG_DEV_PRE06_PETRLM_DEVELOPMENT_ROAD_TYPE)

  #Additional petro road checks
  #Check if all petro roads have a OG_DEV_PRE06_PETRLM_DEVELOPMENT_ROAD_TYPE
  tt<-roads_sf_in %>%
    st_drop_geometry() %>%
    dplyr::filter(is.na(DRA_ROAD_CLASS))

  Petro_Tbl <- st_set_geometry(roads_sf_in, NULL) %>%
    count(OG_DEV_PRE06_PETRLM_DEVELOPMENT_ROAD_TYPE, LENGTH_METRES)

  roads_sf_petro <- roads_sf_in %>%
    mutate(DRA_ROAD_SURFACE=if_else(is.na(OG_DEV_PRE06_OG_PETRLM_DEV_RD_PRE06_PUB_ID),DRA_ROAD_SURFACE,'OGC')) %>%
    mutate(DRA_ROAD_CLASS=if_else(is.na(OG_DEV_PRE06_OG_PETRLM_DEV_RD_PRE06_PUB_ID),DRA_ROAD_CLASS,OG_DEV_PRE06_PETRLM_DEVELOPMENT_ROAD_TYPE))

  Petro_Tbl <- st_set_geometry(roads_sf_petro, NULL) %>%
    dplyr::count(DRA_ROAD_SURFACE, DRA_ROAD_CLASS)
  #### End Petro road check

  #Eliminate non-roads
  notRoadsCls <- c("ferry", "water", "Road Proposed")
  notRoadsSurf<-c("boat")

  roads_sf_1<-roads_sf_in %>%
    filter(!DRA_ROAD_CLASS %in% notRoadsCls,
           !DRA_ROAD_SURFACE %in% notRoadsSurf)

  HighUseCls<-c("Road arterial major","Road highway mabjor", "Road arterial minor","Road highway minor",
                "Road collector major","Road collector minor","Road ramp","Road freeway",
                "Road yield lane")

  ModUseCls<-c("Road local","Road recreation","Road alleyway","Road restricted",
               "Road service","Road resource","Road driveway","Road strata",
               "Road resource demographic", "Road strata","Road recreation demographic", "Trail Recreation",
               "Road runway", "Road runway non-demographic", "Road resource non-status" )

  LowUseCls<-c("Road lane","Road skid","Road trail","Road pedestrian","Road passenger",
               "Road unclassified or unknown","Trail", "Trail demographic","Trail skid", "Road pedestrian mall")

  HighUseSurf<-c("paved")
  ModUseSurf<-c("loose","rough")
  LowUseSurf<-c("overgrown","decommissioned","seasonal","unknown")

  #Add new attribute that holds the use classificationr
  roads_sf <- roads_sf_1 %>%
    mutate(RoadUse = case_when((DRA_ROAD_CLASS %in% HighUseCls & DRA_ROAD_SURFACE %in% HighUseSurf) ~ 1, #high use
                               (DRA_ROAD_CLASS %in% LowUseCls | DRA_ROAD_SURFACE %in% LowUseSurf |
                                  (DRA_ROAD_SURFACE %in% ModUseSurf & is.na(DRA_ROAD_NAME_FULL)) |
                                  (is.na(DRA_ROAD_CLASS) & is.na(DRA_ROAD_SURFACE))) ~ 3,#low use
                               TRUE ~ 2)) # all the rest are medium use

  #Check the assignment
  Rd_Tbl <- st_set_geometry(roads_sf, NULL) %>%
    dplyr::count(DRA_ROAD_SURFACE, DRA_ROAD_CLASS, is.na(DRA_ROAD_NAME_FULL), RoadUse)

  #Data check
  nrow(roads_sf)-nrow(roads_sf_1)
  table(roads_sf$RoadUse)

  # Save as RDS for quicker access later.
  saveRDS(roads_sf, file = "tmp/DRA_roads_sf_clean.rds")
  # Also save as geopackage format for use in GIS and for buffer anlaysis below
  write_sf(roads_sf, file.path(spatialOutDir,"roads_clean.gpkg"))

  roads_sf<-readRDS(file = "tmp/DRA_roads_sf_clean.rds")

  #Use Stars to rasterize according to RoadUse and save as a tif
  #first st_rasterize needs a template to 'burn' the lines onto
  template = BCr_S
  template[[1]][] = NA
  roadsSR<-stars::st_rasterize(roads_sf[,"RoadUse"], template)
  write_stars(roadsSR,dsn=file.path(spatialOutDir,'roadsSR.tif'))

  ###removing some files to avoid memory issues:
  remove(roads_sf_petro)
  remove(roads_sf)
  remove(roads_sf_in)
  remove(roads_sf_1)


  } else {
  #Read in raster roads with values 0-none, 1-high use, 2-moderate use, 3-low use)
  roadsR<-terra::rast(file.path(spatialOutDir,'roadsSR.tif'))
}

#Assign road weights for example: H-400, m-100, l-3 - based on values in the disturbance.xlsx spreadsheet in data directory
#Example in data directory Archive folder


LinearDisturbance_LUT<-data.frame(rdCode=c(1,2,3,0),
                                  Resistance=c(400,100,3,0),
                                  SourceWt=c(0,0,0.75,0),
                                  BinaryHF=c(1,1,1,0))


####Buffering Roads and adding resistance wrights####
#get each use level in a different raster:
roads_buf_file <- file.path(spatialOutDir,"roadsSR_buffered.tif")

if (!file.exists(roads_buf_file)) {

  roadsR_l<-list()
for(i in 1:3){
  roadsR_l[[i]]<-terra::mask(roadsR,
            roadsR,
            inverse=T,
            maskvalue=i)
  }

#buffer each type
#500m for 1; 100m and 500m for 2 and 50m for 3
roadsR_l_h<-buffer(roadsR_l[[1]],width=500,background=NA)#high use
roadsR_l_m1<-buffer(roadsR_l[[2]],width=500,background=NA)#moderate
roadsR_l_m2<-buffer(roadsR_l[[2]],width=100,background=NA)#moderate
roadsR_l_l<-buffer(roadsR_l[[3]],width=100,background=NA)#low use


#reclasfy buffers:
#buffers have 50% of the resistance of their origin raster
#(e.g., 500m buffer of high use roads has 50% of the resitance of the actual road)
#for medium roads, 500m buffer has 50% and 100m has 75%

roadsR_l_h_bf<-classify(roadsR_l_h,matrix(data=c(0,LinearDisturbance_LUT %>% filter(rdCode==1) %>% pull(Resistance),
                                  1,LinearDisturbance_LUT %>% filter(rdCode==1) %>% pull(Resistance)*.5),byrow=T,ncol=2))

roadsR_l_m1_bf<-classify(roadsR_l_m1,matrix(data=c(0,LinearDisturbance_LUT %>% filter(rdCode==2) %>% pull(Resistance),
                                  1,LinearDisturbance_LUT %>% filter(rdCode==2) %>% pull(Resistance)*.5),byrow=T,ncol=2))

roadsR_l_m2_bf<-classify(roadsR_l_m2,matrix(data=c(0,LinearDisturbance_LUT %>% filter(rdCode==2) %>% pull(Resistance),
                                  1,LinearDisturbance_LUT %>% filter(rdCode==2) %>% pull(Resistance)*.75),byrow=T,ncol=2))

roadsR_l_l_bf<-classify(roadsR_l_l,matrix(data=c(0,LinearDisturbance_LUT %>% filter(rdCode==3) %>% pull(Resistance),
                                  1,LinearDisturbance_LUT %>% filter(rdCode==3) %>% pull(Resistance)*.5),byrow=T,ncol=2))

roadsR_buffered<-mosaic(
            roadsR_l_h_bf,
            roadsR_l_m1_bf,
            roadsR_l_m2_bf,
            roadsR_l_l_bf,
            fun='max')


writeRaster(roadsR_buffered,file.path(spatialOutDir,"roadsSR_buffered.tif"))

roadsR_buffered<-rast(file.path(spatialOutDir,"roadsSR_buffered.tif"))
saveRDS(roadsR_buffered,file.path(spatialOutDir,"roadsSR_buffered.rds"))

}else{
  roadsR_buffered<-rast(file.path(spatialOutDir,"roadsSR_buffered.tif"))

}


###Roads - source surface####


roadsB_W_file<-file.path(spatialOutDir,"roadsB_W.tif")
if (!file.exists(roadsB_W_file)) {

roadsB_W1<-subst(roadsR, c(1,2,3,0), c(NA,NA,1,NA))
roadsB_W_b<-buffer(roadsB_W1,width=100,background=NA)
roadsB_W<-subst(roadsB_W_b,c(0,1),c(0.75,.5))

writeRaster(roadsB_W, filename=file.path(spatialOutDir,'roadsB_W.tif'), overwrite=TRUE)
}else{
  roadsB_W<-rast(file.path(spatialOutDir,"roadsB_W.tif"))
}




