clear;clc;close all;delete('test.ppt');
a=figure('Visible','off');plot(1:10);
b=figure('Visible','off');plot([1:10].^2);
c=figure('Visible','off');plot([1:10].^3);
d=figure('Visible','off');plot([1:10].^4);
saveppt2('test.ppt','figure',[a b c d],'columns',2,'scale',true,'stretch',true);