##Plot drawing tool=name
##Draw trial plots=group
##Capture_bottom_left_corner_of_the_trial=point
##Capture_top_left_corner_of_the_trial=point
##Number_of_blocks=string 1
##Number_of_ranges_per_block=string 1
##Number_of_plots_per_range=string 1
##ID_format=selection sequential;serpentine 0
##Start_numbering_plots_from=selection bottom_left;bottom_right;top_left;top_right 0
##Blocks_always_start_on_the_same_side_in_serpentine_format=boolean FALSE
##Starting_ID_if_not_block_design=string 1
##Trial_name=optional string
##Measurement_units_for_plot_size=selection feet;meters 0
##Full_plot_width=string
##Full_plot_height=string
##Data_plot_width=string
##Data_plot_height=string
##Output=output vector

library(sf)
library(terra)

# Convert strings to numbers and feet to meters if necessary
if(Measurement_units_for_plot_size==0){
  plot_width <- as.numeric(Full_plot_width)*0.3048
  plot_height <- as.numeric(Full_plot_height)*0.3048
  data_plot_width <- as.numeric(Data_plot_width)*0.3048
  data_plot_height <- as.numeric(Data_plot_height)*0.3048} else{
    plot_width <- as.numeric(Full_plot_width)
    plot_height <- as.numeric(Full_plot_height)
    data_plot_width <- as.numeric(Data_plot_width)
    data_plot_height <- as.numeric(Data_plot_height)}
start_ID <- as.numeric(Starting_ID_if_not_block_design)
n_blocks <- as.numeric(Number_of_blocks)
n_ranges <- as.numeric(Number_of_ranges_per_block)
n_plots <- as.numeric(Number_of_plots_per_range)
bottom_left <- Capture_bottom_left_corner_of_the_trial
top_left <- Capture_top_left_corner_of_the_trial
restart_side <- Blocks_always_start_on_the_same_side_in_serpentine_format

# Check if coordinates of are projected
if(st_is_longlat(bottom_left)) stop('Input coordinates must be projected (meters)!')

# Draw plots with no spacing between them
# Start by creating a raster with resolution = plot_width x plot_height
x_min <- st_coordinates(bottom_left)[[1,'X']]
x_max <- x_min+plot_width*n_plots
y_min <- st_coordinates(bottom_left)[[1,'Y']]
y_max <- y_min+plot_height*n_blocks*n_ranges
plots <- rast(xmin=x_min, xmax=x_max, ymin=y_min, ymax=y_max, names=c('PlotID'),
              resolution=c(plot_width, plot_height), crs=st_crs(bottom_left)$wkt)
# Assign placeholder values to raster cells
values(plots) <- seq(ncell(plots))

# Assign plot ID

if(n_blocks==1){ # If there are no blocks ('single block')
  
  if(ID_format==0){ # Sequential format
    # Assign plot ID based on starting ID in a sequence
    if(Start_numbering_plots_from==0){ # If numbering starts from the bottom_left
      plots[] <- (start_ID+ncell(plots)-1):start_ID
      for(r in 1:nrow(plots)) plots[r,] <- rev(plots[r,])}
    
    if(Start_numbering_plots_from==1){ # If numbering starts from the bottom_right
      plots[] <- (start_ID+ncell(plots)-1):start_ID}
    
    if(Start_numbering_plots_from==2){ # If numbering starts from the top_left
      plots[] <- start_ID:(start_ID+ncell(plots)-1)}
    
    if(Start_numbering_plots_from==3){ # If numbering starts from the top_right
      plots[] <- start_ID:(start_ID+ncell(plots)-1)
      for(r in 1:nrow(plots)) plots[r,] <- rev(plots[r,])}
    
    # Convert raster cells to polygons
    plots_poly <- st_as_sf(as.polygons(plots, round=FALSE, aggregate=FALSE, values=TRUE, na.rm=TRUE))

  }
  
  if(ID_format==1){ # Serpentine format
    # Assign plot ID based on starting ID in a serpentine
    if(Start_numbering_plots_from==0){ # If numbering starts from the bottom_left
      plots[ncell(plots):1] <- start_ID:(start_ID+ncell(plots)-1)
      inv_rows <- (nrow(plots):1)[seq(1,nrow(plots),2)]}
    
    if(Start_numbering_plots_from==1){ # If numbering starts from the bottom_right
      plots[ncell(plots):1] <- start_ID:(start_ID+ncell(plots)-1)
      inv_rows <- (nrow(plots):1)[seq(2,nrow(plots),2)]}
    
    if(Start_numbering_plots_from==2){ # If numbering starts from the top_left
      plots[1:ncell(plots)] <- start_ID:(start_ID+ncell(plots)-1)
      inv_rows <- seq(2,nrow(plots),2)}
    
    if(Start_numbering_plots_from==3){ # If numbering starts from the top_right
      plots[1:ncell(plots)] <- start_ID:(start_ID+ncell(plots)-1)
      inv_rows <- seq(1,nrow(plots),2)}
    
    # Reverse rows
    for(r in inv_rows) plots[r,] <- rev(plots[r,])
    # Convert raster cells to polygons
    plots_poly <- st_as_sf(as.polygons(plots, round=FALSE, aggregate=FALSE, values=TRUE, na.rm=TRUE))
  }
}

