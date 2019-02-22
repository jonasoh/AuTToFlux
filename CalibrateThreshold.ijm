// CalibrateThreshold.ijm - 
//   process all images in a directory using a range of threshold settings. 
//   this will aid in determining proper values for a particular setup. 

// ask the user for the directory with images to process
dir = getDirectory("Choose directory");

// get file listing
list = getFileList(dir);

// we only process files ending in .tif
imglist = newArray(0);
for(w = 0; w < list.length; w++) {
	if(endsWith(list[w], 'tif')) {
		imglist = Array.concat(imglist, list[w]);
	}
}

// loop over all images
for(w = 0; w < imglist.length; w++) {
	name = dir + File.separator + imglist[w];
	basename = File.getName(name);

	run("Bio-Formats Windowless Importer", "open=[" + name + "]");

	// use the gfp channel
	run("Split Channels");
	close("C3-*");
	close("C2-*");

	// main loop; try every threshold setting between (0, 1) and (0, 15)
	for(upper_threshold = 1; upper_threshold < 15; upper_threshold++) {
		// first, make a duplicate of the image
		run("Duplicate...", " ");
		run("8-bit");
		// thresholding magic
		setThreshold(0, upper_threshold);

		run("Convert to Mask");
		run("Make Binary");
		run("Options...", "iterations=3 count=7 pad do=Open");
		run("Remove Outliers...", "radius=10 threshold=50 which=Bright");
		run("Invert");
		run("Options...", "iterations=3 count=4 pad do=Dilate");
		run("Fill Holes");
		run("Erode");
		run("Analyze Particles...", "size=50-5000 show=Masks clear add");
		roiManager("reset");
		roiManager("Multi-measure measure_all");

		// save the mask and close image
		saveAs("Tiff", name + ".mask.thr0-" + upper_threshold + ".tif");
		saveAs("Results", name + ".mask.thr0-" + upper_threshold + ".csv");
		close(); close();
	}
	close();
}
