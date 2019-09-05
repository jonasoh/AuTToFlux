# Tandem tag assay


The Tandem Tag assay is a widespread approach for quantifying autophagic activity in living cells. Here we describe a step-by step description of semi-automated high-throughput TT asay optimized for measuring autophagic activity in <i>Arabidopsis thaliana</i> roots and provide designated ImageJ macro and R scrpts for it.

The detailed protocol for TT asay can be found [here](https://github.com/jonasoh/AuTToFlux/blob/master/TT%20assay%20protocol/Dauphinee%20et%20al%202019.pdf)

This assay was developed for the study published in [(Dauphinee et al., 2019)](https://doi.org/10.1101/569327). 

The assay includes high-throughput analysis of CLSM images using the designated AuTToFlux pipeline. The pipeline consists of two main parts: 
1. Image processing using ImageJ macro:
 - convert images from different microscopy manufacturers into a common format  [ImageProcessor.ijm](https://github.com/jonasoh/AuTToFlux/blob/master/ImageJ%20macro/ImageProcessor.ijm)
 - if needed, fine tune the tresholding parameters to best match the image quality [CalibrateThreshold.ijm](https://github.com/jonasoh/AuTToFlux/blob/master/ImageJ%20macro/CalibrateThreshold.ijm)
 - identify the vacuoles and calculate the fluorescence intensities ratio for the reporter proteins  [FluorescenceIntensity.ijm](https://github.com/jonasoh/AuTToFlux/blob/master/ImageJ%20macro/FluorescenceIntensity.ijm).
 
2. Analyzing the obtained quantitative data using R scripts for different types of comparisons and generates statistics:
- changes of autophagic activity with time [Flux-vs-Time.R](https://github.com/jonasoh/AuTToFlux/blob/master/R%20scripts/Flux-vs-Time.R)
- comparison of atuphagic activty in control vs reporter lines [Control-vs-Reporter.R](https://github.com/jonasoh/AuTToFlux/blob/master/R%20scripts/Control-vs-Reporter.R)

![Workflow diagram](https://user-images.githubusercontent.com/6480370/54531906-c0c39800-4986-11e9-868f-4f0e9ecb9d00.png)

<b>TT assay workflow diagram </b>
