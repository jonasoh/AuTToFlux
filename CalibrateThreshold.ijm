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

// save all masks to a temporary file
// we use this file to create a montage later
path = getDirectory("temp")+"list.txt";
f = File.open(path);

// loop over all images
for(w = 0; w < imglist.length; w++) {
	name = dir + File.separator + imglist[w];
	basename = File.getName(name);

	run("Bio-Formats Windowless Importer", "open=[" + name + "]");

	// use the mWasabi channel
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
		maskname = dir + File.separator + w + ".mask.thr0-" + upper_threshold;
		saveAs("Tiff", maskname + ".tif");
		saveAs("Results", maskname + ".csv");

		// write mask filename to list for later opening
		print(f, maskname + ".tif");

		close(); close();
	}
	close();
}

File.close(f);
run("Stack From List...", "open="+path+" use");
run("Make Montage...", "columns=14 scale=0.25 border=10 label");
saveAs("Tiff", dir + File.separator + "threshold-overview.tif");
close(); close();
