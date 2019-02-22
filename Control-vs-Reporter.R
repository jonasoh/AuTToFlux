# Control-vs-Reporter.R -
#   compare responses in control vs reporter lines
#   
#   this script requires a main directory, with subdirectories containing control and reporter 
#   data for each experiment

library(ggplot2)
library(dplyr)
library(readr)

# uncomment the line below to get permutation-based p-values
# also uncomment corresponding lines in the loop for statistical evaluation, at the end of the script
#library(lmPerm)

# uncomment to use with github.com/hadley/strict
#library(strict)

# there is no support for directory picker under non-windows platforms
if (.Platform$OS.type == 'unix') {
  dir = readline(prompt = "Enter directory: ")
} else {
  dir <- choose.dir(getwd(), "Choose folder to process")
}

# might as well measure how long it takes
starttime <- Sys.time()
n <- 0

# make sure to start with a clean slate
alldata <- experiments <- perms <- ctrlperms <- repts <- ctrlts <- realdirs <- NULL

# get a list of subdirectories - these are the separate experiments
dirs <- list.files(path = dir, full.names = TRUE, recursive = FALSE, no.. = TRUE)

# make sure we only include directories
for(d in dirs) {
  if(file.info(d)$isdir) {
    realdirs <- c(realdirs, d)
  }
}

# if there are no subdirectories, we must be dealing with a single experiment
if(!length(realdirs) > 0) {
  realdirs <- dir
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
    tbl <- read.csv(f, stringsAsFactors = FALSE)
    rows <- dim(tbl)[1]

    # sometimes the Area column becomes factor, we don't want this
    tbl$Area1 <- as.numeric(tbl$Area1)
    
    # if channels are not specified in the file, add them
    if (! 'Ch' %in% names(tbl)) {
      tbl$Ch <- 1:3
    }
    
    # remove areas < 1 (these are specks which give weird results)
    # XXX: this may need tweaking, but for now all erroneous areas are < 1
    out <- which(tbl$Area1 < 1)
    if (length(out) > 0) {
      tbl <- tbl[-out,]
    }
    
    # get the base file name - we derive data from it
    bname <- basename(f)
    
    # check that the name conforms to naming standard
    # if it doesn't conform, we stop the script to avoid calculation errors
    stopifnot(grepl('^[[:print:]]+_[[:print:]]+_seedling[[:alnum:]]+_image[[:alnum:]]+\\.[[:alnum:]]{2,4}\\.csv$', bname))
    
    bname <- sub('\\.[[:alnum:]]{2,4}\\.csv', '', bname, fixed = FALSE)
    
    params <- unlist(strsplit(bname, '_', fixed = TRUE))
    
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
                            Image = image_no, Area = areas, Experiment = experiment, stringsAsFactors = FALSE)
      expdata <- bind_rows(expdata, imgdata)
    }
  }
  
  normratios <- NULL
  
  # rename treatments called "DMSO" to "Vehicle". this is to ensure backwards compatibility with 
  # files generated using the old naming scheme. 
  expdata$Treatment[expdata$Treatment == 'DMSO'] <- 'Vehicle'
  
  # normalize data against DMSO controls, per line
  for (l in unique(expdata$Line)) {
    dmso_mean <- mean(expdata$Ratio[expdata$Treatment == 'Vehicle' & expdata$Line == l & expdata$Experiment == experiment])
    normratios <- c(normratios, expdata$Ratio[expdata$Line == l & expdata$Experiment == experiment] / dmso_mean)
  }
  
  expdata$Norm_Ratio <- normratios
  alldata <- bind_rows(alldata, expdata)
  
  # summarize the data for plotting and analysis
  expdata %>% 
    group_by(Line) %>% 
    group_by(Treatment, add = TRUE) %>% 
    group_by(Seedling, add = TRUE) %>% 
    summarize(Mean_Ratio = mean(Norm_Ratio), 
              Mean_Raw_Ratio = mean(Ratio),
              Log_Ratio = log10(Mean_Ratio), 
              Raw_Log_Ratio = log10(Mean_Raw_Ratio), 
              SD = sd(Norm_Ratio), 
              n = n()) -> expsum1
  
  expdata %>%
    group_by(Line) %>% 
    group_by(Treatment, add = TRUE) %>% 
    summarize(Mean_Ratio = mean(Norm_Ratio), 
              Log_Ratio = log10(Mean_Ratio), 
              SD = sd(Norm_Ratio), 
              n = n()) -> expsum2
  # XXX: write this to file as well
  
  write.table(expdata, file.path(d, 'summary-full.txt'), row.names = FALSE) 
  write.table(expsum1, file.path(d, 'summary-perseedling.txt'), row.names = FALSE)
  
  cat("\nCalculating statistics for experiment", experiment, "... ")
  
  # calculate p-values using both t-test (unpaired, two-tailed, no assumption of equal variances, log-transformation of ratios)
  # and permutation test. 
  # we need to check for the special cases where reporters and controls are named with '-N' suffix
  rept <- t.test(expsum1$Raw_Log_Ratio[expsum1$Line=='Reporter' & expsum1$Treatment=='Vehicle'], 
                 expsum1$Raw_Log_Ratio[expsum1$Line=='Reporter' & expsum1$Treatment!='Vehicle'])
  ctrlt <- t.test(expsum1$Raw_Log_Ratio[expsum1$Line=='Control' & expsum1$Treatment=='Vehicle'], 
                  expsum1$Raw_Log_Ratio[expsum1$Line=='Control' & expsum1$Treatment!='Vehicle'])
  perm <- NA
  ctrlperm <- NA

  # *** uncomment lines below to get permutation-based p-values ***
  #
  # perm <- summary(aovp(Mean_Raw_Ratio ~ Treatment, 
  #                      data=expsum1[expsum1$Line=='Reporter',], perm='Prob'))
  # ctrlperm <- summary(aovp(Mean_Raw_Ratio ~ Treatment, 
  #                          data=expsum1[expsum1$Line=='Control',], perm='Prob'))

  r.p.pval <- unlist(perm)[9]
  c.p.pval <- unlist(ctrlperm)[9]
  rept.pval <- rept$p.value
  ctrlt.pval <- ctrlt$p.value

  perms <- c(perms, r.p.pval)
  ctrlperms <- c(ctrlperms, c.p.pval)
  repts <- c(repts, rept.pval)
  ctrlts <- c(ctrlts, ctrlt.pval)
}

