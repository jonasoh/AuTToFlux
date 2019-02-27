# EvaluateCalibration.R -
#   evaluate threshold calibration data

library(dplyr)
library(ggplot2)

# there is no support for directory picker under non-windows platforms
if (.Platform$OS.type == 'unix') {
  dir <- readline(prompt = "Enter directory: ")
} else {
  dir <- choose.dir(getwd(), "Choose folder to process")
}

thr.sum <- thrs <- vals <- imgnums <- NULL
imgnum <- -1

# get all .csv files in the directory
files <- list.files(path = dir, pattern = 'csv$', full.names = TRUE, recursive = TRUE, ignore.case = TRUE, no.. = TRUE)

for(f in files) {
  # read the file and its accompanying creation time
  tbl <- read.csv(f, stringsAsFactors = FALSE)

  # remove areas < 1 (these are specks which give weird results)
  out <- which(tbl$Area < 1)
  if (length(out) > 0) {
    tbl <- tbl[-out, ,drop = TRUE]
  }
  
  # get the base file name - we derive data from it
  bname <- basename(f)

  imgnum <- sub('\\.mask\\.thr0-[[:digit:]]+\\.csv', '', bname)  

  # find out upper threshold value
  x <- regexec('thr0-([0-9]+)\\.csv$', bname)
  upper_threshold <- as.numeric(unlist(regmatches(bname, x))[2])

  thrs <- c(thrs, upper_threshold)
  vals <- c(vals, sum(tbl$Area))
  imgnums <- c(imgnums, imgnum)
}

thresholds <- data.frame(threshold=thrs, sumarea=vals, image=imgnums)
sumthreshold <- thresholds %>% 
  group_by(threshold, image) %>% 
  summarize(sumarea = sum(sumarea))

quickgraph <- ggplot(sumthreshold, aes(x=threshold, y=sumarea, group=image, color=as.factor(image))) + 
  geom_point() +
  geom_line() + 
  labs(color="Image", y="Summed area", x="Upper threshold value") + 
  scale_x_continuous(limits=c(1,14), breaks=1:14)
  
ggsave(file.path(dir, 'threshold-graph.pdf'), units='cm', width=20, height=12)
