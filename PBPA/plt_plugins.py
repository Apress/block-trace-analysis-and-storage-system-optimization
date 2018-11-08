# -*- coding: utf-8 -*-
"""
few plotting functions

@author: junxu
"""

import matplotlib.pyplot as plt

def plotyy(x1,y1,x2,y2):
    fig, ax1 = plt.subplots()
    
    ax1.plot(x1, y1, 'b-')
    #ax1.set_xlabel('time (s)')
    ## Make the y-axis label, ticks and tick labels match the line color.
    #ax1.set_ylabel('exp', color='b')
    #ax1.tick_params('y', colors='b')
    
    ax2 = ax1.twinx()   
    #
    ax2.plot(x2, y2, 'r.')
    #ax2.set_ylabel('sin', color='r')
    #ax2.tick_params('y', colors='r')
    
    fig.tight_layout()
    # plt.show()
    
    return fig,ax1,ax2


def change_fontsize(ax,fontsize):

    for item in ([ax.title, ax.xaxis.label, ax.yaxis.label] +
                 ax.get_xticklabels() + ax.get_yticklabels()):
        item.set_fontsize(fontsize)