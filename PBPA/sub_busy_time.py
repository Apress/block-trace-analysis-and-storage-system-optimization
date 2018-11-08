from numpy import zeros, nonzero, shape, arange, transpose, dot, uint8, uint16, uint32, c_,sum,squeeze
    
class time_record_class:
    def __init__(self,total_busy_time=None,device_busy_percent=None):
        self.device_busy_percent=device_busy_percent
        self.total_busy_time=total_busy_time
        
def sub_busy_time(lists_action,options):

# [total_busy_time,device_busy_percent]=sub_busy_time(lists_action,options)
# --> calculate the device busy time;
# 
# inputs
#   lists_action: n samples x 2 array for arrival time and completion time;
#   options: control parameters
# outputs
#   total_busy_time: total busy time
#   device_busy_percent: total busy time / total time
    
# Author jun.xu99@gmail.com
    
    total_busy_time=0.
    con0=shape(lists_action)[0]
    int_start_time=lists_action[1,0]    
    int_end_time=lists_action[1,1]
    # calculate the total busy time
    for i in arange(1,con0).reshape(-1):
        if int_end_time < lists_action[i,0]:
            total_busy_time=total_busy_time + int_end_time - int_start_time
            int_start_time=lists_action[i,0]
            if int_end_time < lists_action[i,1]:
                int_end_time=lists_action[i,1]
        else:
            if int_end_time<lists_action[i,1]:
                int_end_time=lists_action[i,1]
    
    # make sure the starting time is from zero; otherwise you need to adjust
# the trace or let the denominator as (lists_action(con0,2)-lists_action(1,2))
# device_busy_percent=total_busy_time/lists_action(con0,2)
    device_busy_percent=total_busy_time / (lists_action[con0-1,1] - lists_action[0,1])
    time_record=time_record_class(total_busy_time,device_busy_percent)
    
    return time_record
#    time_record.total_busy_time = copy(total_busy_time)
#    time_record.device_busy_percent = copy(device_busy_percent)
    
#    if options.export_report:
#        options.section_name = copy('Busy Time')
#        generate_ppt(options)
#        string0=matlabarray(cat('Total busy time = ',num2str(total_busy_time),' seconds ',char(10),'Total time = ',num2str(lists_action[con0,2]),' seconds ',char(10),'Busy time ratio = ',num2str(device_busy_percent)))
#        saveppt2(options.report_name,'f',0,'t',string0)
    