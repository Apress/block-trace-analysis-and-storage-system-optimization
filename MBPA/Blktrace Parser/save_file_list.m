function data=save_file_list(dirS,dirD, extName)
% copy the files with extName from dirS to dirD

% % dirName = 'C:\path\to\folder';              %# folder path
% % extName = '*.xyz'
% files = dir( fullfile(dirName, extName));   %# list all *.xyz files
% files = {files.name}';                      %'# file names
% 
% data = cell(numel(files),1);                %# store file contents
% % for i=1:numel(files)
% %     fname = fullfile(dirName,files{i});     %# full path to file
% %     data{i} = myLoadFunction(fname);        %# load file
% % end

% dirName=path; extName='fig';
data=ls([dirS,'\*.' extName]);

% figure_path=[path 'figures\'];
% mkdir(figure_path);
% 
% for i=1:size(data,1)
%     copyfile(data(i,:),[figure_path,data(i,:)]);
% end

for i=1:size(data,1)
    copyfile(data(i,:),[dirD,data(i,:)]);
end