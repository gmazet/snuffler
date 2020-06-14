from obspy import read, read_inventory
import matplotlib.pyplot as plt
from sys import exit,argv

fmin=1.0
fmax=40.0
duration=600
clip=[0.0,0.4]
mseedfile="./snuffler_data/030719.mseed"
mseedfile="./snuffler_data/280819.mseed"
mseedfile="snuffler_data/OLIV.mseed"

st = read(mseedfile)

st.merge(method=1,fill_value='interpolate')
inv = read_inventory("./OLIV.xml")
pre_filt = [0.01, 0.05, 45, 50]

i=0
nbsta=len(st)
while (i<nbsta):

    tr = st[i]
    station=tr.stats.station
    tr.remove_response(inventory=inv, pre_filt=pre_filt, output="VEL", water_level=60, plot=False)
    if (station!='IFI'):
        tr.filter('bandpass', freqmin=fmin, freqmax=fmax)

    fig, (ax0, ax1) = plt.subplots(nrows=2)
    fig.set_size_inches(12,10)

    #plt.subplot(211)
    #ax=plt.axes()
    #print ax

    print tr.stats
    f=tr.spectrogram(log=False, axes=ax0, 
        title=station + " " + str(tr.stats.starttime), 
        mult=8.0, wlen=5.0, per_lap=0.9, clip=clip)

    ax0.set_xlim(0,duration)
    ax0.set_ylim(fmin,fmax)

    #plt.subplot(212)
    ax1.set_xlim(0,duration*tr.stats.sampling_rate)
    ax1.plot(tr,linewidth=0.5)

    plt.title(station)
    plt.savefig('./%s.png' % station)

    plt.show()
    
    i+=1
exit()
