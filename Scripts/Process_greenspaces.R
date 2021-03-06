
## Process OS greenspaces 

library(sf)

# load greenspaces
grsp <- st_read('Data/raw_data/OS_greenspaces/OS Open Greenspace (ESRI Shape File) GB/data/GB_GreenspaceSite.shp')
grsp

grsp_geo <- st_transform((grsp), crs = 27700)

# for some reason has a Z-layer after being read in, even though .shp files can't have a Z dimension...? 
# Drop it.
t_ggeo <- st_zm(grsp_geo, drop = T)
t_ggeo

# plot(t_ggeo$geometry)

# # Write the transformed data to file doesn't work...
# st_write(t_ggeo, dsn = 'Data/raw_data/OS_greenspaces/OS Open Greenspace (ESRI Shape File) GB/data/GB_GreenspaceSite_BNG.shp', 
#          driver = "ESRI Shapefile", delete_layer = T)

t_geo_r <- st_read('Data/raw_data/OS_greenspaces/OS Open Greenspace (ESRI Shape File) GB/data/GB_GreenspaceSite_BNG.shp')
t_geo_r

plot(st_geometry(t_geo_r)) # this works but takes ages



#####     split Greenspaces up into grids    ##### 
st_crs(t_geo_r) <- 27700

# read in map and grid of desired cell size
uk <- st_read('/data/notebooks/rstudio-setupconsthomas/DECIDE_constraintlayers/Data/raw_data/UK_grids/uk_map.shp')
uk_grid <- st_read('/data/notebooks/rstudio-setupconsthomas/DECIDE_constraintlayers/Data/raw_data/UK_grids/uk_grid_10km.shp')

st_crs(uk) <- 27700
st_crs(uk_grid) <- 27700

plot(st_geometry(uk), reset = T)
plot(st_geometry(uk_grid), add = T, border = 'orange')

# all in one line
(t_geo_r)[st_intersects(t_geo_r, uk_grid[3,], sparse = F),]

## so, now is easy to loop through and save the footpaths in each grid to file
## will need to redo this once we have the footpaths for scotland and missing places
length(simp_grid_uk)
t_geo_r


doParallel::registerDoParallel(detectCores()-1)

system.time(
  foreach(i = 1:length(st_geometry(uk_grid))) %dopar% {
    print(i)

    grid_sub <- t_geo_r[st_intersects(t_geo_r, uk_grid[i,], sparse = F),]

    if(dim(grid_sub)[1] > 0){ ## if grid cell contains some of shape
      
      print('###   grid contains greenspace   ###')
      
      st_write(grid_sub, dsn = paste0('Data/raw_data/OS_greenspaces/OS Open Greenspace (ESRI Shape File) GB/data/gridded_greenspace_data_10km/grnspc_gridnumber_',i,'.shp'),
               driver = "ESRI Shapefile", delete_layer = T)
      
    }
    
    
    # saveRDS(grid_sub, 
    #         file = paste0('Data/raw_data/OS_greenspaces/OS Open Greenspace (ESRI Shape File) GB/data/gridded_greenspace_data/grnspc_gridnumber_',i,'.rds')) 
    
  }
)





#####      Access points    ####
#####  load access points
# acp <- st_read('Data/raw_data/OS_greenspaces/OS Open Greenspace (ESRI Shape File) GB/data/GB_AccessPoint.shp')
# acp
# 
# acp_geo <- st_transform((acp), crs = 27700)
# 
# # for some reason has a Z-layer after being read in, even though .shp files can't have a Z dimension...? 
# # Drop it.
# t_acp_geo <- st_zm(acp_geo, drop = T)
# t_acp_geo

# # write
# st_write(t_acp_geo, dsn = 'Data/raw_data/OS_greenspaces/OS Open Greenspace (ESRI Shape File) GB/data/GB_AccessPoint_BNG.shp', 
#          driver = "ESRI Shapefile", delete_layer = T)


