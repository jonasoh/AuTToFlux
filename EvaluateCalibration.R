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

thr.sum <- thrs <- vals <- NULL

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
  
  # find out upper threshold value
  x <- regexec('thr0-([0-9]+)\\.csv$', bname)
  upper_threshold <- as.numeric(unlist(regmatches(bname, x))[2])
  
  thrs <- c(thrs, upper_threshold)
  vals <- c(vals, sum(tbl$Area))
}

thresholds <- data.frame(threshold=thrs, sumarea=vals)
thresholds %>% arrange(threshold) -> thresholds

# XXX: also summarize the data, or group, to allow the use of multiple images

ggplot(thresholds, aes(x=threshold, y=sumarea)) +
  geom_line()
