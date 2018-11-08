%% trunk the file into small size
% filename: the file to be trunked
function partition_file(filename)

fid = fopen(filename);
[pathstr,name,ext] = fileparts(filename);
allocated_num=500000;
count0=0;
filenamew=[pathstr,'\',name,int2str(allocated_num),ext];
fidw=fopen(filenamew,'w');
for i=1:allocated_num
    tline = fgetl(fid);
   fprintf(fidw,'%s\n', tline) ;
end

fclose(fid);
fclose(fidw);
