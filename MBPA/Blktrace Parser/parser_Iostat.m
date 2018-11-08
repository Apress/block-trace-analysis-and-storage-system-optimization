%%JUN are you including this file in your book? 
%It's not clear what the input file format is here.
%is this iostat? 

clear;
filename='path to IOSTAT file log';
hostname='';
[pathstr,name,ext] = fileparts(filename);
fid=fopen(filename);
tline=fgetl(fid);
Time_record=zeros(10000,6);
SDA_record=zeros(10000,11);
SDB_record=zeros(10000,11);
CPU_record=zeros(10000,6);
tr_con=0;

while ischar(tline)
    idx_wdscnl111=strfind(tline,hostname);
    if ~isempty(idx_wdscnl111)        
        for i=1:10 % iostat repeated 10 time each round
            tline=fgetl(fid); % empty line
            tline=fgetl(fid); % time line
            idx_14=strfind(tline,'/14');
            if isempty(idx_14)
                continue;
            else
                x=sscanf(tline,'%d/%d/%d %d:%d:%d');
                
                tr_con=tr_con+1;
                Time_record(tr_con,:)=x';
                tline=fgetl(fid); %avg-cpu:  %user   %nice %system %iowait  %steal   %idle
                tline=fgetl(fid);
                y=sscanf(tline,'%f %f %f %f %f %f');
                CPU_record(tr_con,:)=y';
                tline=fgetl(fid);
                tline=fgetl(fid); % Device:         rrqm/s   wrqm/s     r/s     w/s   rsec/s   wsec/s avgrq-sz avgqu-sz   await  svctm  %util
                tline=fgetl(fid);
                za=sscanf(tline,'sda               %f     %f    %f    %f    %f    %f    %f     %f    %f   %f   %f');
                SDA_record(tr_con,:)=za';
                tline=fgetl(fid);
                zb=sscanf(tline,'sdb               %f     %f    %f    %f    %f    %f    %f     %f    %f   %f   %f');
                SDB_record(tr_con,:)=zb';
                for j=1:7
                    tline=fgetl(fid);
                end
            end
        end
       
    end
     tline=fgetl(fid);
end

SDA_record=SDA_record(1:tr_con,:);
SDB_record=SDB_record(1:tr_con,:);
Time_record=Time_record(1:tr_con,:)
CPU_record=CPU_record(1:tr_con,:);

fclose(fid);

ac_con=tr_con/10;
SDA_record_ave=zeros(ac_con,11);
SDB_record_ave=zeros(ac_con,11);
Time_record_ave=zeros(ac_con,6);
CPU_record_ave=zeros(ac_con,6);

for i=1:ac_con
SDA_record_ave(i,:)=mean(SDA_record((i-1)*10+1:i*10,:));
SDB_record_ave(i,:)=mean(SDB_record((i-1)*10+1:i*10,:));
%Time_record_ave(i,:)=mean(SDA_record((i-1)*10+1:i*10,:));
CPU_record_ave(i,:)=mean(CPU_record((i-1)*10+1:i*10,:));
end

figure;
h=bar(CPU_record_ave,'stacked');
set(h(1),'FaceColor','r')
set(h(2),'FaceColor','b')
set(h(3),'FaceColor','c')
set(h(4),'FaceColor','y')
set(h(5),'FaceColor','k')
set(h(6),'FaceColor','g')
title('System CPU Average Utilization');
legend('%user','%nice', '%system', '%iowait',  '%steal',   '%idle')
xlabel('time (per 5 min)')
ylabel('utilization percent')

figure;
hold on;
plot(1:ac_con,SDB_record_ave(:,1),'r:');
plot(1:ac_con,SDB_record_ave(:,2),'b');
title('Request Merged Per Second');
legend('read','write')
xlabel('time (per 5 min)')
ylabel('rqm/s')

figure;
hold on;
plot(1:ac_con,SDB_record_ave(:,3),'r:');
plot(1:ac_con,SDB_record_ave(:,4),'b');
title('IO Per Second');
legend('read','write')
xlabel('time (per 5 min)')
ylabel('IOPS')

figure;
hold on;
plot(1:ac_con,SDB_record_ave(:,5)/2048,'r:');
plot(1:ac_con,SDB_record_ave(:,6)/2048,'b');
title('Throughput');
legend('read','write')
xlabel('time (per 5 min)')
ylabel('MB/s')

figure;
hold on;
plot(1:ac_con,SDB_record_ave(:,7)/2,'k-.');
plot(1:ac_con,SDB_record_ave(:,5)./SDB_record_ave(:,3)/2,'r:');
plot(1:ac_con,SDB_record_ave(:,6)./SDB_record_ave(:,4)/2,'b');
title('Average Size');
legend('combined','read','write')
xlabel('time (per 5 min)')
ylabel('KB')


figure;
hold on;
plot(1:ac_con,SDB_record_ave(:,8),'b');
title('Average Queue Length');
xlabel('time (per 5 min)')
ylabel('length')

figure;
hold on;
plot(1:ac_con,SDB_record_ave(:,9),'r:');
plot(1:ac_con,SDB_record_ave(:,10),'b');
title('Response Time and Service Time');
legend('await','svctm')
xlabel('time (per 5 min)')
ylabel('time (ms)')


figure;
hold on;
plot(1:ac_con,100-CPU_record_ave(:,6),'r:');
plot(1:ac_con,SDB_record_ave(:,11),'b');
title('System Utlis. vs Device Utlis.');
legend('System','Device')
xlabel('time (per 5 min)')
ylabel('Percent')