# collect the p-values computed using all methods and save them to a file in main dir
exppvals <- data.frame(Experiment = experiments, Reporter.ttest.pval = repts, Control.ttest.pval = ctrlts, 
                       Reporter.perm.pval = perms, Control.perm.pval = ctrlperms, stringsAsFactors = FALSE)
write.table(exppvals, file.path(dir, 'pvals.txt'), row.names=FALSE, sep='\t')

alldata %>% 
  group_by(Experiment) %>% 
  group_by(Line, add = TRUE) %>% 
  group_by(Treatment, add = TRUE) %>% 
  group_by(Seedling, add = TRUE) %>% 
  summarize(Norm_Ratio = mean(Norm_Ratio)) -> allsum

# also save complete data set as well as per-seedling summaries of all experiments
write.table(allsum, file.path(dir, 'summary-perseedling.txt'), row.names = FALSE, sep='\t', quote=FALSE)
write.table(alldata, file.path(dir, 'summary.txt'), row.names = FALSE, sep='\t', quote=FALSE)

scripttime <- Sys.time() - starttime
units(scripttime) <- 'mins'
cat("Took", scripttime, "minutes to process", n, "files.\n")

# add a quick graph to the dir
quickgraph <- ggplot(allsum, aes(y=Norm_Ratio, x=Line)) + 
  facet_wrap(. ~ Experiment) + 
  geom_boxplot() + 
  ylab('Normalized ratio') + 
  theme(axis.title.x = element_blank(), panel.background = element_blank())
ggsave(file.path(dir, 'summary-graph.pdf'))