if(n_blocks>1){ # If there are multiple blocks
  
  # Check if number of blocks is greater than 9 to determine number of digits in labels
  n_dig_blocks <- ifelse(n_blocks > 9, 2, 1)
  # Check if number of plots per block is greater than 99 to determine number of digits in labels
  n_dig_entries <- ifelse(n_ranges*n_plots > 99, 3, 2)
  
  if(ID_format==0){ # Sequential format
    # Convert raster cells to polygons
    plots_poly <- st_as_sf(as.polygons(plots, round=FALSE, aggregate=FALSE, values=TRUE, na.rm=TRUE))
    # Assign plot ID based on block and plot number
    for(cell in 1:ncell(plots)){
      if(Start_numbering_plots_from==0){ # If numbering starts from the bottom_left
        block_ID <- sprintf(paste0('%0',n_dig_blocks,'d'), rev(ceiling((1:nrow(plots))/n_ranges))[rowFromCell(plots, cell)])
        range_ID <- rev(rep(1:n_ranges,n_blocks))[rowFromCell(plots, cell)]
        entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
        plots_poly[cell,'PlotID'] <- paste0(block_ID, entry_ID, collapse='')
      }
      
      if(Start_numbering_plots_from==1){ # If numbering starts from the bottom_right
        block_ID <- sprintf(paste0('%0',n_dig_blocks,'d'), rev(ceiling((1:nrow(plots))/n_ranges))[rowFromCell(plots, cell)])
        range_ID <- rev(rep(1:n_ranges,n_blocks))[rowFromCell(plots, cell)]
        entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
        plots_poly[cell,'PlotID'] <- paste0(block_ID, entry_ID, collapse='')
      }
      
      if(Start_numbering_plots_from==2){ # If numbering starts from the top_left
        block_ID <- sprintf(paste0('%0',n_dig_blocks,'d'), ceiling((1:nrow(plots))/n_ranges)[rowFromCell(plots, cell)])
        range_ID <- rep(1:n_ranges,n_blocks)[rowFromCell(plots, cell)]
        entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
        plots_poly[cell,'PlotID'] <- paste0(block_ID, entry_ID, collapse='')
      }
      
      if(Start_numbering_plots_from==3){ # If numbering starts from the top_right
        block_ID <- sprintf(paste0('%0',n_dig_blocks,'d'), ceiling((1:nrow(plots))/n_ranges)[rowFromCell(plots, cell)])
        range_ID <- rep(1:n_ranges,n_blocks)[rowFromCell(plots, cell)]
        entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
        plots_poly[cell,'PlotID'] <- paste0(block_ID, entry_ID, collapse='')
      }
    }
  }
  
  if(ID_format==1){ # Serpentine format
    # Convert raster cells to polygons
    plots_poly <- st_as_sf(as.polygons(plots, round=FALSE, aggregate=FALSE, values=TRUE, na.rm=TRUE))
    
    if(restart_side){ # If blocks should always start on the same side

      # Assign plot ID based on block and plot number
      for(cell in 1:ncell(plots)){
        if(Start_numbering_plots_from==0){ # If numbering starts from the bottom_left
          block_ID <- sprintf(paste0('%0',n_dig_blocks,'d'), rev(ceiling((1:nrow(plots))/n_ranges))[rowFromCell(plots, cell)])
          range_ID <- rev(rep(1:n_ranges,n_blocks))[rowFromCell(plots, cell)]
          if(range_ID%%2==1){ # If the range number is odd
            entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
            plots_poly[cell,'PlotID'] <- paste0(block_ID, entry_ID, collapse='')
          } else{ # If the range number is even
            entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
            plots_poly[cell,'PlotID'] <- paste0(block_ID, entry_ID, collapse='')
          }
        }
        
        if(Start_numbering_plots_from==1){ # If numbering starts from the bottom_right
          block_ID <- sprintf(paste0('%0',n_dig_blocks,'d'), rev(ceiling((1:nrow(plots))/n_ranges))[rowFromCell(plots, cell)])
          range_ID <- rev(rep(1:n_ranges,n_blocks))[rowFromCell(plots, cell)]
          if(range_ID%%2==1){ # If the range number is odd
            entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
            plots_poly[cell,'PlotID'] <- paste0(block_ID, entry_ID, collapse='')
          } else{ # If the range number is even
            entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
            plots_poly[cell,'PlotID'] <- paste0(block_ID, entry_ID, collapse='')
          }
        }
        
        if(Start_numbering_plots_from==2){ # If numbering starts from the top_left
          block_ID <- sprintf(paste0('%0',n_dig_blocks,'d'), ceiling((1:nrow(plots))/n_ranges)[rowFromCell(plots, cell)])
          range_ID <- rep(1:n_ranges,n_blocks)[rowFromCell(plots, cell)]
          if(range_ID%%2==1){ # If the range number is odd
            entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
            plots_poly[cell,'PlotID'] <- paste0(block_ID, entry_ID, collapse='')
          } else{ # If the range number is even
            entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
            plots_poly[cell,'PlotID'] <- paste0(block_ID, entry_ID, collapse='')
          }
        }
        
        if(Start_numbering_plots_from==3){ # If numbering starts from the top_right
          block_ID <- sprintf(paste0('%0',n_dig_blocks,'d'), ceiling((1:nrow(plots))/n_ranges)[rowFromCell(plots, cell)])
          range_ID <- rep(1:n_ranges,n_blocks)[rowFromCell(plots, cell)]
          if(range_ID%%2==1){ # If the range number is odd
            entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
            plots_poly[cell,'PlotID'] <- paste0(block_ID, entry_ID, collapse='')
          } else{ # If the range number is even
            entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
            plots_poly[cell,'PlotID'] <- paste0(block_ID, entry_ID, collapse='')
          }
        }
      }
    } else{ # Else, if blocks should follow the serpentine

      # Assign plot ID based on block and plot number
      for(cell in 1:ncell(plots)){
        if(Start_numbering_plots_from==0){ # If numbering starts from the bottom_left
          block_ID <- sprintf(paste0('%0',n_dig_blocks,'d'), rev(ceiling((1:nrow(plots))/n_ranges))[rowFromCell(plots, cell)])
          range_ID <- rev(rep(1:n_ranges,n_blocks))[rowFromCell(plots, cell)]
          if((nrow(plots):1)[rowFromCell(plots, cell)]%%2==1){ # If the row number is odd
            entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
            plots_poly[cell,'PlotID'] <- paste0(block_ID, entry_ID, collapse='')
          } else{ # If the row number is even
            entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
            plots_poly[cell,'PlotID'] <- rbind(paste0(block_ID, entry_ID, collapse=''))
          }
        }
        
        if(Start_numbering_plots_from==1){ # If numbering starts from the bottom_right
          block_ID <- sprintf(paste0('%0',n_dig_blocks,'d'), rev(ceiling((1:nrow(plots))/n_ranges))[rowFromCell(plots, cell)])
          range_ID <- rev(rep(1:n_ranges,n_blocks))[rowFromCell(plots, cell)]
          if((nrow(plots):1)[rowFromCell(plots, cell)]%%2==1){ # If the row number is odd
            entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
            plots_poly[cell,'PlotID'] <- paste0(block_ID, entry_ID, collapse='')
          } else{ # If the row number is even
            entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
            plots_poly[cell,'PlotID'] <- paste0(block_ID, entry_ID, collapse='')
          }
        }
        
        if(Start_numbering_plots_from==2){ # If numbering starts from the top_left
          block_ID <- sprintf(paste0('%0',n_dig_blocks,'d'), ceiling((1:nrow(plots))/n_ranges)[rowFromCell(plots, cell)])
          range_ID <- rep(1:n_ranges,n_blocks)[rowFromCell(plots, cell)]
          if(rowFromCell(plots, cell)%%2==1){ # If the row number is odd
            entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
            plots_poly[cell,'PlotID'] <- paste0(block_ID, entry_ID, collapse='')
          } else{ # If the row number is even
            entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
            plots_poly[cell,'PlotID'] <- paste0(block_ID, entry_ID, collapse='')
          }
        }
        
        if(Start_numbering_plots_from==3){ # If numbering starts from the top_right
          block_ID <- sprintf(paste0('%0',n_dig_blocks,'d'), ceiling((1:nrow(plots))/n_ranges)[rowFromCell(plots, cell)])
          range_ID <- rep(1:n_ranges,n_blocks)[rowFromCell(plots, cell)]
          if(rowFromCell(plots, cell)%%2==1){ # If the row number is odd
            entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
            plots_poly[cell,'PlotID'] <- paste0(block_ID, entry_ID, collapse='')
          } else{ # If the row number is even
            entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
            plots_poly[cell,'PlotID'] <- paste0(block_ID, entry_ID, collapse='')
          }
        }
      }
    }
  }
}

