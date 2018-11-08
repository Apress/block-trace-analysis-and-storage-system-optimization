% process and plot active queue data from btt parameter "Q"
function queue_array=plot_queue_profile(filename,options)

fid=fopen(filename);

if fid<0
    disp('error to open the file');
    return
end

si=20000;
si_inc=5000;
queue_array=zeros(si,2); % time, seek distance
i=0;
tline=fgetl(fid);
while ischar(tline)
    % we purposely omit the first one.
    i=i+1;
    [t, gap]=sscanf(tline, '%f     %d ');
    if i>si
        queue_array=[queue_array;zeros(si_inc,2)];
        si=si+si_inc;
    else
        queue_array(i,:)=t';
    end
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
    queue_array=queue_array(2:i,:);
    rem_str='';
else
    queue_array=queue_array(1:i,:);
    rem_str=' Active Queue Depth';
end

queue_mode=mode(queue_array(:,2));
queue_mean=mean(queue_array(:,2));
% queue_abs_mean=mean(abs(queue_array(:,2)));
queue_mode_freq=size(find(queue_array(:,2)==queue_mode),1);
queue_mode_ratio=queue_mode_freq/i;
queue_middle_ratio=size(find(queue_array(:,2)>5 & queue_array(:,2)<=10),1)/i;
queue_large_ratio=size(find(queue_array(:,2)>10),1)/i;
Queue.queue_array=queue_array;
Queue.queue_mode=queue_mode;
Queue.queue_mean=queue_mean;
Queue.queue_mode_freq=queue_mode_freq;
Queue.queue_mode_ratio=queue_mode_ratio;
Queue.queue_middle_ratio=queue_middle_ratio;
Queue.queue_large_ratio=queue_large_ratio;

if plot_figure==1
    figure;
    plot(queue_array(:,1),queue_array(:,2),'*','MarkerSize',0.5);
    xlabel('time(s)')
    ylabel('Queue depth')
    title({[plot_title,' ', rem_str ];[' Queue Depth Mode=', int2str(queue_mode),' with frequency=', int2str(queue_mode_freq), ' and ratio=', num2str(queue_mode_ratio,3)];['Mean=', num2str(queue_mean),  '; 5<QD<=10 ratio=', num2str(queue_middle_ratio), '; QD>10 ratio=', num2str(queue_large_ratio) ]});
end