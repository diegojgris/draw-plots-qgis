##Draw plots from Excel file=name
##Draw trial plots=group
##load_vector_using_rgdal
##Output_directory=optional folder D:/
##Excel_file=file NA
##ID_format=selection sequential;serpentine 0
##Start_numbering_plots_from=selection bottom_left;bottom_right;top_left;top_right 0
##Starting_ID_if_not_block_design=string 1
##Measurement_units_used_in_the_Excel_file=selection feet;meters 0
##Also_export_individual_trials=boolean FALSE
##All_trials=output vector

library(rgeos)
library(maptools)
library(xlsx)

# Check if Excel file path has xlsx extension and either import it or create template file
if(grepl('.xlsx', Excel_file)){
  input_table <- read.xlsx(Excel_file, 1)} else{
    template <- rbind(c(1,-34.71185,36.88238,-34.71183,36.88515,1,20,10,40,100,30,80),
                      c(2,-34.70782,36.88180,-34.70554,36.88358,6,3,25,30,30,25,25),
                      c(3,-34.70664,36.87818,-34.70383,36.87822,3,4,12,100,75,85,50))
    template <- as.data.frame(template)
    names(template) <- c('trial_name','bottom_left_long','bottom_left_lat','top_left_long','top_left_lat',
                         'n_blocks','n_ranges_per_block','n_plots_per_range',
                         'plot_width','plot_height','data_plot_width','data_plot_height')
    template$trial_name <- c('A','B','C')
    write.xlsx(template, file.path(Output_directory, 'input_template.xlsx'),
               col.names=T, row.names=F)
    cat('\n\n\nEXCEL TEMPLATE CREATED!\nIGNORE ERROR MESSAGE BELOW.\n\n\n\n')
    quit()}

# Convert strings to numbers and feet to meters if necessary
if(Measurement_units_used_in_the_Excel_file==0){
  plot_width <- as.numeric(input_table$plot_width)*0.3048
  plot_height <- as.numeric(input_table$plot_height)*0.3048
  data_plot_width <- as.numeric(input_table$data_plot_width)*0.3048
  data_plot_height <- as.numeric(input_table$data_plot_height)*0.3048} else{
    plot_width <- as.numeric(input_table$plot_width)
    plot_height <- as.numeric(input_table$plot_height)
    data_plot_width <- as.numeric(input_table$data_plot_width)
    data_plot_height <- as.numeric(input_table$data_plot_height)}

# Get variables from table
start_ID <- as.numeric(Starting_ID_if_not_block_design)
n_blocks <- as.numeric(input_table$n_blocks)
n_ranges <- as.numeric(input_table$n_ranges_per_block)
n_plots <- as.numeric(input_table$n_plots_per_range)
exper_name <- input_table$trial_name

# Create empty list to hold all experiments
all_experiments <- list()