t_acp_geo <- st_read('Data/raw_data/OS_greenspaces/OS Open Greenspace (ESRI Shape File) GB/data/GB_AccessPoint_BNG.shp')
t_acp_geo

#####     split access points up into grids    ##### 
st_crs(t_acp_geo) <- 27700

# read in map and grid of desired cell size
uk <- st_read('/data/notebooks/rstudio-setupconsthomas/DECIDE_constraintlayers/Data/raw_data/UK_grids/uk_map.shp')
uk_grid <- st_read('/data/notebooks/rstudio-setupconsthomas/DECIDE_constraintlayers/Data/raw_data/UK_grids/uk_grid_10km.shp')

st_crs(uk) <- 27700
st_crs(uk_grid) <- 27700

plot(st_geometry(uk), reset = T)
plot(st_geometry(uk_grid), add = T, border = 'orange')


# get all the paths in grid number 3
g <- (uk_grid[100,])
plot(g, add = T, border = 'red')

ints <- st_intersects(t_acp_geo, g, sparse = F)
unique(ints)

# all in one line
(t_acp_geo)[st_intersects(t_acp_geo, uk_grid[[3]], sparse = F),]

## so, now is easy to loop through and save the footpaths in each grid to file
## will need to redo this once we have the footpaths for scotland and missing places
length(simp_grid_uk)
t_acp_geo

doParallel::registerDoParallel(detectCores()-1)

system.time(
  foreach(i = 1:length(st_geometry(uk_grid))) %dopar% {
    print(i)

    grid_sub <- t_acp_geo[st_intersects(t_acp_geo, uk_grid[i,], sparse = F),]
    
    if(dim(grid_sub)[1] > 0){ ## if grid cell contains some of shape
      
      print('###   grid contains access points   ###')
      
      st_write(grid_sub, dsn = paste0('Data/raw_data/OS_greenspaces/OS Open Greenspace (ESRI Shape File) GB/data/gridded_accesspoint_data_10km/accspnt_gridnumber_',i,'.shp'),
               driver = "ESRI Shapefile", delete_layer = T)
      
    }
    
    
    # saveRDS(grid_sub, 
    #         file = paste0('Data/raw_data/OS_greenspaces/OS Open Greenspace (ESRI Shape File) GB/data/gridded_accesspoint_data/accspnt_gridnumber_',i,'.rds')) 
    
  }
)



######     for testing the function works    ######

greenspace = grsp
accesspoints = acp


filter_accessible_locations <- function(location = c(-1.110557, 51.602436),
                                        distance = 10000,
                                        prow,
                                        greenspace,
                                        accesspoints){
  
  dat_sf <- st_sf(st_sfc(st_point(location)), crs = 4326) # load location points, convert to spatial lat/lon
  trans_loc <- st_transform(dat_sf, crs = 27700) # transform to BNG
  buffed <- st_buffer(trans_loc, distance) # create a buffer around the point
  
  # set the coordinates of the PROW dataset to BNG
  st_crs(prow) <- 27700
  
  # get region around PROW
  c_buf <- st_intersection(prow, buffed) # crop the sf object -  
  
  # get geometry greenspaces and transform (not actually changing, just adding extra bits to match buffer)
  grsp_geo <- st_transform(st_geometry(grsp), crs = 27700)
  st_crs(t_geo_r) <- 27700
  
  # get greenspaces within distance from location
  grsp_buf <- st_intersection(t_geo_r, buffed) # crop the sf object -  
  
  # get access points geometries
  accp_geo <- st_transform(st_geometry(accesspoints), crs = 27700)
  
  # get access points within distance from location
  accp_buf <- st_intersection(accp_geo, buffed) # crop the sf object -  
  
  
  plot(grsp_buf$geometry, col = rgb(0,255,0,max = 255, alpha = 100))
  plot(accp_buf, col = 'red', pch = 20, cex = 0.3, add = T)
}