# Get centroids of the plots to draw inner data plot
plots_centroids <- st_coordinates(st_centroid(st_geometry(plots_poly)))

# Draw inner data plots where data will be extracted
# Start with empty list
data_plots <- st_sf(plots_poly)
# Run through centroids, compute corner of data plots based on data_plot_width
#and data_plot_height, draw the polygon, and add them to the list data_plots
for(p in 1:nrow(plots_centroids)){
  x_min <- plots_centroids[[p,'X']] - data_plot_width/2
  x_max <- plots_centroids[[p,'X']] + data_plot_width/2
  y_min <- plots_centroids[[p,'Y']] - data_plot_height/2
  y_max <- plots_centroids[[p,'Y']] + data_plot_height/2
  data_plots[p,'geometry'] <- st_as_sfc(st_bbox(c(xmin=x_min, xmax=x_max, ymax=y_max, ymin=y_min), crs=st_crs(bottom_left)))
}

# Calculate bearing between the two points in radians
bearing <- pi/2 - atan2(st_coordinates(top_left)[[1,'Y']] - st_coordinates(bottom_left)[[1,'Y']],
                        st_coordinates(top_left)[[1,'X']] - st_coordinates(bottom_left)[[1,'X']])

# Define the rotation matrix
rotation_matrix = function(a) matrix(c(cos(a), sin(a), -sin(a), cos(a)), 2, 2)
# Define a transformer to rotate coordinates
transformer = function(geometries, bearing, center) (geometries - center) * rotation_matrix(bearing) + center
# Rotate plots
rotated_geometries <- transformer(st_geometry(data_plots), bearing, center=bottom_left)

rotated_plots <- st_sf(data_plots, geometry=rotated_geometries)

# Assign coordinate system
st_crs(rotated_plots) <- st_crs(bottom_left)

# Create column with trial name if field is not blank
if(Trial_name!=''){
  rotated_plots$Trial <- Trial_name
  }

# Output vector layer to QGIS
Output <- rotated_plots