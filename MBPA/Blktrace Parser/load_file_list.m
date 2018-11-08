function data=load_file_list(dirName,extName)

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
data=ls([pwd,'\*.' extName]);
path=dirName;

figure_path=[path 'figures\'];
mkdir(figure_path);

for i=1:size(data,1)
    copyfile(data(i,:),[figure_path,data(i,:)]);
end

