///Written by Abby Kroken, PhD. Loyola University Chicago, 2024

//Begin with an open time-lapse that may have multuple biofilms in frame. Macro will process one biofilm in a user-defined ROI.

//cleanup from prior runs
run("Clear Results");
run("Set Measurements...", "area redirect=None decimal=3");
setBatchMode("True"); // turn off here for troubleshooting
name = getTitle();

//user selects a cropped region
makeRectangle(534, 352, 300, 300);
setBatchMode("show");
setTool("rectangle");
waitForUser("drag the box over a single biofilm");
setBatchMode("hide");/////////////////
run("Duplicate...", "title=crop duplicate channels=1");///specify other channels for multichanel images here
selectWindow("crop");

//registration and tighter cropping
run("Correct 3D drift", "channel=1 correct edge_enhance only=0 lowest=1 highest=1 max_shift_x=10.000000000 max_shift_y=10.000000000 max_shift_z=10");
selectWindow("registered time points");
makeRectangle(30, 30, 250, 250);
run("Crop");
selectWindow("crop");
close();
selectWindow("registered time points");
rename("crop");

//find bacteria with edges and global threshold
run("Duplicate...", "title=edges duplicate");
run("Find Edges", "stack");
run("Enhance Contrast", "saturated=0.35");
setAutoThreshold("Triangle dark");
run("Convert to Mask", "method=Yen background=Dark create");
//run("Close-", "stack"); ///comment out to avoid planktonic being linked in a web
run("Invert", "stack");
run("Analyze Particles...", "size=2-Infinity show=Masks stack");
run("Dilate", "stack"); ///expand the excluded region a little bit to account for edges 
run("Invert", "stack");
rename("binary");


//get number of frames
selectWindow("binary");
getDimensions(width, height, channels, slices, frames);
print("frames= " + frames);
print("slices= " + slices);

getDimensions(width, height, channels, slices, frames);
newImage("biofilm", "8-bit white", width, height, slices);
run("Invert LUT");
selectWindow("binary");


//For each frame, keep largest object and measure area
for (i=1; i<slices+1;i++) {
	setSlice(i);
	run("Duplicate...", "title=slice");
	run("Keep Largest Region");
	imageCalculator("Divide create 32-bit", "slice-largest","slice-largest");
	selectWindow("Result of slice-largest");
	run("Measure");
	
	selectWindow("slice-largest");
	run("Copy");
	selectWindow("biofilm");
	setSlice(i);
	run("Paste");
	
	selectWindow("Result of slice-largest");
	close();
	selectWindow("slice-largest");
	close();
	selectWindow("slice");
	close();
	selectWindow("binary");
}

setBatchMode("show");////////

//adjust contrast based on first frame of biofilm
selectWindow("biofilm");
run("Select None");
run("16-bit");
run("Enhance Contrast", "saturated=0.35");

//close some intermediates
selectWindow("MASK_edges");
close();
selectWindow("edges");
close();

//merge map and DIC biofilm image
selectWindow("binary");
run("16-bit");
run("Merge Channels...", "c1=biofilm c3=binary c4=crop create keep");

//copy results to clipboard
String.copyResults();

//close some intermediates
selectWindow("biofilm");
close();
selectWindow("binary");
close();

setBatchMode("exit and display");
