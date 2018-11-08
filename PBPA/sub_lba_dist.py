
import numpy as np

from lba_size_dist2 import lba_size_dist2
from mpl_toolkits.mplot3d import Axes3D

# if available import pylab (from matlibplot)
try:
    import matplotlib.pylab as plt
except ImportError:
    pass

def sub_lba_dist(lists_action, lists_cmd, options):

    # Local Variables: plot_fontsize, lists_action, i, idx_write, save_figure, lba_size_set, stat_record, idx_read, section_name, X, y, x, plot_figure, lba_stat_array, options, Y, lists_cmd
    # Function calls: subplot, plot, lba_size_dist, set, gcf, figure, title, zlabel, isfield, findall, mesh, sub_lba_dist, colorbar, meshgrid, xlabel, ylabel, generate_ppt, saveas, isempty, find
    #% stat_record=sub_lba_dist(lists_action,lists_cmd,options)
    #% --> calcuate the size distribution
    #% inputs
    #%   lists_action: n samples x 2 array for arrival time and completion time;
    #%   lists_cmd: n samples x 3 for LBA, size, flags ( (0 write, 1 read))
    #%   access_type: 0 write, 1 read, 2 all
    #%   options: control parameters
    #%       lba_size_set: how many LBA range sets
    #%
    #% outputs
    #%   lba_stat_array: cells structure; LBA statistics for write/read/all
    #%
    #% contact jun.xu99@gmail.com for questions
    
    
    if hasattr(options, 'plot_fontsize'):
        plot_fontsize = options.plot_fontsize
    else:
        plot_fontsize = 10
        
    
    if hasattr(options, 'save_figure'):
        save_figure = options.save_figure
    else:
        save_figure = 1
        
    
    if hasattr(options, 'plot_figure'):
        plot_figure = options.plot_figure
    else:
        plot_figure = 1
        
    
    if hasattr(options, 'lba_size_set'):
        lba_size_set=options.lba_size_set;    
    else:
        options.lba_size_set = 50
        
    plot_figure=options.plot_figure

    #%5: LBA vs time;
    if plot_figure == 1:
        idx_read = np.nonzero((lists_cmd[:,2] == 1))
        idx_write = np.nonzero((lists_cmd[:,2] == 0))
        plt.figure
        plt.subplot(2., 1., 1.)
        plt.plot(lists_action[(idx_read),0], lists_cmd[(idx_read),0], 'r*', markersize= 1)
        plt.ylabel('LBA')
        plt.title('read')
        plt.subplot(2., 1., 2.)
        plt.plot(lists_action[(idx_write),0], lists_cmd[(idx_write),0], 'b+', markersize=1)
        plt.ylabel('LBA')
        plt.xlabel('time (s)')
        plt.title('write')
        plt.savefig('lba_all.eps')
        plt.savefig('lba_all.jpg')
        
        
    lba_stat_array=[];
    for i in np.arange(3):
        
        print(i)
        stat_record = lba_size_dist2(lists_cmd, i, options)
    
        if plot_figure == 1:
            x = np.arange(1, 1025)
            y = stat_record.lba_size_idx
            if len(y)<=1:
                continue
            fig=plt.figure()
            ax=Axes3D(fig)
            [X, Y] = plt.meshgrid(x, y)
            ax.plot_surface(X, Y, (stat_record.lba_size_dist))
            plt.set_cmap('hot')
              
          
            ax.set_ylabel('LBA Range')
            ax.set_xlabel('Request size')
            ax.set_zlabel('Frequency')
            
            if i == 0.:
                ax.set_title('LBA & Size Disribution - Write ')
            elif i == 1.:
                ax.set_title('LBA & Size Disribution - Read ')
                
            else:
                ax.set_title('LBA & Size Disribution - Combined ')
                
           
            # set((plt.gcf, '-property', 'FontSize'), 'FontSize', plot_fontsize)
            # plt.grid()
            if i == 1:
                plt.savefig('lba_size_freq_read.eps', format="eps")
                plt.savefig('lba_size_freq_read.jpg')
            elif i == 0:
                plt.savefig('lba_size_freq_write.eps', format="eps")
                plt.savefig('lba_size_freq_write.jpg')
                
            else:
                plt.savefig('lba_size_freq_com.eps', format="eps")
                plt.savefig('lba_size_freq_com.jpg')
                
            plt.show()                   
            
        lba_stat_array.append(stat_record)           
   
    
#    if options.export_report:
#        options.section_name = 'LBA Distribution'
#        generate_ppt(options)
    
    
    return lba_stat_array