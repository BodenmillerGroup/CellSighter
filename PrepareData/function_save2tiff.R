library(tiff)
library(cytomapper)

save2tiff <- function(CytoImageList, root_dir, masks = FALSE){
  # case image
  if(!masks){
    print(paste0("Saving ",length(CytoImageList)," IMAGES as tiff and creating channels.txt with ", length(channelNames(images)), " channels"))
    # create directory if necessary
    if(!dir.exists(paste0(root_dir,"/CellTypes/data/images"))){
      dir.create(paste0(root_dir,"/CellTypes/data/images"), recursive = TRUE)
    }

    # save images as tiff
    lapply(names(CytImageList), function(x){
      writeImage(as.array(CytImageList[[x]])/(2^16 - 1),
                 paste0(root_dir,"/CellTypes/data/images/",x, ".tiff"),
                 bits.per.sample = 16)
    })

    # create channels.txt
    writeLines(channelNames(CytImageList),con=paste0(root_dir,"/channels.txt"),sep="\n")

  }

  # case masks
  else{
    print(paste0("Saving ",length(CytoImageList)," MASKS as tiff"))
    # create directory if necessary
    if(!dir.exists(paste0(root_dir,"/CellTypes/cells"))){
      dir.create(paste0(root_dir,"/CellTypes/cells"), recursive = TRUE)
    }

    # save masks as tiff
    lapply(names(CytImageList), function(x){
      writeImage(as.array(CytImageList[[x]])/(2^16 - 1),
                 paste0(root_dir,"/CellTypes/cells/",x, ".tiff"),
                 bits.per.sample = 16)
    })

  }


}