# Run through experiments and draw plots
for(i in 1:nrow(input_table)){
  # Get left border coordinates
  left_coords <- input_table[i,c('bottom_left_long','bottom_left_lat','top_left_long','top_left_lat')]
  # Check if coordinates are in decimal degrees
  if(left_coords[[1]]>180|left_coords[[2]]>90) stop('Coordinates must be in WGS84 decimal degrees!')
  # Assign new names
  names(left_coords) <- c('long','lat','long','lat')
  # Now, put the coordinates in different rows (bottom left first)
  xy <- rbind(left_coords[1:2], left_coords[3:4])
  # Transform into SpatialPoints
  coordinates(xy) <- c(1,2)
  # Assign WGS84 projection to the points
  crs(xy) <- '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs'
  # Get UTM zone
  zone <- floor((left_coords[[1]]+180)/6)+1
  # Create proj4
  if(left_coords[[2]]>0){ # If coordinates are in the northern hemisphere
    proj4 <- paste0('+proj=utm +zone=', zone, ' +ellps=WGS84 +datum=WGS84 +units=m +no_defs')
  } else{ # If coordinates are in the southern hemisphere
    proj4 <- paste0('+proj=utm +zone=', zone, ' +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs')
  }
  # Tranform coordinates to UTM
  UTM <- spTransform(xy, proj4)
  # Get UTM coordinates
  coords <- UTM@coords
  # Calculate bearing between the two left-most coordinates
  bearing <- 90 - (180/pi)*atan2(coords[[2,2]]-coords[[1,2]], coords[[2,1]]-coords[[1,1]])
  
  # Draw plots
  # Start by creating a raster with resolution = plot_width x plot_height
  x_min <- coords[[1,1]]
  x_max <- x_min+plot_width[[i]]*n_plots[[i]]
  y_min <- coords[[1,2]]
  y_max <- y_min+plot_height[[i]]*n_blocks[[i]]*n_ranges[[i]]
  plots <- raster(xmn=x_min, xmx=x_max, ymn=y_min, ymx=y_max,
                  resolution=c(plot_width[[i]],plot_height[[i]]), crs=crs(UTM))
  
  # Assign plot ID
  
  if(n_blocks[[i]]==1){ # If there are no blocks ('single block')
    
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
    
    if(ID_format==0){ # Sequential format
      # Convert raster cells to polygons
      plots_poly <- rasterToPolygons(plots)
      # Assign plot ID based on block and plot number
      for(cell in 1:ncell(plots)){
        if(Start_numbering_plots_from==0){ # If numbering starts from the bottom_left
          block_ID <- rev(ceiling((1:nrow(plots))/n_ranges[[i]]))[rowFromCell(plots, cell)]
          range_ID <- rev(rep(1:n_ranges[[i]],n_blocks[[i]]))[rowFromCell(plots, cell)]
          entry_ID <- sprintf('%02d', colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
          plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
        }
        
        if(Start_numbering_plots_from==1){ # If numbering starts from the bottom_right
          block_ID <- rev(ceiling((1:nrow(plots))/n_ranges[[i]]))[rowFromCell(plots, cell)]
          range_ID <- rev(rep(1:n_ranges[[i]],n_blocks[[i]]))[rowFromCell(plots, cell)]
          entry_ID <- sprintf('%02d', (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
          plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
        }
        
        if(Start_numbering_plots_from==2){ # If numbering starts from the top_left
          block_ID <- ceiling((1:nrow(plots))/n_ranges[[i]])[rowFromCell(plots, cell)]
          range_ID <- rep(1:n_ranges[[i]],n_blocks[[i]])[rowFromCell(plots, cell)]
          entry_ID <- sprintf('%02d', colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
          plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
        }
        
        if(Start_numbering_plots_from==3){ # If numbering starts from the top_right
          block_ID <- ceiling((1:nrow(plots))/n_ranges[[i]])[rowFromCell(plots, cell)]
          range_ID <- rep(1:n_ranges[[i]],n_blocks[[i]])[rowFromCell(plots, cell)]
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
          block_ID <- rev(ceiling((1:nrow(plots))/n_ranges[[i]]))[rowFromCell(plots, cell)]
          range_ID <- rev(rep(1:n_ranges[[i]],n_blocks[[i]]))[rowFromCell(plots, cell)]
          if(range_ID%%2==1){ # If the range number is odd
            entry_ID <- sprintf('%02d', colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
            plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
          } else{ # If the range number is even
            entry_ID <- sprintf('%02d', (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
            plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
          }
        }
        
        if(Start_numbering_plots_from==1){ # If numbering starts from the bottom_right
          block_ID <- rev(ceiling((1:nrow(plots))/n_ranges[[i]]))[rowFromCell(plots, cell)]
          range_ID <- rev(rep(1:n_ranges[[i]],n_blocks[[i]]))[rowFromCell(plots, cell)]
          if(range_ID%%2==1){ # If the range number is odd
            entry_ID <- sprintf('%02d', (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
            plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
          } else{ # If the range number is even
            entry_ID <- sprintf('%02d', colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
            plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
          }
        }
        
        if(Start_numbering_plots_from==2){ # If numbering starts from the top_left
          block_ID <- ceiling((1:nrow(plots))/n_ranges[[i]])[rowFromCell(plots, cell)]
          range_ID <- rep(1:n_ranges[[i]],n_blocks[[i]])[rowFromCell(plots, cell)]
          if(range_ID%%2==1){ # If the range number is odd
            entry_ID <- sprintf('%02d', colFromCell(plots, cell)+ncol(plots)*(range_ID-1))
            plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
          } else{ # If the range number is even
            entry_ID <- sprintf('%02d', (ncol(plots):1)[colFromCell(plots, cell)]+ncol(plots)*(range_ID-1))
            plots_poly[cell,] <- paste0(block_ID, entry_ID, collapse='')
          }
        }
        
        if(Start_numbering_plots_from==3){ # If numbering starts from the top_right
          block_ID <- ceiling((1:nrow(plots))/n_ranges[[i]])[rowFromCell(plots, cell)]
          range_ID <- rep(1:n_ranges[[i]],n_blocks[[i]])[rowFromCell(plots, cell)]
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
    x_min <- centroids[p]@coords[1] - data_plot_width[i]/2
    x_max <- centroids[p]@coords[1] + data_plot_width[i]/2
    y_min <- centroids[p]@coords[2] - data_plot_height[i]/2
    y_max <- centroids[p]@coords[2] + data_plot_height[i]/2
    data_plots[[p]] <- bbox2SP(y_max, y_min, x_max, x_min, proj4string=crs(UTM))
  }
  # Combine all Polygons in the list into a single SpatialPolygons object
  if(length(data_plots)>1){
    data_plots_poly <- bind(data_plots)} else{
      data_plots_poly <- data_plots[[1]]
    }
  
  # Assign plots_poly IDs to the data_plots_poly layer
  data_plots_poly$PlotID <- as.character(plots_poly$PlotID)
  
  # Rotate inner plots to match experiment rotation
  rotated_plots <- elide(data_plots_poly, rotate=bearing, center=as.numeric(coords[1,]))
  
  # Assign coordinate system
  crs(rotated_plots) <- crs(UTM)
  
  # Add trial name to another column in the plots data frame
  rotated_plots$Trial <- exper_name[i]
  
  # Export individual shapefiles, if desired
  if(Also_export_individual_trials){
    file_name <- paste0(Output_directory, '/',
                        trial_name[i], '_Plot_ID.shp')
    shapefile(rotated_plots, file_name)}
  
  # Add experiment plots to list of experiments
  all_experiments[[i]] <- rotated_plots
}
# Combine all experiments in the list into a single SpatialPolygonsDataFrame object
if(length(all_experiments)>1){
  All_trials <- bind(all_experiments)} else{
    All_trials <- all_experiments[[1]]
  }