cells2labels <- function(root_dir, sce, image_id_col, cell_id_col, cell_label_col, non_labelled="unlabelled"){
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

    # create empty dataframe with nrow() = max(ObjectNumber)
    df <- as.data.frame(matrix(rep(NA,max(cur_sce$ObjectNumber)+1)))
    df[colData(cur_sce)[,cell_id_col]+1,] <- dic[colData(cur_sce)[,cell_label_col]]
    df[is.na(df$V1),] <- -1

    # save as txt
    if(endsWith(x,".tiff")){
      x <- gsub(".tiff","",x)
    }
    path <- paste0(root_dir,"/CellTypes/cells2labels/",x,".txt")
    write.table(df, file = path, row.names = F, col.names = F)
    return (path)
  })

  return (images)
}
