# AuTToFlux
AuTToFlux is a pipeline for analyzing RFP/GFP ratios in vacuoles, used in the Tandem Tag assay for autophagic flux quantification. 

The pipeline consists of two parts. The first part, written in the ImageJ macro language, converts images from different microscopy manufacturers into a common format (ImageProcessor.ijm) and then find the vacuoles and calculates the RFP and GFP intensities for them (ThresholdMacro.ijm). The second part, written in R, processes the data and generates statistics. 

```
# Install dependencies
install.packages(c("ggplot2", "dplyr", "readr"))
```
