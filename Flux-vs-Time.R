# Flux-vs-Time.R -
#   analyze RFP/GFP ratios at different timepoints and, possibly, concentrations
# 
#   N.B.: this script requires an info.txt file to be present in the directory.
#         see below for the format of this file. 

library(dplyr)
library(ggplot2)

# there is no support for directory picker under non-windows platforms
if (.Platform$OS.type == 'unix') {
  dir <- readline(prompt = "Enter directory: ")
} else {
  dir <- choose.dir(getwd(), "Choose folder to process")
}

# we need to ask for the number of timepoints for k-means clustering
clusters <- as.numeric(readline(prompt = "Enter the number of timepoints: "))

# might as well measure how long it takes
starttime <- Sys.time()

# check that there's an info.txt file in the directory
# info.txt is a tab-delimited file with two columns:
#
#   Treatment | StartTime
#   ----------+------------------
#   Vehicle   | 2017-07-24 15:13
#   ...       | ...
#
# the values of StartTime are used to calculate the exact times since inoculation

infofile <- file.path(dir, 'info.txt')
stopifnot(file.exists(infofile))
treatments <- read.delim(infofile)
treatments$StartTime <- strptime(treatments$StartTime, format='%Y-%m-%d %H:%M')

# rename treatments called "DMSO" to "Vehicle". this is to ensure backwards compatibility with 
# files generated using the old naming scheme. 
treatments$Treatment[treatments$Treatment == 'DMSO'] <- 'Vehicle'

# make sure to start with a clean slate
expdata <- normratios <- NULL

# get all .csv files in the directory
files <- list.files(path = dir, pattern = 'csv$', full.names = TRUE, recursive = TRUE, ignore.case = TRUE, no.. = TRUE)

for(f in files) {
  # read the file and its accompanying creation time
  tbl <- read.csv(f, stringsAsFactors = FALSE)
  
  # suppress non-endline warnings
  suppressWarnings(
    crdate <- read.table(sub('csv$', 'time', f), stringsAsFactors = FALSE)
  )

  # process time description
  datetime <- as.character(crdate)
  datetime <- unlist(strsplit(datetime, '.', fixed = TRUE))[1]
  datetime <- sub('T', ' ', datetime, fixed = TRUE)
  datetime <- strptime(datetime, format='%Y-%m-%d %H:%M:%S')
  
  # if channels are not specified in the file, add them
  if (! 'Ch' %in% names(tbl)) {
    tbl$Ch <- 1:3
  }
  
  # remove areas < 1 (these are specks which give weird results)
  out <- which(tbl$Area < 1)
  if (length(out) > 0) {
    tbl <- tbl[-out, ,drop = TRUE]
  }
  
  # get the base file name - we derive data from it
  bname <- basename(f)
  
  # check that the name conforms to naming standard
  # if it doesn't conform, we stop the script to avoid calculation errors
  stopifnot(grepl('^[[:print:]]+_[[:print:]]+_seedling[[:alnum:]]+_image[[:alnum:]]+(\\.[[:alnum:]]{2,4})?\\.[[:alnum:]]{2,4}\\.csv$', bname))
  
  bname <- sub('\\.[[:alnum:]]{2,4}(\\.[[:alnum:]]{2,4})?\\.csv', '', bname, fixed = FALSE)
  
  params <- unlist(strsplit(bname, '_', fixed = TRUE))
  
  line <- params[1]

  if (params[2] != 'DMSO') {
    treatment <- params[2]
  } else {
    treatment <- 'Vehicle'
  }

  seedling_no <- sub('seedling', '', params[3])
  image_no <- sub('image', '', params[4])
  
  # exit if we can't extract parameters
  if ('' %in% c(line, treatment) | NA %in% c(seedling_no, image_no)) {
    print(paste("Unable to extract parameters from this file:", origbname))
    stop()
  }

  # calculate ratios; GFP is in ch 2 and RFP in ch 1
  ratios <- na.omit(tbl$Mean[tbl$Ch == 2] / tbl$Mean[tbl$Ch == 1])

  # find out the exact elapsed time, in minutes
  elapsed <- as.numeric(difftime(datetime, treatments$StartTime[treatments$Treatment == treatment]), units="hours")

  areas <- NULL
  
  if (length(ratios > 0)) {
    # beware: areas are numbered sequentially from 1 to the number of areas, and thus do not necessarily match 
    #   those in the original files (i.e. if specks were removed)
    areas = seq_along(length(ratios))
    
    imgdata <- data.frame(Ratio = ratios, Line = line, Treatment = treatment, Seedling = seedling_no, 
                          Image = image_no, Area = areas, Actual_Time = datetime, Elapsed = elapsed, stringsAsFactors = FALSE)
    expdata <- bind_rows(expdata, imgdata)
  }
}

# use k-means clustering to group times elapsed into distinct timepoints. 
# instead of random initial centers, we specify timepoints based on quantiles. 
# this works as long as there are approximately equal numbers of samples for each timepoint, 
# and is much more robust compared to using the default, random, initial centers. 
init_quantiles <- seq(0, 1, length.out=clusters+2)[2:(clusters+1)]
init_centers <- quantile(expdata$Elapsed, init_quantiles)
fit <- kmeans(expdata$Elapsed, init_centers, iter.max=1000, algorithm="MacQueen")
expdata$Timepoint <- fit$cluster

expdata <- expdata %>% arrange(Timepoint)

# normalize data for each timepoint
for (tp in unique(expdata$Timepoint)) {
  dmso_mean <- mean(expdata$Ratio[expdata$Treatment == 'Vehicle' & expdata$Timepoint == tp])
  normratios <- c(normratios, expdata$Ratio[expdata$Timepoint == tp] / dmso_mean)
}

expdata$Norm_Ratio <- normratios
expdata$Log_Ratio <- log10(normratios)
expdata$Line <- as.factor(expdata$Line)
expdata$Treatment <- as.factor(expdata$Treatment)
expdata$Timepoint <- as.factor(expdata$Timepoint)

# summarize the data for plotting and analysis
expdata %>% group_by(Timepoint) %>% 
  group_by(Treatment, add = TRUE) %>% 
  group_by(Seedling, add = TRUE) %>% 
  summarize(Mean_Ratio = mean(Norm_Ratio), 
            SD = sd(Norm_Ratio), 
            Elapsed = mean(Elapsed),
            n = n()) -> expsum

# we need to convert POSIXct format datetimes into character in order to save them
expdata2 <- expdata
expdata2$Actual_Time <- as.character(expdata2$Actual_Time)
write.table(expdata2, file.path(dir, 'summary-full.txt'), row.names = FALSE, sep='\t', quote=FALSE) 
write.table(expsum, file.path(dir, 'summary-perseedling.txt'), row.names = FALSE, sep='\t', quote=FALSE)

scripttime <- Sys.time() - starttime
cat("Took", scripttime, "seconds to process", length(files), "files.")

# output quick graph to directory
quickgraph <- ggplot(expdata, aes(x=Elapsed, y=Norm_Ratio, color=Treatment)) +
  geom_point(alpha=.2, size=1.5) +
  ylab('Normalized ratio') + 
  xlab('Time since inoculation') +
  geom_smooth(data=expdata, aes(x=Elapsed, y=Norm_Ratio, color=Treatment), method='lm', formula = y ~ poly(x,2), se=FALSE) +
  theme(panel.background = element_blank())
ggsave(file.path(dir, 'summary-graph.pdf'))
