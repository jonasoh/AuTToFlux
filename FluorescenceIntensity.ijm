// FluorescenceIntensity.ijm
//   processes all files in a certain directory and subfolders of that directory 
//   using thresholding magic to detect vacuoles, and records their intensities.

// ask the user for the directory with images to process
dir = getDirectory("Choose directory");

// also ask for the upper threshold limit
upper_threshold = getNumber("Upper threshold limit", 1);

// note start time, for benchmarking
start = getTime();

// get file listing
list = getFileList(dir);
newlist = list;

// expand directories -- we only recurse one level deep
// (i.e. main directory with subdirs for each experiment
for(i = 0; i < list.length; i++) {
	if (endsWith(list[i], '/')) {
		files = getFileList(dir + list[i]);
		for (n = 0; n < files.length; n++) {
			files[n] = list[i] + '/' + files[n];
		}
		newlist = Array.concat(newlist, files);
	}
}
list = newlist;

// we only process files ending in .tif
imglist = newArray(0);
for(w = 0; w < list.length; w++) {
	if(endsWith(list[w], 'tif')) {
		imglist = Array.concat(imglist, list[w]);
	}
}

// set correct measurements
run("Set Measurements...", "area mean redirect=None decimal=3");

// loop over all images
for(w = 0; w < imglist.length; w++) {
	name = dir + '/' + imglist[w];
	basename = File.getName(name);

	run("Bio-Formats Windowless Importer", "open=[" + name + "]");

	// save the gfp channel and close the others
	run("Split Channels");
	close("C3-*");
	close("C2-*");
	saveAs("Tiff", name + ".gfp.tif");

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

	run("ROI Manager...");
	nrois = roiManager("count");

	// process the rois, if there are any
	if (nrois > 0) {
		saveAs("Tiff", name + ".mask.tif");

		run("Bio-Formats Windowless Importer", "open=[" + name + "]");

		for (i = 0; i < nrois; i++) {
			roiManager("Select", i);
			roiManager("Multi-measure measure_all append one");
		}

		// save the results to .csv file
		run("Input/Output...", "jpeg=0 gif=-1 file=.csv use_file copy_column copy_row save_column save_row");
		saveAs("Results", name + ".csv");
	} else {
		print("No ROIs in " + name);
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
num = imglist.length;
print("Processed " + num + " images in " + elapsed + " seconds.");
