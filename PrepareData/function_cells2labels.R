cells2labels <- function(root_dir, sce, image_id_col, cell_label_col, non_labelled="unlabelled"){
  # create directory if necessary
  if(!dir.exists(paste0(root_dir,"/CellTypes/cells2labels"))){
    dir.create(paste0(root_dir,"/CellTypes/cells2labels"),recursive = TRUE)
  }

  # create label to label-id dictionary, set unlabeled to -1
  dic <- c()
  labels <- sort(unique(colData(sce)[,cell_label_col]))
  labels <- labels[labels != non_labelled]

  for (i in 1:length(labels)){
    dic[labels[i]] <- i-1
  }
  dic[non_labelled] <- -1

  # store global label information
  if (!dir.exists(paste0(root_dir,"/ForConfig"))){
    dir.create(paste0(root_dir,"/ForConfig"))
  }

  classes <- sapply(seq_along(dic),function(i){return(paste(dic[i],":",names(dic)[i]))})
  writeLines(classes,con=paste0(root_dir,"/ForConfig/","classes_dic",".txt"),sep="\n")

  # store average radius information
  radius <- mean(sqrt(sce$area/pi))
  max <- max(sqrt(sce$area/pi))
  writeLines(paste(radius,max,sep=","),con=paste0(root_dir,"/ForConfig/","radius_max",".txt"),sep="")

  # extract image id from image name if necessary
  sce$image_id_col <- colData(sce)[,image_id_col]
  if (endsWith(sce$image_id_col[1],".tiff")){
    sce$image_id_col <- str_split(sce$image_id_col,".tiff", simplify=T)[,1]
  }

  # create cells2labels file for all images contained in the sce
  print(paste0("Creating cells2labels for ",length(unique(sce$image_id_col))," images"))
  images <- lapply(unique(sce$image_id_col), function(x){
    #select one image
    cur_sce <- sce[,sce$image_id_col == x]
    # extract object number and cell label
    df <- data.frame(ObjectNumber = cur_sce$ObjectNumber, CellLabel = cur_sce$cell_labels)
    # make sure rows are ordered by object number
    df <- df[order(df$ObjectNumber),]
    # store as txt file: where object number is represented by the index of the row
    ## assign numeric label
    df$label <- dic[df$CellLabel]
    #TODO: how to make sure all cells in there? If possibly cell with highest ObjectNumber were excluded
    nr_lines = 1
    # start with empty row because of python indexing
    final_string <- "-1\n"
    # iterate over all cells
    for (object_nr in df$ObjectNumber){
      # if cell is missing, fill in rows with -1
      if (object_nr > nr_lines){
        dif <- object_nr - nr_lines
        add_string <- rep("-1\n",dif)
        final_string <- paste0(final_string,add_string)
        nr_lines <- nr_lines + dif
      }
      # add cellLabel at correct row number
      final_string <- paste0(final_string, df$label[df$ObjectNumber == object_nr],"\n")
      nr_lines <- nr_lines + 1
    }

    # save as txt
    writeLines(final_string,con=paste0(root_dir,"/CellTypes/cells2labels/",x,".txt"),sep="")
    return (paste0(root_dir,"/CellTypes/cells2labels/",x,".txt"))
  })

  return (images)
}
