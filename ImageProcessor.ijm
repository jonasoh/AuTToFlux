// ImageProcessor.ijm -
//   batch process all images in a given directory. 
//   converts images to TIFF and saves the acquisition dates. 

run("Bio-Formats Macro Extensions");

// ask the user for the directory with images to process
dir = getDirectory("Choose directory");

// note start time, for benchmarking
start = getTime();
num = 0;

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

// only process image files
images = newArray(0);
for(w = 0; w < list.length; w++) {
	fn = dir + '/' + list[w];
	Ext.isThisType(fn, type)
	if (type == "true") {
		images = Array.concat(images, fn);
	}
}

// process images
for (n = 0; n < images.length; n++) {
	Ext.setId(images[n]);
	Ext.getSeriesCount(count);
	if (count == 1) {
		// file contains only one image
		run("Bio-Formats Windowless Importer", "open=[" + images[n] + "]");
		saveAs("tiff", images[n] + ".tif");
		Ext.getImageCreationDate(crdate);
		File.saveString(crdate, images[n] + ".tif.time");
		num++;
		close();
	} else {
		// file contains several images; save each separately
		for (i = 1; i < count + 1; i++) {
			Ext.setSeries(i - 1);
			Ext.getSeriesName(sname);
			Ext.getImageCreationDate(crdate);
			run("Bio-Formats Importer", "open=[" + images[n] + "] series_" + i);
			saveAs("tiff", dir + File.separator + sname + ".tif");
			File.saveString(crdate, dir + '/' + sname + ".tif.time");
			num++;
			close();
		}
	}
}

elapsed = (getTime() - start) / 1000;
print("Processed " + num + " images in " + elapsed + " seconds.");
