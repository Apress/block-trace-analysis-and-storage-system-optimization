function strout=string_generate(data,n)
% strout=string_generate(data,n)
% generate a string for a axb matrix
%
% input:
%   data: a samples x b features
%   n: only select samples evenly from total a samples
%
% output:
%    strout: the output string
%
% Author: jun.xu99@gmail.com

if isempty(data)
    strout='EMPTY';
    return;
end

% data should be in the format of a samples x b features
[a,b]=size(data);
if a<n
    n=a;
end
% evenly select n samples from the data
interval=1/n;
samples=zeros(n+1,b);
po=0;
for i=1:n+1
    idx=ceil((i-1)*interval*a);
    if idx==0
        idx=1;
    end
    samples(i,:)=data(idx,:);
end

strout=[];

for j=1:b
    for i=1:n+1
        strout=[strout, num2str(samples(i,j)),' '];
    end
    strout=[strout,char(10)];
end
