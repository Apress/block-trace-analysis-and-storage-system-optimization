% extract different event from blktrace for statistics

filename='sdb_fs';
fid=fopen(filename);
tline=fgetl(fid);

action_array=zeros(15,1); 
% 1A,2B,3C,4D,5F,6G,7I, 8M, 9P, 10Q, 11S, 12T, 13U, 14X, 15m
action_flag={'A','B','C','D','F','G','I', 'M', 'P', 'Q', 'S', 'T', 'U', 'X', 'm'};
con=0;
[pathstr,name,ext] = fileparts(filename);

while ischar(tline)
    con=con+1;
      if tline(1)=='C'
          break;
      end
      action=sscanf(tline,'%*d,%*d   %*d        %*d     %*f %*d  %c %*s' );
      if char(action)=='A'
          action_array(1)=action_array(1)+1;
      elseif char(action)=='A'
          action_array(1)=action_array(1)+1;
                elseif char(action)=='B'
          action_array(2)=action_array(2)+1;
                elseif char(action)=='C'
          action_array(3)=action_array(3)+1;
                elseif char(action)=='D'
          action_array(4)=action_array(4)+1;
                elseif char(action)=='F'
          action_array(5)=action_array(5)+1;
                elseif char(action)=='G'
          action_array(6)=action_array(6)+1;
                elseif char(action)=='I'
          action_array(7)=action_array(7)+1;
                elseif char(action)=='M'
          action_array(8)=action_array(8)+1;
                elseif char(action)=='P'
          action_array(9)=action_array(9)+1;
                elseif char(action)=='Q'
          action_array(10)=action_array(10)+1;
                elseif char(action)=='S'
          action_array(11)=action_array(11)+1;
                elseif char(action)=='T'
          action_array(12)=action_array(12)+1;
                elseif char(action)=='U'
          action_array(13)=action_array(13)+1;
                elseif char(action)=='X'
          action_array(14)=action_array(14)+1;
                elseif char(action)=='m'
          action_array(15)=action_array(15)+1;          
      end    
      tline=fgetl(fid);
      
      if mod(con,10000)==0
          disp([int2str(con), 'events are processed',])
      end
end

fclose(fid);
action_sum=sum(action_array);
action_max=max(action_array);
he0=action_max*0.02;
figure;
bar(action_array);
for i=1:15
    text(i,action_array(i)+he0,action_flag{i});
end
xlabel('Events')
ylabel('Frequency')
title([name,':total events=', int2str(action_sum)]);

figure;
action_array_per=action_array/action_sum*100;
bar(action_array_per);
action_max=max(action_array_per);
he0=action_max*0.02;
for i=1:15
    text(i,action_array_per(i)+he0,action_flag{i});
end
xlabel('Events')
ylabel('percent %')
title([name,':total events=', int2str(action_sum)]);
