%%JUN, what's the file input format? output format looks like an excel sheet

%filename='testlog.txt';
filename='chunks_deleted_5-22';
outfile='outfile.xlsx';
fid=fopen(filename);
tline=fgetl(fid);

request_lba_list=zeros(100000,10);
request_size_list=zeros(100000,10);
request_time_list=zeros(100000,7);

cont=0;
while ischar(tline)
    cont=cont+1;
    a=size(tline,2);
    
    time0=sscanf(tline,'%d-%d-%d %d:%d:%d,%d%*s');
    request_time_list(cont,:)=time0(1:7);
    str_ask=strfind(tline,'ask');
    if ~isempty(str_ask)
        ip_address=sscanf(tline(str_ask+3:a),'%d.%d.%d.%d:%d%*s');
    end
    
    str_blk=strfind(tline,'blk_');
    if ~isempty(str_blk)
        b=size(str_blk,2);
        for i=1:b
            if tline(str_blk+4)=='-'
                request=sscanf(tline(str_blk(i)+5:a),'%d_%d%*s');
            else
                request=sscanf(tline(str_blk(i)+4:a),'%d_%d%*s');
            end
            request_lba_list(cont,i)=request(1);
            request_size_list(cont,i)=request(2);
        end
    else
        
    end
   tline=fgetl(fid);     
end
fclose(fid);

% you can write to different files to reduce size
xlswrite(outfile,request_lba_list,1);
xlswrite(outfile,request_size_list,2);
xlswrite(outfile,request_time_list,3);
