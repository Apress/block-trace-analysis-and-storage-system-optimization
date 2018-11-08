%% this program further parse the btt output "--dump-blocknos" via the parameter "-B"
%% get the information of arrival time, first LBA and last LBA
function IO_list=parse_dump_blocknos(filename, options)

if nargin<2
    options=1;
end

fid=fopen(filename);

if fid<0
    disp('error to open the file');
    return
end

si=20000; % initial number of requests
si_inc=5000; % incremental number
IO_list=zeros(si,3); % arrival time, first LBA and last LBA

i=0; j=1;
tline=fgetl(fid);
while ischar(tline)    
    x=sscanf(tline,'%f %d %d');
    i=i+1;
    if i>si
        IO_list=[IO_list;zeros(si_inc,3)];
        si=si+si_inc;
    end
    IO_list(i,:)=x';
    tline=fgetl(fid);j=j+1;
end
fclose(fid);

IO_list=IO_list(1:i,:);