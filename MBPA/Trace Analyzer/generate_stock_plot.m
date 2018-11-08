function generate_stock_plot(data,node_set,batch_set,options)
% generate_stock_plot(data,node_set,batch_set,options)
% generate stock-like figures
% input:
%   data: the data to be plot
%   node_set:
%   batch_set:
%   options:  if options.remove=1, then the min and max values are removed.
% output: None
% Author: jun.xu99@gmail.com 

csi=size(node_set,2);
csj=size(batch_set,2);

Stat_IOPS=zeros(csi,12);
for i=1:csi
    temp_data=data((i-1)*csj+1:i*csj,:);
    temp=zeros(csj-2,3);
    if options.remove==1
        for j=1:3
            [temp_idx0,temp_d0]=min(temp_data(:,j));
            [temp_idx1,temp_d1]=max(temp_data(:,j));
            temp_idx2=setdiff(1:csj,[temp_d0, temp_d1]);
            temp(:,j)=temp_data(temp_idx2,j);
        end
    end
    
    temp_data=temp;
    Stat_IOPS(i,:)=[mean(temp_data) std(temp_data) min(temp_data) max(temp_data)];
end
aS=size(Stat_IOPS,2);
% w_idx=2:3:aS;
% r_idx=3;3:aS;
for i=1:csi
    str0{i}=int2str(node_set(i));
end

if options.write==1
    figure;
    hold on;
    plot(node_set, Stat_IOPS(:,2),'r^','MarkerSize',16);
    plot(node_set, Stat_IOPS(:,5),'b+','MarkerSize',16);
    legend('average','std');
    for i=1:csi
        plot([node_set(i),node_set(i)],[Stat_IOPS(i,8), Stat_IOPS(i,11)],'y','LineWidth',4);
    end
    xlabel('Node ID')
    ylabel(options.ylabel);
    title('Write')
    y1=max(Stat_IOPS(:,11))*1.1;
    y2=min([Stat_IOPS(:,8);Stat_IOPS(:,5)])*0.9;
    axis([146,151,y2,y1]);
    
    ax = gca;
    ax.XTick=node_set;
    
    %ax.XTickLabel = str0;
    set(gca, 'XTick',node_set)
    set(gca, 'XTickLabel',str0)
    set(findall(gcf,'-property','FontSize'),'FontSize',options.fontsize);
    saveas(gcf,[options.dataname,'_',options.ylabel,'_write.fig']);
    saveas(gcf,[options.dataname,'_',options.ylabel,'_write.eps'],'psc2');
    
end

if options.read==1
    figure;
    hold on;
    plot(node_set, Stat_IOPS(:,3),'r^','MarkerSize',16);
    plot(node_set, Stat_IOPS(:,6),'b+','MarkerSize',16);
    legend('average','std');
    for i=1:csi
        plot([node_set(i),node_set(i)],[Stat_IOPS(i,9), Stat_IOPS(i,12)],'y','LineWidth',4);
    end
    xlabel('Node ID')
    ylabel(options.ylabel);
    title('Read')
    y1=max(Stat_IOPS(:,11))*1.1;
    y2=min([Stat_IOPS(:,8);Stat_IOPS(:,5)])*0.9;
    axis([146,151,y2,y1]);
    
    ax = gca;
    %ax.XTick=node_set;
    %ax.XTickLabel = str0;
    set(gca, 'XTick',node_set)
    set(gca, 'XTickLabel',str0)
    set(findall(gcf,'-property','FontSize'),'FontSize',options.fontsize)
    saveas(gcf,[options.dataname,'_',options.ylabel,'_read.fig']);
    saveas(gcf,[options.dataname,'_',options.ylabel,'_read.eps'],'psc2');
end

if options.both==1

    figure;
    subplot(2,1,1);
    hold on;
    plot(node_set, Stat_IOPS(:,3),'r^','MarkerSize',16);
    plot(node_set, Stat_IOPS(:,6),'b+','MarkerSize',16);
    %legend('average','std','Location','EastOutside');
    legend('average','std');
    for i=1:csi
        plot([node_set(i),node_set(i)],[Stat_IOPS(i,9), Stat_IOPS(i,12)],'y','LineWidth',4);
    end
    xlabel('Node ID')
    ylabel(options.ylabel);
    title('Read')
    y1=max(Stat_IOPS(:,11))*1.1;
    y2=min([Stat_IOPS(:,8);Stat_IOPS(:,5)])*0.9;
    axis([146,152,y2,y1]);
    ax = gca;
    %ax.XTick=node_set;
    %ax.XTickLabel = str0;
    set(gca, 'XTick',node_set)
    set(gca, 'XTickLabel',str0)
    set(findall(gcf,'-property','FontSize'),'FontSize',options.fontsize)
    
    subplot(2,1,2);
    
    hold on;
    plot(node_set, Stat_IOPS(:,2),'r^','MarkerSize',16);
    plot(node_set, Stat_IOPS(:,5),'b+','MarkerSize',16);
    %legend('average','std','Location','EastOutside');
    legend('average','std');
    
    for i=1:csi
        plot([node_set(i),node_set(i)],[Stat_IOPS(i,8), Stat_IOPS(i,11)],'y','LineWidth',4);
    end
    xlabel('Node ID')
    ylabel(options.ylabel);
    title('Write')
    y1=max(Stat_IOPS(:,11))*1.1;
    y2=min([Stat_IOPS(:,8);Stat_IOPS(:,5)])*0.9;
    axis([146,152,y2,y1]);
    
    ax = gca;
    %ax.XTick=node_set;
    %ax.XTickLabel = str0;
    set(gca, 'XTick',[node_set])
    set(gca, 'XTickLabel',str0)
    set(findall(gcf,'-property','FontSize'),'FontSize',options.fontsize)
    
    saveas(gcf,[options.dataname,'_',options.ylabel,'_both.fig']);
    saveas(gcf,[options.dataname,'_',options.ylabel,'_both.eps'],'psc2');
end