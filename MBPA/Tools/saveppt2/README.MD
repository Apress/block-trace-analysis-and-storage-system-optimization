This tool was developed by Jedediah Frey
See https://www.mathworks.com/matlabcentral/fileexchange/19322-saveppt2 

## Description	
saveppt2 builds on saveppt to include many new options.

Saveppt2 Features: 
Save multiple plots to the same PowerPoint slide. 
Create slides with and without a title. 
Add notes to a PowerPoint slide 
Scale the figure to fill the slide (with and without locking aspect ratio). 
Horizontally and vertically align figures on the slide. 
Use a template file for creating a new presentation. (Useful for automated reports) 
Add padding to any of the sides for use with scaling or aligning figures.

New in Jun 2010. 
Can choose between Metafile or bitmap drivers when copy and pasting to PowerPoint. 
Add a blank title page or blank page from Matlab. 
Add comments & textbox to slide. 
Make PowerPoint visible during operations. (Required for Comments). 
If there is another PowerPoint presentation open, PowerPoint will not quit. 
Disable closing of PowerPoint presentation and return ActiveX object for further programmatic slide manipulation.

Also added a method to do batch processing by keeping an ActiveX session open and just adding new slides to it. 
ppt=saveppt2('batch.ppt','init'); 
  for i=1:10 
      plot(rand(1,100),rand(1,100),'*'); 
      saveppt2('ppt',ppt) 
end 
saveppt2('batch.ppt','ppt',ppt,'close');

The zip file includes saveppt2 and a sample presentation created with saveppt2. The code for creating the presentation is also included. 
 
GitHub Project: 
http://github.com/jedediahfrey/Jedediah-Frey-s-MATLABCentral-Projects

## Acknowledgements	
Saveppt, Xlswrite1, and Validate Input inspired this file.

This file inspired Preclinical Pkpd Modeling, Slide Extractor Fig, Power Point Slide Extractor, and Block Edf Heat Map View.

## MATLAB release	
MATLAB 7.5 (R2007b)

## Other requirements	
Requires Windows because it uses ActiveX. This was tested on 2007b and Office 2000 on Windows XP SP3. It should work with other releases.
