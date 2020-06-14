from obspy import read, read_inventory
import matplotlib.pyplot as plt
import matplotlib.dates as dates
from datetime import datetime, timedelta
from obspy.imaging.spectrogram import spectrogram
import matplotlib.dates as mdates
from sys import exit,argv

try:
    mseedfile=argv[1]
    station=argv[2]
    duration=int(argv[3])
    fmin=float(argv[4])
    fmax=float(argv[5])
except:
    mseedfile="./snuffler_data/OLIV.mseed"
    station="OLIV"
    duration=600
    fmin=1.0
    fmax=40.0

clip=[0.0,0.4]

st = read(mseedfile)

st.merge(method=1,fill_value='interpolate')
inv = read_inventory("./xml/%s.xml" % station)
pre_filt = [0.01, 0.05, 45, 50]

i=0
nbsta=len(st)
while (i<nbsta):

    tr = st[i]
    station=tr.stats.station
    #tr.remove_response(inventory=inv, pre_filt=pre_filt, output="DISP", water_level=60, plot=False)

    tr.detrend()
    ###tr.decimate(factor=2, strict_length=False)
    tr.filter('bandpass', freqmin=fmin, freqmax=fmax)

    sample_rate=tr.stats.sampling_rate
    Xtime_min=tr.stats.starttime
    Xtime_max=tr.stats.endtime
    tr.trim(Xtime_min, Xtime_min + timedelta(milliseconds=duration*1000))
    print tr.stats
    te = tr.stats.starttime.timestamp
    te2 = tr.stats.endtime.timestamp
    x_lims = list(map(datetime.utcfromtimestamp, [te, te2]))
    x_lims = mdates.date2num(x_lims)
    y_lims = [0,100]

    fig, (ax0, ax1) = plt.subplots(nrows=2)
    fig.set_size_inches(10,8)

    #spectrogram(tr.data, tr.stats.sampling_rate, wlen=1., axes=ax0, dbscale=True,log=False, cmap='jet',title=str(tr.stats.station) +" " +str(tr.stats.starttime))
    tr.spectrogram(log=False, axes=ax0, title=station + " " + str(tr.stats.starttime), mult=8.0, wlen=5.0, per_lap=0.9, clip=clip)

    #ax0.set_ylim(0,tr.stats.sampling_rate / 2)
    fmtr = mdates.DateFormatter("%H:%M:%S")
    #ax0.xaxis_date()
    #ax0.set_xlim(x_lims[0],x_lims[1])
    #ax0.xaxis.set_major_formatter(fmtr)

    #print x_lims
    #ax0 = fig.gca()
    #print ax0
    #ax0.set_xlim(x_lims[0],x_lims[1])
    #ax0.xaxis.set_major_formatter(fmtr)
    #ax0 = plt.gca()

    #fig.canvas.draw()

    #ax0.set_xlim(0,duration*tr.stats.sampling_rate)
    #XLIM0=ax0.get_xlim()
    #print XLIM0
    #ax0.xaxis.set_major_formatter(dates.DateFormatter('%H:%M'))
    #ax0.xaxis.set_major_locator(dates.SecondLocator(interval=30))
    #ax0.xaxis.set_minor_locator(dates.SecondLocator(interval=10))
    #labelx=ax0.get_xticklabels()
    #plt.setp(labelx, rotation=30, fontsize=9)
    #ax0.set_xlim(0,duration)
    #ax0.set_ylim(fmin,fmax)
    #ax0.xaxis_date()

    #ax1.plot(tr,linewidth=0.5)
    ax1.plot(tr.times("matplotlib"), tr.data, "b-")
    #ax1.set_xlim(0,duration*tr.stats.sampling_rate)
    ax1.xaxis.set_major_formatter(dates.DateFormatter('%H:%M'))
    ax1.xaxis.set_major_locator(dates.SecondLocator(interval=60))
    ax1.xaxis.set_minor_locator(dates.SecondLocator(interval=30))
    #labelx=ax1.get_xticklabels()
    #plt.setp(labelx, rotation=30, fontsize=9)
    #ax1.set_xlim(0,duration)
    ax1.xaxis_date()
    fig.autofmt_xdate()

    plt.title(station)
    fig.tight_layout(pad=0.5,rect=(0,0,1,0.95))
    plt.savefig('./%s.png' % station)

    plt.show()
    
    i+=1
exit()
