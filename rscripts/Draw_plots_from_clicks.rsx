##Draw plots from clicks=name
##Draw trial plots=group
##load_vector_using_rgdal
##Capture_bottom_left_corner_of_the_trial=point
##Capture_top_left_corner_of_the_trial=point
##Number_of_blocks=string 1
##Number_of_ranges_per_block=string 1
##Number_of_plots_per_range=string 1
##ID_format=selection sequential;serpentine 0
##Start_numbering_plots_from=selection bottom_left;bottom_right;top_left;top_right 0
##Starting_ID_if_not_block_design=string 1
##Measurement_units_for_plot_size=selection feet;meters 0
##Full_plot_width=string
##Full_plot_height=string
##Data_plot_width=string
##Data_plot_height=string
##Output=output vector

library(rgeos)
library(maptools)

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

# Check if coordinates of are projected
if(!is.projected(bottom_left)) stop('Input coordinates must be projected (meters)!')

# Draw plots with no spacing between them
# Start by creating a raster with resolution = plot_width x plot_height
x_min <- xmin(bottom_left)
x_max <- x_min+plot_width*n_plots
y_min <- ymin(bottom_left)
y_max <- y_min+plot_height*n_blocks*n_ranges
plots <- raster(xmn=x_min, xmx=x_max, ymn=y_min, ymx=y_max,
                resolution=c(plot_width,plot_height), crs=crs(bottom_left))

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
    plots_poly <- rasterToPolygons(plots)
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
    plots_poly <- rasterToPolygons(plots)
  }
}

if(n_blocks>1){ # If there are multiple blocks
  
  if(ID_format==0){ # Sequential format
    # Convert raster cells to polygons
    plots_poly <- rasterToPolygons(plots)
    # Assign plot ID based on block and plot number
    for(cell in 1:ncell(plots)){
      if(Start_numbering_plots_from==0){ # If numbering starts from the bottom_left
        block_ID <- rev(ceiling((1:nrow(plots))/n_ranges))[rowFromCell(plots, cell)]
        range_ID <- rev(rep(1:n_ranges,n_blocks))[rowFromCell(plots, cell)]
        entry_ID <- sprintf('%02d', colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
        plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
      }
      
      if(Start_numbering_plots_from==1){ # If numbering starts from the bottom_right
        block_ID <- rev(ceiling((1:nrow(plots))/n_ranges))[rowFromCell(plots, cell)]
        range_ID <- rev(rep(1:n_ranges,n_blocks))[rowFromCell(plots, cell)]
        entry_ID <- sprintf('%02d', (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
        plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
      }
      
      if(Start_numbering_plots_from==2){ # If numbering starts from the top_left
        block_ID <- ceiling((1:nrow(plots))/n_ranges)[rowFromCell(plots, cell)]
        range_ID <- rep(1:n_ranges,n_blocks)[rowFromCell(plots, cell)]
        entry_ID <- sprintf('%02d', colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
        plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
      }
      
      if(Start_numbering_plots_from==3){ # If numbering starts from the top_right
        block_ID <- ceiling((1:nrow(plots))/n_ranges)[rowFromCell(plots, cell)]
        range_ID <- rep(1:n_ranges,n_blocks)[rowFromCell(plots, cell)]
        entry_ID <- sprintf('%02d', (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
        plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
      }
    }
  }
  
  if(ID_format==1){ # Serpentine format
    # Convert raster cells to polygons
    plots_poly <- rasterToPolygons(plots)
    # Assign plot ID based on block and plot number
    for(cell in 1:ncell(plots)){
      if(Start_numbering_plots_from==0){ # If numbering starts from the bottom_left
        block_ID <- rev(ceiling((1:nrow(plots))/n_ranges))[rowFromCell(plots, cell)]
        range_ID <- rev(rep(1:n_ranges,n_blocks))[rowFromCell(plots, cell)]
        if(range_ID%%2==1){ # If the range number is odd
          entry_ID <- sprintf('%02d', colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
          plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
        } else{ # If the range number is even
          entry_ID <- sprintf('%02d', (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
          plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
        }
      }
      
      if(Start_numbering_plots_from==1){ # If numbering starts from the bottom_right
        block_ID <- rev(ceiling((1:nrow(plots))/n_ranges))[rowFromCell(plots, cell)]
        range_ID <- rev(rep(1:n_ranges,n_blocks))[rowFromCell(plots, cell)]
        if(range_ID%%2==1){ # If the range number is odd
          entry_ID <- sprintf('%02d', (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
          plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
        } else{ # If the range number is even
          entry_ID <- sprintf('%02d', colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
          plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
        }
      }
      
      if(Start_numbering_plots_from==2){ # If numbering starts from the top_left
        block_ID <- ceiling((1:nrow(plots))/n_ranges)[rowFromCell(plots, cell)]
        range_ID <- rep(1:n_ranges,n_blocks)[rowFromCell(plots, cell)]
        if(range_ID%%2==1){ # If the range number is odd
          entry_ID <- sprintf('%02d', colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
          plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
        } else{ # If the range number is even
          entry_ID <- sprintf('%02d', (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
          plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
        }
      }
      
      if(Start_numbering_plots_from==3){ # If numbering starts from the top_right
        block_ID <- ceiling((1:nrow(plots))/n_ranges)[rowFromCell(plots, cell)]
        range_ID <- rep(1:n_ranges,n_blocks)[rowFromCell(plots, cell)]
        if(range_ID%%2==1){ # If the range number is odd
          entry_ID <- sprintf('%02d', (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
          plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
        } else{ # If the range number is even
          entry_ID <- sprintf('%02d', colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
          plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
        }
      }
    }
  }
}

# Change column name in the polygons data frame to PlotID
names(plots_poly) <- c('PlotID')

# Get centroids of the plots to draw inner data plot
centroids <- gCentroid(plots_poly, byid=TRUE)

# Draw inner data plots where data will be extracted
# Start with empty list
data_plots <- list()
# Run through centroids, compute corner of data plots based on data_plot_width
#and data_plot_height, draw the polygon, and add them to the list data_plots
for(p in 1:length(centroids)){
  x_min <- centroids[p]@coords[1] - data_plot_width/2
  x_max <- centroids[p]@coords[1] + data_plot_width/2
  y_min <- centroids[p]@coords[2] - data_plot_height/2
  y_max <- centroids[p]@coords[2] + data_plot_height/2
  data_plots[[p]] <- bbox2SP(y_max, y_min, x_max, x_min, proj4string=crs(bottom_left))
}
# Combine all Polygons in the list into a single SpatialPolygons object
if(length(data_plots)>1){
  data_plots_poly <- bind(data_plots)} else{
    data_plots_poly <- data_plots[[1]]
  }

# Assign plots_poly IDs to the data_plots_poly layer
data_plots_poly$PlotID <- as.character(plots_poly$PlotID)

# Calculate bearing between the two points
bearing <- 90 - (180/pi)*atan2(ymin(top_left)-ymin(bottom_left),
                               xmin(top_left)-xmin(bottom_left))

# Rotate inner plots to match experiment rotation
rotated_plots <- elide(data_plots_poly, rotate=bearing,
                       center=c(xmin(bottom_left), ymin(bottom_left)))

# Assign coordinate system
crs(rotated_plots) <- crs(bottom_left)

# Output vector layer to QGIS
Output <- rotated_plots