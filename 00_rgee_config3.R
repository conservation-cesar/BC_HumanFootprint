
#ee_Authenticate()
ee_Initialize(drive=T) #easier to get the data is you can updload to google drive

#BC ecoregions to get natural regions from rgee:e
bc<-ecoregions(ask=F)

###Split bc ecoregions by ecoregion name:
bc_eco<-split(bc,bc$ECOREGION_CODE)


#get unique names:
unique_region_names<-names(bc_eco)

#iniate for loop:
for(i in unique_region_names){

bc_roi<-bc_eco[[i]]

bc_ee<-sf_as_ee(bc_roi)
bc_ee<-ee$FeatureCollection(bc_ee)
## inspection. Filter by region and date.
START <- ee$Date('2023-05-02')
END <- START$advance(1, 'year')

colFilter <- ee$Filter$And(
  ee$Filter$bounds(bc_ee),
  ee$Filter$date(START, END),
)

# colFilter <- ee$Filter$And(
#   ee$Filter$bounds(ee$Geometry$Point(20.6729, 52.4305)),
#   ee$Filter$date(START, END),
# )


dwCol <- ee$ImageCollection('GOOGLE/DYNAMICWORLD/V1')$
  filter(colFilter)$
  map(function(x){
    return(x$clip(bc_ee))
  })

## Define list pairs of DW LULC label and color.
CLASS_NAMES <- c(
  'water', 'trees', 'grass', 'flooded_vegetation', 'crops',
  'shrub_and_scrub', 'built' , 'bare', 'snow_and_ice')

dwCol_select<-dwCol$select('label')$reduce(ee$Reducer$mode())

rast_dw<-ee_as_rast(
  image= dwCol_select,
  container= '2023_dw_raw_classes',
  region = ee$Geometry$bounds(bc_ee),
  scale= 50,
  maxPixels= 1e10
)

terra::writeRaster(rast_dw,file.path(rgee_Dir,paste0("rast_dw_50_",i,".tif")),overwrite=TRUE)


}

#####Create a mosaic with all ecoregions##########################################################
dw_rasters<-list.files(rgee_Dir,pattern = "rast_dw_50",full.names =T) %>%
  lapply(rast)

dw_mosaic<-terra::mosaic(dw_rasters,fun="max",
                         filename=file.path(rgee_Dir,"dw_mosaic.tif"))
