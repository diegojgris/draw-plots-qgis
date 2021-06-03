##Draw plots from polygons=name
##Draw trial plots=group
##load_vector_using_rgdal
##Polygon_vector=vector polygon
##Number_of_blocks=string 1
##Number_of_ranges_per_block=string 1
##Number_of_plots_per_range=string 1
##ID_format=selection sequential;serpentine 0
##Start_numbering_plots_from=selection bottom_left;bottom_right;top_left;top_right 0
##Blocks_always_start_on_the_same_side_in_serpentine_format=boolean FALSE
##Starting_ID_if_single_block=string 1
##Measurement_units_for_plot_size=selection feet;meters 0
##Full_plot_width=string
##Full_plot_height=string
##Data_plot_width=string
##Data_plot_height=string
##Field_containing_trial_names=optional field Polygon_vector
##Output_directory_for_individual_shapefiles=optional folder
##All_trials=output vector

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
start_ID <- as.numeric(Starting_ID_if_single_block)
n_blocks <- as.numeric(Number_of_blocks)
n_ranges <- as.numeric(Number_of_ranges_per_block)
n_plots <- as.numeric(Number_of_plots_per_range)
restart_side <- Blocks_always_start_on_the_same_side_in_serpentine_format

# Check if coordinates of the input vector are projected
if(!is.projected(Polygon_vector)) stop('Coordinates of the input must be projected (meters)!')

# Get experiment names or set to A, B, C...
if(Field_containing_trial_names!=''){
  exper_name <- Polygon_vector[[Field_containing_trial_names]]} else{
    exper_name <- LETTERS[1:length(Polygon_vector)]}

# Create empty list to hold all experiments
all_experiments <- list()

