% remove the FS-related event and obtain filtered events.
% This file is an example of how to do multiple files simultaneously
% filepath1 is the directory where the blktrace files are located
% filepath2 is the directory where the .fs files will be output
filepath1='';
filepath2='';

%For every input file in your directory, create names for your output
%In this example, there are two blktrace files in filepath 1, and three in filepath 2
%Exercise for the reader: 
%                        1) automate this array generation to strip the blktrace
%                           filename and feed it into the output field
%                        2) Then, set the iterative value of the for loop to
%                           correctly reflect the number of files that need to 
%                           be processed and save it as blktrace_size3.m

filename_array={[filepath1,'sdb_all_147'],[filepath1,'sdb_fs_147'],[filepath2,'sdb_all_148'],[filepath2,'sdb_all2_148'],[filepath2,'sdb_fs_148']};

for i=4:4
    filename=filename_array{i};
    
    fid=fopen(filename);
    tline=fgetl(fid);
    filename1=[filename,'.fs'];
    fid1=fopen(filename1,'w');
    % m=109; I=73; D=68; C=67
    % find the FS filtered 
    while ischar(tline)
        x=sscanf(tline,'  %*d,%*d   %*d        %*d     %*f %*d  %s %*s');
        if x==109 | x==73 | x==68 | x==67
            fprintf(fid1,'%s\n',tline);        
        end
        tline=fgetl(fid);
    end
    fclose(fid);
    fclose(fid1);
    
    
end
