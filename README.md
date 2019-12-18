# Tandem tag assay

The Tandem Tag (TT) assay is a widespread approach for quantifying autophagic activity in living cells. Here, we provide a semi-automated high-throughput TT assay optimized for measuring autophagic activity in <i>Arabidopsis thaliana</i> roots and designated ImageJ macro and R scripts that enable analysis.

The detailed protocol for the TT assay can be found [here](https://github.com/jonasoh/AuTToFlux/blob/master/TT%20assay%20protocol/Dauphinee%20et%20al%202019.pdf).

This assay was developed for the study published in [(Dauphinee et al., 2019)](https://doi.org/10.1104/pp.19.00647).

The assay includes high-throughput analysis of CLSM images using the designated AuTToFlux pipeline. The pipeline consists of the following steps:
1. Image processing using ImageJ macro:
 - convert images from different microscopy manufacturers into a common format ([ImageProcessor.ijm](https://github.com/jonasoh/AuTToFlux/blob/master/ImageJ%20macro/ImageProcessor.ijm)).
 - if needed, fine tune the tresholding parameters to best match the image quality ([CalibrateThreshold.ijm](https://github.com/jonasoh/AuTToFlux/blob/master/ImageJ%20macro/CalibrateThreshold.ijm)).
 - identify the vacuoles and calculate the fluorescence intensities ratio for the reporter proteins  ([FluorescenceIntensity.ijm](https://github.com/jonasoh/AuTToFlux/blob/master/ImageJ%20macro/FluorescenceIntensity.ijm)).
 
2. Analyzing the obtained quantitative data using R scripts for different types of comparisons, and generating statistics:
- autophagic activity as a function of time ([Flux-vs-Time.R](https://github.com/jonasoh/AuTToFlux/blob/master/R%20scripts/Flux-vs-Time.R)).
- comparison of autophagic activity in control vs reporter lines ([Control-vs-Reporter.R](https://github.com/jonasoh/AuTToFlux/blob/master/R%20scripts/Control-vs-Reporter.R)).




[Here](https://zenodo.org/record/3583102#.XfpQO0dKhjE) you can find demo files and also [insrtuction videos](https://www.youtube.com/playlist?list=PLPn3bUtQD5M097cH7oWE4nDg9DNO5_MwK) to test the assay prior to performing analysis of your data.
- ImageProcessor.ijm  can be tested on both folders with demo files, while following instructions provided in the [video 2](https://youtu.be/nKPq0kNvW_U)
- CalibrateThreshold.ijm can be tested on files in the Flux-vs-Time_demoFile folder. Please note that you will need to process the folder with ImageProcessor.ijm first. The three images used for treshold calibration in the [video 3](https://youtu.be/Wkw3VXFj2is) were:
   - Reporter_0.5uM.AZD_seedling1_image1
   - Reporter_Vehicle_seedling8_image3
   - Reporter_Vehicle_seedling9_image1
- FluorescenceIntensity.ijm can be tested on both folders with demo files following the intructions in the [video 4](https://youtu.be/6jYqkYXOpiQ). Please note that you will need to process folders with ImageProcessor.ijm first.  
- The Flux-vs-Time. R can be tested using Flux-vs-Time_demoFile folder that contains the micrographs utilized for [video 5](https://youtu.be/0_wDY7RN_hk). The folder includes confocal micrographs of TT reporter line seedlings exposed to 0.5µM AZD or a Vehicle (1% DMSO) treatment. Treatments were applied at 2018-03-20 9:00 and seedlings were scanned at three timepoints.
- Flux-vs-Control.R can be tested using Control-vs-Reporter_demoFile folder as demonstrated in the [video 6](https://youtu.be/PQRZ1oOBgws). The folder includes micrographs of TT Reporter and Control line seedlings treated with 0.5µM AZD or a Vehicle (1% DMSO).
 


<b>Figure 1. TT assay workflow diagram </b>

![Workflow diagram](https://user-images.githubusercontent.com/6480370/54531906-c0c39800-4986-11e9-868f-4f0e9ecb9d00.png)

