library(stringr)
library(readr)

# TODO: automatization of hierarchy match?
data2config <- function(path_to_store, root_dir, crop_input_size=NULL ,train_split=0.8, train_set=NULL,
                        val_set=NULL, epoch_max=50,lr=0.001,blacklist=NULL,channels_path=paste0(root_dir,"/channels.txt"),
                        weight_to_eval=NULL, sample_batch=TRUE, to_pad=FALSE, size_data=1000, aug = TRUE){

  # import class information
  dic <- c()
  classes <- str_split(read.delim(paste0(root_dir,"/ForConfig/classes_dic.txt"), sep = "\n",header=F)[,1],":",simplify=T)
  dic[str_remove(classes[,2]," ")] <- str_remove(classes[,1]," ")
  num_classes <- length(dic) - 1

  # create hierarchy_match string
  hierarchy_match_string <- ""
  for (label in names(dic)){
    hierarchy_match_string <- paste0(hierarchy_match_string,"\"",dic[label],"\":","\"",label,"\", ")
  }
  hierarchy_match_string <- substring(hierarchy_match_string,1,nchar(hierarchy_match_string)-2)
  hierarchy_match_string <- paste0("{",hierarchy_match_string,"}")

  # create root_dir string
  root_dir_string <- paste0("\"",root_dir,"\"")

  # compute crop_input_size from mean and max cell radius
  if (is.null(crop_input_size)){
    stats <- str_split(read_lines(paste0(root_dir,"/ForConfig/radius_max.txt")),pattern = ",",simplify=T)
    radius = stats[,1]
    maxi = stats[,2]
    crop_input_size = round(as.numeric(maxi) + 1.5*as.numeric(radius))
  }

  # split between train and validation set
  image_ids <- str_split(list.files(paste0(root_dir,"/CellTypes/data/images/")),pattern = ".tiff",simplify = T)[,1]

  if(is.null(train_set) & is.null(val_set)){
    train_set <- sample(image_ids,length(image_ids)*train_split)
    val_set <- image_ids[!(image_ids %in% train_set)]

    train_set_string <- paste(train_set,collapse = '","')
    train_set_string <- paste0("[\"",train_set_string,"\"]")

    val_set_string <- paste(val_set, collapse = '","')
    val_set_string <- paste0("[\"",val_set_string,"\"]")


    writeLines(train_set_string,con=paste0(root_dir,"/ForConfig/train_set.txt"), sep="")
    writeLines(val_set_string,con=paste0(root_dir,"/ForConfig/val_set.txt"), sep="")
  }
  #TODO: implement case where train or val set is given

  # create blacklist string
  blacklist_string <- paste(blacklist,collapse = '","')
  blacklist_string <- paste0("[\"",blacklist_string,"\"]")

  # create channels_path string
  channels_path_string <- paste0("\"",channels_path,"\"")

  # create weight_to_eval string
  weight_to_eval_string = "\"\""
  if (!is.null(weight_to_eval)){
    weight_to_eval_string <- paste0("\"",weight_to_eval,"\"")
  }

  # write into config.json file
  out <- paste0("{\"crop_input_size\": ",crop_input_size, ",\n",
                "\"crop_size\": ", crop_input_size*2,",\n",
                "\"root_dir\": ", root_dir_string,",\n",
                "\"train_set\": ", train_set_string,",\n",
                "\"val_set\": ", val_set_string,",\n",
                "\"num_classes\": ", num_classes,",\n",
                "\"epoch_max\": ", epoch_max,",\n",
                "\"lr\": ", lr,",\n",
                "\"blacklist\": ", blacklist_string,",\n",
                "\"channels_path\": ", channels_path_string,",\n",
                "\"weight_to_eval\": ", weight_to_eval_string,",\n",
                "\"sample_batch\": ", tolower(as.character(sample_batch)),",\n",
                "\"to_pad\": ", tolower(as.character(to_pad)),",\n",
                "\"hierarchy_match\": ", hierarchy_match_string,",\n",
                "\"size_data\": ", size_data,",\n",
                "\"aug\": ", tolower(as.character(aug)) ,"\n}"
                )

  writeLines(out,  con = paste0(path_to_store,"/config.json"))
}
