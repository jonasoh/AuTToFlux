# vacuole.R -
#   analyze RFP/GFP ratios

library(ggplot2)
library(dplyr)

# there is no support for directory picker under non-windows platforms
if (.Platform$OS.type == 'unix') {
  dir = readline(prompt = "Enter directory: ")
} else {
  dir <- choose.dir(getwd(), "Choose folder to process")
}

# might as well measure how long it takes
starttime <- Sys.time()

# check that there's an info.txt file in the directory
# info.txt is a tab-delimited file with two columns:
#
#   Treatment | StartTime
#   ----------+------------------
#   DMSO      | 2017-07-24 15:13
#   ...       | ...
#
# the values of StartTime are used to calculate the exact times since inoculation

infofile <- file.path(dir, 'info.txt')
stopifnot(file.exists(infofile))
treatments <- read.delim(infofile)
treatments$StartTime <- strptime(treatments$StartTime, format='%Y-%m-%d %H:%M')

# make sure to start with a clean slate
expdata <- NULL

# get all .csv files in the directory
files <- list.files(path = dir, pattern = 'csv$', full.names = TRUE, recursive = TRUE, ignore.case = TRUE, no.. = TRUE)

for(f in files) {
  tbl <- read.csv(f, stringsAsFactors = FALSE)
  rows <- dim(tbl)[1]

  # due to the way ImageJ saves the .csv files, datetimes are stored in the first cell of the last row
  datetime <- as.character(tbl[rows, 1, drop = TRUE])
  datetime <- unlist(strsplit(datetime, '.', fixed = TRUE))[1]
  datetime <- sub('T', ' ', datetime, fixed = TRUE)
  datetime <- strptime(datetime, format='%Y-%m-%d %H:%M:%S')
  
  # remove last two rows as they contain junk
  tbl <- tbl[-c(rows, rows - 1), , drop = TRUE]

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
  stopifnot(grepl('^[[:print:]]+_[[:print:]]+_[[:print:]]+_seedling[[:digit:]]+_image[[:digit:]]+\\.czi\\.csv$', bname))
  
  bname <- sub('.czi.csv', '', bname, fixed = TRUE)
  
  params <- unlist(strsplit(bname, '_', fixed = TRUE))
  
  timepoint <- params[1]
  line <- params[2]
  treatment <- params[3]
  seedling_no <- as.numeric(sub('seedling', '', params[4]))
  image_no <- as.numeric(sub('image', '', params[5]))
  
  # calculate ratios; GFP is in ch 2 and RFP in ch 1
  ratios <- na.omit(tbl$Mean[tbl$Ch == 2] / tbl$Mean[tbl$Ch == 1])

  # find out the exact elapsed time, in minutes
  elapsed <- as.numeric(datetime - treatments$StartTime[treatments$Treatment == treatment]) * 60

  areas <- NULL
  
  if (length(ratios > 0)) {
    # beware: areas are numbered sequentially from 1 to the number of areas, and thus do not necessarily match 
    #   those in the original files (i.e. if specks were removed)
    areas = 1:length(ratios)
    
    imgdata <- data.frame(Ratio = ratios, Timepoint = timepoint, Line = line, Treatment = treatment, Seedling = seedling_no, 
                          Image = image_no, Area = areas, Actual_Time = datetime, Elapsed = elapsed, stringsAsFactors = FALSE)
    expdata <- rbind(expdata, imgdata)
  }
}

normratios <- NULL

for (tp in unique(expdata$Timepoint)) {
  dmso_mean <- mean(expdata$Ratio[expdata$Treatment == 'DMSO' & expdata$Timepoint == tp])
  normratios <- c(normratios, expdata$Ratio[expdata$Timepoint == tp] / dmso_mean)
}

expdata$Norm_Ratio <- normratios
expdata$Log_Ratio <- log10(normratios)

expdata$Timepoint <- as.factor(expdata$Timepoint)
expdata$Line <- as.factor(expdata$Line)
expdata$Treatment <- as.factor(expdata$Treatment)

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
write.table(expdata2, file.path(dir, 'summary-full.txt'), row.names = FALSE) 
write.table(expsum, file.path(dir, 'summary-perseedling.txt'), row.names = FALSE)

scripttime <- Sys.time() - starttime
cat("Took", scripttime, "seconds to process", length(files), "files.")

# ugly sorting hack
expdata$Treatment <- relevel(expdata$Treatment, '5uM C12')
expdata$Treatment <- relevel(expdata$Treatment, 'DMSO')

# here goes the plotting functions
ggplot(expdata, aes(x=Elapsed, y=Norm_Ratio, color=Treatment)) + 
  geom_point(alpha=.2, size=1.5) + 
  geom_smooth(data=expdata, aes(x=Elapsed, y=Norm_Ratio, color=Treatment), method='lm', formula = y ~ poly(x,2), se=FALSE) + 
  theme(panel.background = element_blank()) + 
  scale_color_brewer()
