% process and plot seek data from btt result
function Seek=plot_seek_profile(filename,options)

fid=fopen(filename);

if fid<0
    disp('error to open the file');
    return
end

si=20000;
si_inc=5000;
seek_array=zeros(si,2); % time, seek distance
i=0;
tline=fgetl(fid);
while ischar(tline)
    % we purposely omit the first one.
    i=i+1;
    [t, gap]=sscanf(tline, '%f     %d ');
    if i>si
        seek_array=[seek_array;zeros(si_inc,2)];
        si=si+si_inc;
    else
        seek_array(i,:)=t';
    end
    tline=fgetl(fid);
end

if isfield(options, 'plot_figure')
    plot_figure=options.plot_figure;
else
    plot_figure=1;
end

if isfield(options, 'plot_figure')
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
    seek_array=seek_array(2:i,:);
    rem_str='(omit first seek)';
else
    seek_array=seek_array(1:i,:);
    rem_str='(include first seek)';
end

seek_mode=mode(seek_array(:,2));
seek_mean=mean(seek_array(:,2));
seek_abs_mean=mean(abs(seek_array(:,2)));
seek_mode_freq=size(find(seek_array(:,2)==seek_mode),1);
seek_mode_ratio=seek_mode_freq/i;
seek_middle_ratio=size(find(seek_array(:,2)>1000 & seek_array(:,2)<=10000),1)/i;
seek_large_ratio=size(find(seek_array(:,2)>10000),1)/i;

Seek.seek_array=seek_array;
Seek.seek_mode=seek_mode;
Seek.seek_abs_mean=seek_abs_mean;
Seek.seek_mode_freq=seek_mode_freq;
Seek.seek_mode_ratio=seek_mode_ratio;
Seek.seek_middle_ratio=seek_middle_ratio;
Seek.seek_large_ratio=seek_large_ratio;

if plot_figure==1
    figure;
    plot(seek_array(:,1),seek_array(:,2),'*','MarkerSize',0.5);
    xlabel('time(s)')
    ylabel('seek distance (blk)')
    title({[plot_title,' ', rem_str ];[' Seek Mode=', int2str(seek_mode),' with frequency=', int2str(seek_mode_freq), ' and ratio=', num2str(seek_mode_ratio,3)];['Mean=', num2str(seek_mean), '; Abs Mean=', int2str(seek_abs_mean), '; 1000<SD<=10000 ratio=', num2str(seek_middle_ratio), '; SD>10000 ratio=', num2str(seek_large_ratio) ]});
end