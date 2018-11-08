% process and plot Q & C data from btt results
% INPUT is the blocktrace file
% Output is the graphed results
function QC=plot_QC_profile(filename,options)

fid=fopen(filename);

if fid<0
    disp('error to open the file');
    return
end

si=20000;
si_inc=5000;
QC_array=zeros(si,2); % time, seek distance
i=0;
tline=fgetl(fid); %     Total System : c activity
tline=fgetl(fid); %# Per process
tline=fgetl(fid);
j=0;
while ischar(tline)
    % we purposely omit the first one.
    i=i+1; 
    [t, gap]=sscanf(tline, '%f     %d ');
    
    %     if strcmp(tline,'# Per process')
    %         disp('End of Total System; break');
    %         break;
    %     end
    
    if isempty(t)
        if j==0
            disp('End of Total System: q activity; continue c activity');
            qi=i;
            i=0;
            Q_array=QC_array(1:qi,:);
            tline=fgetl(fid);
            tline=fgetl(fid);
            j=j+1;
            continue;
        else
            disp('End of Total System: c activity; break');
            break;            
        end
    end
       
    if i>si
        QC_array=[QC_array;zeros(si_inc,2)];
        si=si+si_inc;
    else
        
    end
    QC_array(i,:)=(t([1,3]))';
    tline=fgetl(fid);
end

if isfield(options, 'plot_figure')
    plot_figure=options.plot_figure;
else
    plot_figure=1;
end

if isfield(options, 'plot_title')
    plot_title=options.plot_title;
else
    plot_title='';
end

if isfield(options, 'plot_omit')
    plot_omit=options.plot_omit;
else
    plot_omit=1;
end

if plot_omit==1
    QC_array=QC_array(2:i,:);
    rem_str='';
else
    QC_array=QC_array(1:i,:);
    rem_str=' QC Activity';
end

ci=i;

% compact Q_array
temp=Q_array(1,2);
Q_array_new=Q_array;
j=1;
for i=2:qi-1
    if abs(Q_array(i,2)-temp)<0.001  % actually the same value
        continue;
    else
        j=j+1;
        Q_array_new(j,:)=Q_array(i,:);
        temp=Q_array(i,2);
    end
end
Q_array_new=Q_array_new(1:j,:);
qj=j;

if mod(j,2)==1
    even_index=0;
else
    even_index=1;
end

if abs(Q_array_new(1,2))<0.001  % the first value is zero, at idle
    idle_time_array=(Q_array_new(2:2:qj,1)-Q_array_new(1:2:qj-1,1));
    idle_time=sum(idle_time_array);
    idle_time_array=[Q_array_new(1:2:qj-1,1) idle_time_array];
else
    idle_time_array=(Q_array_new(3:2:qj,1)-Q_array_new(2:2:qj-1,1));
    idle_time=sum(idle_time_array);
    idle_time_array=[Q_array_new(2:2:qj-1,1) idle_time_array];
end
Q_busy_time=Q_array_new(qj,1)-idle_time;
Q_idle_time=idle_time;
Q_idle_time_freq=size(idle_time_array,1);
Q_idle_time_mean=mean(idle_time_array(:,2));
Q_idle_time_array=idle_time_array;

QC.Q_busy_time=Q_busy_time;
QC.Q_idle_time=Q_idle_time;
QC.Q_idle_time_freq=Q_idle_time_freq;
QC.Q_idle_time_mean=Q_idle_time_mean;
QC.Q_idle_time_array=Q_idle_time_array;


% compact C_array
temp=QC_array(1,2);
QC_array_new=QC_array;
j=1;
for i=2:ci-1
    if abs(QC_array(i,2)-temp)<0.001  % actually the same value
        continue;
    else
        j=j+1;
        QC_array_new(j,:)=QC_array(i,:);
        temp=QC_array(i,2);
    end
end
C_array_new=QC_array_new(1:j,:);
cj=j;

if abs(C_array_new(1,2)-0.5)<0.001  % the first value is 0.5, at idle
    idle_time_array=(C_array_new(2:2:cj,1)-C_array_new(1:2:cj-1,1));
    idle_time=sum(idle_time_array);
    idle_time_array=[C_array_new(1:2:cj-1,1) idle_time_array];
else
    idle_time_array=(C_array_new(3:2:cj,1)-C_array_new(2:2:cj-1,1));
    idle_time=sum(idle_time_array);
    idle_time_array=[C_array_new(2:2:cj-1,1) idle_time_array];
end
C_busy_time=C_array_new(cj,1)-idle_time;
C_idle_time=idle_time;
C_idle_time_freq=size(idle_time_array,1);
C_idle_time_mean=mean(idle_time_array(:,2));
C_idle_time_array=idle_time_array;
QC.C_busy_time=C_busy_time;
QC.C_idle_time=C_idle_time;
QC.C_idle_time_freq=C_idle_time_freq;
QC.C_idle_time_mean=C_idle_time_mean;
QC.C_idle_time_array=C_idle_time_array;


if plot_figure==1
    figure;
    % plot(QC_array(:,1),QC_array(:,2));
    plot(C_array_new(:,1),C_array_new(:,2),'*','MarkerSize',0.5);
    hold on;
    plot(Q_array_new(:,1),Q_array_new(:,2),'r*','MarkerSize',0.5);
    legend('C activity','Q activity')
    xlabel('time(s)')
    ylabel('High=on; Low=off')
    title({[plot_title,' ', rem_str, 'Total time=', num2str(C_array_new(cj,1),3)];['Q idle time=', num2str(Q_idle_time), ' with freq=', num2str(Q_idle_time_freq,3), ' and mean=', num2str(Q_idle_time_mean,3)  ];['C idle time=', num2str(C_idle_time), ' with freq=', num2str(C_idle_time_freq,3), ' and mean=', num2str(C_idle_time_mean,3), ]});
    
    figure;
    subplot(2,1,1)
    plot(Q_idle_time_array(:,1),Q_idle_time_array(:,2)*1000,'*','MarkerSize',0.5);
    ylabel('Q idle time (ms)')
    title({[plot_title,' ', rem_str, 'Total time=', num2str(C_array_new(cj,1),3)];['Q idle time=', num2str(Q_idle_time), ' with freq=', num2str(Q_idle_time_freq,3), ' and mean=', num2str(Q_idle_time_mean,3)];[' C idle time=', num2str(C_idle_time), ' with freq=', num2str(C_idle_time_freq,3), ' and mean=', num2str(C_idle_time_mean,3), ]});

    subplot(2,1,2)
    plot(C_idle_time_array(:,1),C_idle_time_array(:,2)*1000,'*','MarkerSize',0.5);
    ylabel('C idle time (ms)')
    xlabel('time(s)')
end
