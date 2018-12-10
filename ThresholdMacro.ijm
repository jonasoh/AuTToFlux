// ThresholdMacro.ijm

// ask the user for the directory with images to process
dir = getDirectory("Choose directory");

// note start time, for benchmarking
start = getTime();

// get file listing
list = getFileList(dir);
newlist = list;

// expand directories -- we only recurse one level deep
// (i.e. main directory with subdirs for each experiment
for(i = 0; i < list.length; i++) {
	if (endsWith(list[i], File.separator)) {
		print("checking " + list[i]);
		files = getFileList(dir + list[i]);
		for (n = 0; n < files.length; n++) {
			files[n] = list[i] + File.separator + files[n];
		}
		newlist = Array.concat(newlist, files);
		Array.print(newlist);
	}
}
list = newlist;

// we only process files ending in .tif
czilist = newArray(0);
for(w = 0; w < list.length; w++) {
	if(endsWith(list[w], 'czi')) {
		czilist = Array.concat(czilist, list[w]);
	}
}

// loop over all images
for(w = 0; w < czilist.length; w++) {
	name = dir + File.separator + czilist[w];
	basename = File.getName(name);

	run("Bio-Formats Windowless Importer", "open=[" + name + "]");

	// save the gfp channel and close the others
	run("Split Channels");
	close("C3-*");
	close("C2-*");
	saveAs("Tiff", name + ".gfp.tif");

	run("8-bit");
	setAutoThreshold("Percentile");

	// thresholding magic
	setThreshold(0, 1);
	run("Convert to Mask");
	run("Make Binary");
	run("Options...", "iterations=3 count=7 pad do=Open");
	run("Remove Outliers...", "radius=10 threshold=50 which=Bright");
	run("Invert");
	run("Options...", "iterations=3 count=4 pad do=Dilate");
	run("Fill Holes");
	run("Erode");
	run("Analyze Particles...", "size=500-5000 show=Masks clear add");

	run("ROI Manager...");
	nrois = roiManager("count");

	// process the rois, if there are any
	if (nrois > 0) {
		saveAs("Tiff", name + ".mask.tif");

		run("Bio-Formats Windowless Importer", "open=" + name);

		for (i = 0; i < nrois; i++) {
			roiManager("Select", i);
			roiManager("Multi-measure measure_all append one");
		}

		// save the results to .csv file
		run("Input/Output...", "jpeg=0 gif=-1 file=.csv use_file copy_column copy_row save_column save_row");
		saveAs("Results", name + ".csv");

		// write the creation date to a separate file
		f = File.open(name + ".time");
		File.close(f);
	}

	if (nrois>0) {
		roiManager("reset");
	}

	// clean up before the next iteration
	run("Clear Results");
	while (nImages>0) {
		selectImage(nImages);
		close();
	}
}

if (isOpen("ROI Manager")) {
	selectWindow("ROI Manager");
	run("Close");
}

if (isOpen("Results")) {
	selectWindow("Results");
	run("Close");
}

elapsed = (getTime() - start) / 1000;
num = czilist.length;
print("Processed " + num + " images in " + elapsed + " seconds.");