# Run through experiments and draw plots
for(i in 1:length(Polygon_vector)){
  # Get coordinates of the vertices of the polygon
  area_coords <- Polygon_vector[i,]@polygons[[1]]@Polygons[[1]]@coords
  # Get coordinates of the two left-most vertices
  left_coords <- area_coords[order(area_coords[-nrow(area_coords),1]),][1:2,]
  # Now, order coordinates by the y coordinate
  xy <- left_coords[order(left_coords[,2]),]
  # Calculate bearing betwwen the two left-most coordinates
  bearing <- 90 - (180/pi)*atan2(xy[2,2]-xy[1,2], xy[2,1]-xy[1,1])
  # Get centroid of the experiment
  exp_centroid <- gCentroid(Polygon_vector[i,])
  # Rotate experiment to north orientation just to draw the raster
  rotated_experiment <- elide(Polygon_vector[i,], rotate=-bearing,
                              center=coordinates(exp_centroid))
  
  # Draw plots with no spacing between them
  # Start by creating a raster with resolution = plot_width x plot_height
  x_min <- xmin(Polygon_vector[i,])
  x_max <- x_min+plot_width*n_plots
  y_min <- ymin(Polygon_vector[i,])
  y_max <- y_min+plot_height*n_blocks*n_ranges
  plots <- raster(xmn=x_min, xmx=x_max, ymn=y_min, ymx=y_max,
                  resolution=c(plot_width,plot_height), crs=crs(Polygon_vector))
  
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
  
  if(n_blocks[[i]]>1){ # If there are multiple blocks
    
    # Check if number of blocks is greater than 9 to determine number of digits in labels
    n_dig_blocks <- ifelse(n_blocks[[i]] > 9, 2, 1)
    # Check if number of plots per block is greater than 99 to determine number of digits in labels
    n_dig_entries <- ifelse(n_ranges[[i]]*n_plots[[i]] > 99, 3, 2)
    
    if(ID_format==0){ # Sequential format
      # Convert raster cells to polygons
      plots_poly <- rasterToPolygons(plots)
      # Assign plot ID based on block and plot number
      for(cell in 1:ncell(plots)){
        if(Start_numbering_plots_from==0){ # If numbering starts from the bottom_left
          sprintf(paste0('%0',n_dig_blocks,'d'), block_ID <- rev(ceiling((1:nrow(plots))/n_ranges[[i]]))[rowFromCell(plots, cell)])
          range_ID <- rev(rep(1:n_ranges[[i]],n_blocks[[i]]))[rowFromCell(plots, cell)]
          entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
          plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
        }
        
        if(Start_numbering_plots_from==1){ # If numbering starts from the bottom_right
          sprintf(paste0('%0',n_dig_blocks,'d'), block_ID <- rev(ceiling((1:nrow(plots))/n_ranges[[i]]))[rowFromCell(plots, cell)])
          range_ID <- rev(rep(1:n_ranges[[i]],n_blocks[[i]]))[rowFromCell(plots, cell)]
          entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
          plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
        }
        
        if(Start_numbering_plots_from==2){ # If numbering starts from the top_left
          sprintf(paste0('%0',n_dig_blocks,'d'), block_ID <- ceiling((1:nrow(plots))/n_ranges[[i]])[rowFromCell(plots, cell)])
          range_ID <- rep(1:n_ranges[[i]],n_blocks[[i]])[rowFromCell(plots, cell)]
          entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
          plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
        }
        
        if(Start_numbering_plots_from==3){ # If numbering starts from the top_right
          sprintf(paste0('%0',n_dig_blocks,'d'), block_ID <- ceiling((1:nrow(plots))/n_ranges[[i]])[rowFromCell(plots, cell)])
          range_ID <- rep(1:n_ranges[[i]],n_blocks[[i]])[rowFromCell(plots, cell)]
          entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
          plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
        }
      }
    }
    
    if(ID_format==1){ # Serpentine format
      # Convert raster cells to polygons
      plots_poly <- rasterToPolygons(plots)
      
      if(restart_side){ # If blocks should always start on the same side
        
        # Assign plot ID based on block and plot number
        for(cell in 1:ncell(plots)){
          if(Start_numbering_plots_from==0){ # If numbering starts from the bottom_left
            block_ID <- sprintf(paste0('%0',n_dig_blocks,'d'), rev(ceiling((1:nrow(plots))/n_ranges[[i]]))[rowFromCell(plots, cell)])
            range_ID <- rev(rep(1:n_ranges[[i]],n_blocks[[i]]))[rowFromCell(plots, cell)]
            if(range_ID%%2==1){ # If the range number is odd
              entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
              plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
            } else{ # If the range number is even
              entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
              plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
            }
          }
          
          if(Start_numbering_plots_from==1){ # If numbering starts from the bottom_right
            block_ID <- sprintf(paste0('%0',n_dig_blocks,'d'), rev(ceiling((1:nrow(plots))/n_ranges[[i]]))[rowFromCell(plots, cell)])
            range_ID <- rev(rep(1:n_ranges[[i]],n_blocks[[i]]))[rowFromCell(plots, cell)]
            if(range_ID%%2==1){ # If the range number is odd
              entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
              plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
            } else{ # If the range number is even
              entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
              plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
            }
          }
          
          if(Start_numbering_plots_from==2){ # If numbering starts from the top_left
            block_ID <- sprintf(paste0('%0',n_dig_blocks,'d'), ceiling((1:nrow(plots))/n_ranges[[i]])[rowFromCell(plots, cell)])
            range_ID <- rep(1:n_ranges[[i]],n_blocks[[i]])[rowFromCell(plots, cell)]
            if(range_ID%%2==1){ # If the range number is odd
              entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
              plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
            } else{ # If the range number is even
              entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
              plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
            }
          }
          
          if(Start_numbering_plots_from==3){ # If numbering starts from the top_right
            block_ID <- sprintf(paste0('%0',n_dig_blocks,'d'), ceiling((1:nrow(plots))/n_ranges[[i]])[rowFromCell(plots, cell)])
            range_ID <- rep(1:n_ranges[[i]],n_blocks[[i]])[rowFromCell(plots, cell)]
            if(range_ID%%2==1){ # If the range number is odd
              entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
              plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
            } else{ # If the range number is even
              entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
              plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
            }
          }
        }
      } else{ # Else, if blocks should follow the serpentine
        
        # Assign plot ID based on block and plot number
        for(cell in 1:ncell(plots)){
          if(Start_numbering_plots_from==0){ # If numbering starts from the bottom_left
            block_ID <- sprintf(paste0('%0',n_dig_blocks,'d'), rev(ceiling((1:nrow(plots))/n_ranges[[i]]))[rowFromCell(plots, cell)])
            range_ID <- rev(rep(1:n_ranges[[i]],n_blocks[[i]]))[rowFromCell(plots, cell)]
            if((nrow(plots):1)[rowFromCell(plots, cell)]%%2==1){ # If the row number is odd
              entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
              plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
            } else{ # If the row number is even
              entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
              plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
            }
          }
          
          if(Start_numbering_plots_from==1){ # If numbering starts from the bottom_right
            block_ID <- sprintf(paste0('%0',n_dig_blocks,'d'), rev(ceiling((1:nrow(plots))/n_ranges[[i]]))[rowFromCell(plots, cell)])
            range_ID <- rev(rep(1:n_ranges[[i]],n_blocks[[i]]))[rowFromCell(plots, cell)]
            if((nrow(plots):1)[rowFromCell(plots, cell)]%%2==1){ # If the row number is odd
              entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
              plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
            } else{ # If the row number is even
              entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
              plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
            }
          }
          
          if(Start_numbering_plots_from==2){ # If numbering starts from the top_left
            block_ID <- sprintf(paste0('%0',n_dig_blocks,'d'), ceiling((1:nrow(plots))/n_ranges[[i]])[rowFromCell(plots, cell)])
            range_ID <- rep(1:n_ranges[[i]],n_blocks[[i]])[rowFromCell(plots, cell)]
            if(rowFromCell(plots, cell)%%2==1){ # If the row number is odd
              entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
              plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
            } else{ # If the row number is even
              entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
              plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
            }
          }
          
          if(Start_numbering_plots_from==3){ # If numbering starts from the top_right
            block_ID <- sprintf(paste0('%0',n_dig_blocks,'d'), ceiling((1:nrow(plots))/n_ranges[[i]])[rowFromCell(plots, cell)])
            range_ID <- rep(1:n_ranges[[i]],n_blocks[[i]])[rowFromCell(plots, cell)]
            if(rowFromCell(plots, cell)%%2==1){ # If the row number is odd
              entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
              plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
            } else{ # If the row number is even
              entry_ID <- sprintf(paste0('%0',n_dig_entries,'d'), colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
              plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
            }
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
    data_plots[[p]] <- bbox2SP(y_max, y_min, x_max, x_min, proj4string=crs(Polygon_vector))
  }
  # Combine all Polygons in the list into a single SpatialPolygons object
  if(length(data_plots)>1){
    data_plots_poly <- bind(data_plots)} else{
      data_plots_poly <- data_plots[[1]]
    }
  
  # Assign plots_poly IDs to the data_plots_poly layer
  data_plots_poly$PlotID <- as.character(plots_poly$PlotID)
  
  # Rotate inner plots to match experiment rotation
  rotated_plots <- elide(data_plots_poly, rotate=bearing,
                         center=coordinates(exp_centroid))
  
  # Assign coordinate system
  crs(rotated_plots) <- crs(Polygon_vector)
  
  # Add trial name to another column in the plots data frame
  rotated_plots$Trial <- exper_name[i]
  
  # Export individual shapefiles, if desired
  if(nchar(Output_directory_for_individual_shapefiles)>0){
    file_name <- paste0(Output_directory_for_individual_shapefiles, '/',
                        exper_name[i], '_Plot_ID.shp')
    shapefile(rotated_plots, file_name)}
  
  # Add experiment plots to list of experiments
  all_experiments[[i]] <- rotated_plots
}
# Combine all experiments in the list into a single SpatialPolygonsDataFrame object
if(length(all_experiments)>1){
  All_trials <- bind(all_experiments)} else{
    All_trials <- all_experiments[[1]]
  }