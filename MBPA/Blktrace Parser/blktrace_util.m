% extract the data from "top" output to analyze the blktrace utilization
% abandant 

filename='top.log';
fid=fopen(filename);
n_value=zeros(5,100);
con1=0;
tline=fgetl(fid);

while ischar(tline)
    s1=sscanf(tline,'  %s %*s');
    if strcmp(s1,'PIDPRVIRTSHR%CPUTIME+')
        tline=fgetl(fid);
        if size(tline,2)>10
            s2=sscanf(tline,' 1421 %s %*s');
            if strcmp(s2,'root')
                con1=con1+1;
                x1=sscanf(tline, ' 1421 root      20   0  %dm  %d  %d S  %f  %f   %*s'); 
                if size(x1,1)<5
                    x1=sscanf(tline, ' 1421 root      20   0  %dm  %dm  %dm S  %f  %f   %*s'); 
                    x1(2:3)=x1(2:3)*1024;
                else
                    
                end
                n_value(:,con1)=x1;
            end
            tline=fgetl(fid);
        else      
            tline=fgetl(fid);
            continue;
        end        
    end
    tline=fgetl(fid);
end
fclose(fid);

%generate a graph of detailed memory utilization
figure;
subplot(3,1,1);
plot((1:con1)*5, n_value(1,:));
ylabel('VIRT (MB)')
subplot(3,1,2);
plot((1:con1)*5, n_value(2,:));
ylabel('RES (KB)')
subplot(3,1,3);
plot((1:con1)*5, n_value(3,:));
ylabel('SHR (MB)')
xlabel('time (second)')

%generate graph of memory and cpu utilization
figure
subplot(2,1,1);
plot((1:con1)*5, n_value(4,:));
ylabel('CPU Util %')
subplot(2,1,2);
plot((1:con1)*5, n_value(5,:));
ylabel('MEM Util')
