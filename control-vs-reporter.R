# control-vs-reporter.R -
#   compare responses in control vs reporter lines

require(ggplot2)
require(dplyr)
require(readr)
library(lmPerm)

# there is no support for directory picker under non-windows platforms
if (.Platform$OS.type == 'unix') {
  dir = readline(prompt = "Enter directory: ")
} else {
  dir <- choose.dir(getwd(), "Choose folder to process")
}

# might as well measure how long it takes
starttime <- Sys.time()
n <- 0

# override input - use this for development only
#dir <- '~/Documents/ImageJ/TTE14_1uMC7/'

# make sure to start with a clean slate
alldata <- NULL
pvals <- NULL
experiments <- NULL

# get a list of subdirectories - these are the separate experiments
dirs <- list.files(path = dir, full.names = TRUE, recursive = FALSE, no.. = TRUE)

# make sure we only include directories
realdirs <- NULL
for(d in dirs) {
  if(file.info(d)$isdir) realdirs <- c(realdirs, d)
}

# process each dir separately
for(d in realdirs) {
  experiment <- basename(d)
  experiments <- c(experiments, experiment)
  expdata <- NULL
  
  # get all .csv files in the directory
  files <- list.files(path = d, pattern = 'csv$', full.names = TRUE, recursive = TRUE, ignore.case = TRUE, no.. = TRUE)
  
  for(f in files) {
    n <- n + 1
    cat('.')
    suppressMessages(suppressWarnings(tbl <- readr::read_csv(f, guess_max=2)))
    rows <- dim(tbl)[1]
    
    # use complete.cases to strip out trailing junk
    tbl <- tbl[complete.cases(tbl),]
    
    # sometimes the Area column becomes factor, we don't want this
    tbl$Area1 <- as.numeric(tbl$Area1)
    
    # if channels are not specified in the file, add them
    if (! 'Ch' %in% names(tbl)) {
      tbl$Ch <- 1:3
    }
    
    # remove areas < 1 (these are specks which give weird results)
    out <- which(tbl$Area1 < 1)
    if (length(out) > 0) {
      tbl <- tbl[-out,]
    }
    
    # get the base file name - we derive data from it
    bname <- basename(f)
    bname <- sub('.czi.csv', '', bname, fixed=TRUE)
    
    params <- unlist(strsplit(bname, '_', fixed=TRUE))
    
    line <- params[1]
    treatment <- params[2]
    seedling_no <- as.numeric(sub('seedling', '', params[3]))
    image_no <- as.numeric(sub('image', '', params[4]))
    
    # calculate ratios; RFP is in ch 2 and GFP in ch 1
    ratios <- na.omit(tbl$Mean1[tbl$Ch == 2] / tbl$Mean1[tbl$Ch == 1])
    
    # beware: areas are numbered sequentially from 1 to the number of areas, and thus do not necessarily match 
    #   those in the original files (i.e. if specks were removed)
    areas = 1:length(ratios)
    
    if (length(ratios > 0)) {
      imgdata <- data.frame(Ratio = ratios, Line = line, Treatment = treatment, Seedling = seedling_no, 
                            Image = image_no, Area = areas, Experiment = experiment)
      expdata <- rbind(expdata, imgdata)
    }
  }
  
  normratios <- NULL
  
  for (l in unique(expdata$Line)) {
    dmso_mean <- mean(expdata$Ratio[expdata$Treatment == 'DMSO' & expdata$Line == l])
    normratios <- c(normratios, expdata$Ratio[expdata$Line == l] / dmso_mean)
  }
  
  expdata$Norm_Ratio <- normratios
  alldata <- rbind(alldata, expdata)
  
  # summarize the data for plotting and analysis
  expdata %>% group_by(Line) %>% 
    group_by(Treatment, add=T) %>% 
    group_by(Seedling, add=T) %>% 
    summarize(Mean_Ratio = mean(Norm_Ratio), 
              Mean_Raw_Ratio = mean(Ratio),
              Log_Ratio = log10(Mean_Ratio), 
              Raw_Log_Ratio = log10(Mean_Raw_Ratio), 
              SD = sd(Norm_Ratio), 
              n = n()) -> expsum1
  
  write.table(expdata, file.path(d, 'summary-full.txt'), row.names=FALSE) 
  write.table(expsum1, file.path(d, 'summary-perseedling.txt'), row.names=FALSE)
  
  cat("\nPerforming permutation test for experiment", experiment, "... ")
  
  if ('Reporter' %in% unique(expsum1$Line)) {
    perm <- summary(aovp(Mean_Raw_Ratio~Treatment, data=expsum1[expsum1$Line=='Reporter',], perm='Exact', maxExact = 100))
  } else {
    perm <- summary(aovp(Mean_Raw_Ratio~Treatment, data=expsum1[expsum1$Line=='Reporter-N',], perm='Exact', maxExact = 100))
  }
  
  pval <- unlist(perm)[7]
  cat("p-value is", pval, "\n")
  pvals <- c(pvals, pval)
}

exppvals <- data.frame(Experiment = experiments, pval = pvals)
write.table(exppvals, file.path(dir, 'pvals.txt'), row.names=FALSE)
write.table(alldata, file.path(dir, 'summary.txt'), row.names=FALSE)

scripttime <- Sys.time() - starttime
cat("Took", scripttime, "seconds to process", n, "files.\n")

# here goes the plotting functions
#ggplot(expdata, aes(x=Treatment, y=Norm_Ratio)) + geom_boxplot() + facet_grid(. ~ Line)
#ggplot(expsum1, aes(x=Treatment, y=Mean_Ratio)) + geom_boxplot() + facet_grid(. ~ Line)
