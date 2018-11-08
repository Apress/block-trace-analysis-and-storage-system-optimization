function str0=check_sequence(seek_value, seek_queue, options)
% function str0=check_sequence(seek_value, seek_queue, options)
% check the sequence/randomness based on pre-defined threshold.
% input:
%   options.seek [4]: if <[1], low; if 1~[2], relative low; if 2~[3] relatively
%   high; if >[3] high
%   seek_delta: 1: the threshold for steady state; 2/3: the treshold for mixed stream
%   options.seek_head_str: string to add at the head
%    seek_value: nXm matrix; m is usually equal to 10::: % 1 total R/W IO
%   number, 2 sequnce number, 3 mean, 4 mean abs, 5 median, 6 mode, 7 mode
%   couter, 8 min abs, 9 max abs, 10 std abs
%   seek_queue: nX1 vector, queue length
% output:
%   str0: statement string array on the sequence properity
%
% Author: jun.xu99@gmail.com

str0=[];
[a,b]=size(seek_value);
a1=size(seek_queue,2);

if a~=a1
    disp('Error in input values dimension');
    return;
end

if isfield(options, 'seek_head_str')
    seek_head_str=options.seek_head_str;
else
    seek_head_str='';
end

if isfield(options, 'seek')
    seek=options.seek;
else
    seek=[0.1,0.2,0.5,0.8];
end

if isfield(options, 'seek_delta')
    seek_delta=options.seek_delta;
else
    seek_delta=[0.01,0.1,0.2];
end


if a<2
    disp('Warning! too small size of value! extend the quene length and run again')
    return;
end

% only when mode==0, we consider the trace has seqnence
temp_str0=['QL=',int2str(seek_queue(1))];

if seek_value(1,6)==0
    mode_rati=seek_value(1,2)/seek_value(1,1);
    if mode_rati<seek(1)
        temp_str1='Very low';
    elseif mode_rati<seek(2)
        temp_str1='Low';
    elseif mode_rati<seek(3)
        temp_str1='Relatively high';
    elseif mode_rati<seek(4)
        temp_str1='High';
    elseif mode_rati<seek(4)
        temp_str1='Very high';
    else
        temp_str1='Unknown'
    end
    temp_str1=['Mode=0 with ratio= ', num2str(mode_rati)   ,' and sequence ' temp_str1, '  at ' temp_str0];
    
    % check if mixed stream in case of sequence
    % first check the steady state
    if a<3
        disp('Warning! too small size of value to check steady state! steady status will not be included')
        temp_str2=[];
    else
        steady_i=0;
        for i=1:a-1
            if seek_value(i+1)/seek_value(i)<seek_delta(1)*(seek_queue(i+1)/seek_queue(i))
                steady_i=seek_queue(i+1);
                break;
            end
        end
        if steady_i>0
            temp_str2=['Steady state possibly at QL=' int2str((steady_i))];
        else
            temp_str2=['Higher rate possibly for long length than ' int2str(seek_queue(a))];
        end
        
        for i=1:a-1
            if seek_value(i+1)/seek_value(i)>seek_delta(3)*(seek_queue(i+1)/seek_queue(i))
                temp_str3='Strong mixed streams detected';
                break;
            elseif seek_value(i+1)/seek_value(i)>seek_delta(2)*(seek_queue(i+1)/seek_queue(i))
                temp_str3='Mixed streams detected';
            else
                temp_str3='';
            end
        end
    end
    
else
    temp_str1=['Mode=', num2str(seek_value(1,6)), '  at ', temp_str0, '; Relatively random'];
    temp_str3='';
    temp_str2='';
end

str0=[temp_str1, '; ',  temp_str2, '; ', temp_str3];