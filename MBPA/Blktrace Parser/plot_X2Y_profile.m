% process and plot seek data from btt result
% share the process for Q2C, D2C and Q2D
function X2Y=plot_X2Y_profile(filename,options)

fid=fopen(filename);

if fid<0
    disp('error to open the file');
    return
end

si=20000;
si_inc=5000;
X2Y_array=zeros(si,2); % arrival time, duration
i=0;
tline=fgetl(fid);
while ischar(tline)
    % we purposely omit the first one.
    i=i+1;
    [t, gap]=sscanf(tline, '%f     %d ');
    if i>si
        X2Y_array=[X2Y_array;zeros(si_inc,2)];
        si=si+si_inc;
    else
        X2Y_array(i,:)=(t([1,3]))';
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

if isfield(options, 'time_range')
idx1=find(X2Y_array(:,1)>options.time_range(1),1,'first');
idx2=find(X2Y_array(:,1)<options.time_range(2),1,'last');
X2Y_array=X2Y_array(idx1:idx2,:);
end

X2Y_mean=mean(X2Y_array(:,2));
X2Y_std=std(X2Y_array(:,2));
X2Y_less_mean_ratio=size(find(X2Y_array(:,2)<X2Y_mean),1)/i;

X2Y.X2Y_array=X2Y_array;

X2Y.X2Y_mean=X2Y_mean;
X2Y.X2Y_std=X2Y_std;
X2Y.X2Y_less_mean_ratio=X2Y_less_mean_ratio;

if plot_figure==1
    figure;
    plot(X2Y_array(:,1),X2Y_array(:,2),'*','MarkerSize',0.5);
    xlabel('time(s)')
    ylabel('reponse time(s)')
    title({[plot_title ];[' mean=', num2str(X2Y_mean),' std=', num2str(X2Y_std), '<mean ratio=', num2str(X2Y_less_mean_ratio) ]});
end
