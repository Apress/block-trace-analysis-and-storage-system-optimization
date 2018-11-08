% extract the data from linux "top" output to analyze the blktrace utilization

filename='top.log';
fid=fopen(filename);
n_value=zeros(5,100);
con1=0;
tline=fgetl(fid);

x0=0;

while ischar(tline)
    s1=strfind(tline,'blktrace');
    if ~isempty(s1)
        if x0==0
            pid=sscanf(tline, ' %d root %*s');
            pid_str=int2str(pid(1));
        else
        end
            
                con1=con1+1;
                str1=[' ', pid_str, ' root      20   0  %dm  %d  %d S  %f  %f   %*s'];
                x1=sscanf(tline, str1);
                if size(x1,1)<5
                    str1=[' ', pid_str, ' root      20   0  %dm  %dm  %dm S  %f  %f   %*s'];
                    x1=sscanf(tline, str1);
                    x1(2:3)=x1(2:3)*1024;
                else
                    
                end
                n_value(:,con1)=x1;
            end
            tline=fgetl(fid);   
end
fclose(fid);

%Graph detailed memory utilization
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

%Graph memory and cpu utilization
figure
subplot(2,1,1);
plot((1:con1)*5, n_value(4,:));
ylabel('CPU Util %')
subplot(2,1,2);
plot((1:con1)*5, n_value(5,:));
ylabel('MEM Util %')
