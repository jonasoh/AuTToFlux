# AuTToFlux
AuTToFlux is a pipeline for analyzing RFP/GFP ratios in vacuoles, used in the Tandem Tag assay for autophagic flux quantification. 

![Workflow diagram](https://user-images.githubusercontent.com/6480370/53161378-3035aa00-35ca-11e9-8aa3-02b8d01a90c4.png)

The pipeline consists of two parts. The first part, written in the ImageJ macro language, converts images from different microscopy manufacturers into a common format (ImageProcessor.ijm) and then find the vacuoles and calculates the RFP and GFP intensities for them (ThresholdMacro.ijm). The second part, written in R, processes the data and generates statistics. 

Details on the pipeline can be found in the preprint manuscript: Dauphinee et al. (2019) <b>Chemical screening pipeline for identification of specific plant autophagy modulators</b>. doi: [10.1101/569327](https://doi.org/10.1101/569327) 
