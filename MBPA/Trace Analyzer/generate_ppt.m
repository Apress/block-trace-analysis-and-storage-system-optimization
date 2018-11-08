function y=generate_ppt(options)
% y=generate_ppt(options)
% Create ppt slides with all current openned figures; one figure per page
% it need the toolbox "saveppt2" from mathworks files exchange; this tool may
% not work well for higher version than 2010.
% input: 
%   options: options.report_name specifies the report name
% output:
%   y: if success, output 1; otherwise 0.
% 
% Author: jun.xu99@gmail.com 

y=0;
if options.export_report
    if ~isfield(options, 'report_name')
        options.report_name ='workload_analysis.ppt';
    end
    
    saveppt2(options.report_name,'f',0,'t',options.section_name)
    
    figHandles = findobj('Type','figure');
    for II=1:size(figHandles,1)
        saveppt2(options.report_name,'figure',figHandles(II));
        % saveppt2(report_name,'figure',[],'notes',[halign{1} ' ' valign{1}],'halign',halign,'valign',valign,'stretch',false);
        % saveppt2('test.ppt','figure',[a b c d],'columns',i,'title',['Columns ' num2str(i)])
    end
    close all
    y=1;
end