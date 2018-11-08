% this program is used to remove the FS related events in blktrace trace,
% i.e., with the similar output of "-a fs"
% Input  parameter: Filepath of blktrace file
% Output parameter: Filepath/name of the output file
%                   Output is all of the stripped filesystem events 

%%JUN: I added some comments about input and output parameters for this 
%%     Make sure I'm correct ^.^ 

filename=''
fid=fopen(filename);
tline=fgetl(fid);  

filename1=''
fid1=fopen(filename1,'w');
tline=fgetl(fid);
% Scan distances for FS events
% m=109; I=73; D=68; C=67
while ischar(tline)
    x=sscanf(tline,'  %*d,%*d   %*d        %*d     %*f %*d  %s %*s');
    if x==109 | x==73 | x==68 | x==67
        fprintf(fid1,'%s\n',tline);
    end
    tline=fgetl(fid);
end
fclose(fid);
fclose(fid1);
