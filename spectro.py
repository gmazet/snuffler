from obspy import read, read_inventory
from obspy.imaging.spectrogram import spectrogram
import matplotlib.pyplot as plt
import matplotlib.dates as dates
from matplotlib.ticker import MultipleLocator, FormatStrFormatter, AutoMinorLocator
from datetime import datetime, timedelta
from sys import exit,argv

try:
    mseedfile=argv[1]
    fmin=float(argv[2])
    fmax=float(argv[3])
except:
    mseedfile="./snuffler_data/OLIV.mseed"
    fmin=1.0
    fmax=40.0

clip=[0.0,0.05]
wlen=5.0
per_lap=0.95
mult=1.0
pre_filt = [0.01, 0.05, 48, 50]

st = read(mseedfile)
st.merge(method=1,fill_value='interpolate')

i=0
nbsta=len(st)
while (i<nbsta):

    tr = st[i]

    #inv = read_inventory("./xml/%s.xml" % tr.stats.station)
    ###tr.remove_response(inventory=inv, pre_filt=pre_filt, output="DISP", water_level=60, plot=False)

    tr.detrend()
    tr.filter('bandpass', freqmin=fmin, freqmax=fmax, corners=4.0, zerophase=True)

    sample_rate=tr.stats.sampling_rate
    Xtime_min=tr.stats.starttime
    Xtime_max=tr.stats.endtime
    duration=int(tr.stats.npts/tr.stats.sampling_rate)
    tr.trim(Xtime_min, Xtime_min + timedelta(milliseconds=duration*1000))
    print tr.stats

    t1 = tr.stats.starttime.timestamp
    t2 = tr.stats.endtime.timestamp
    x_lim = list(map(datetime.utcfromtimestamp, [t1, t2]))
    x_lims = dates.date2num(x_lim)
    y_lims = [0,100]

    fig, (ax0, ax1) = plt.subplots(nrows=2)
    #fig.set_size_inches(28,12)

    spectrogram(tr.data, tr.stats.sampling_rate, wlen=wlen, per_lap=per_lap, clip=clip, mult=mult, axes=ax0, dbscale=True,log=False, cmap='jet',title=str(tr.stats.station) +" " +str(tr.stats.starttime))
    #tr.spectrogram(log=True, axes=ax0, title=tr.stats.station + " " + str(tr.stats.starttime), mult=8.0, wlen=5.0, per_lap=0.9, clip=clip)
    #custom_spectro.spectrogram(data=tr.data,samp_rate=tr.stats.sampling_rate,log=False,cmap='jet', dbscale=True, show=False,clip=clip, axes=ax0, wlen=wlen,per_lap=per_lap,decal=0)

    ax0.xaxis.set_major_locator(MultipleLocator(60))
    ax0.xaxis.set_minor_locator(MultipleLocator(30))
    ax0.set_ylim(0,tr.stats.sampling_rate / 2)
    ax0.set_xlim(0, duration)
    ax0.set_title("%s [%s - %s]" % (tr.stats.station, x_lim[0], x_lim[1]))

    ax1.plot(tr.times("matplotlib"), tr.data, "b-", linewidth=0.5)
    ax1.xaxis.set_major_formatter(dates.DateFormatter('%H:%M:%S'))
    ax1.xaxis.set_major_locator(dates.SecondLocator(interval=60))
    ax1.xaxis.set_minor_locator(dates.SecondLocator(interval=10))
    ax1.set_xlim(x_lims[0], x_lims[1])
    ax1.xaxis_date()
    labelx=ax1.get_xticklabels()
    plt.setp(labelx, rotation=30, fontsize=9)
    #fig.autofmt_xdate()

    fig.tight_layout(pad=0.5,rect=(0,0,1,0.90))
    plt.savefig('./%s.png' % tr.stats.station)

    plt.show()
    
    i+=1
