#!/bin/bash

SOFT=$(basename "$0")
cachefile=$HOME/.pyrocko/$SOFT.pf
if [ ! -s $cachefile ] ; then
	touch $cachefile
fi

function myexitstatus {
	if [ $exitstatus = 1 ]; then
		echo "exit"
		exit
	fi
}

#wget "https://service.iris.edu/fdsnws/station/1/query?latitude=7.1&longitude=-5.0&maxradius=2&level=channel&format=text&channel=HHZ,BHZ&nodata=404"
#curl -k 'http://ws.resif.Fr/fdsnws/station/1/query?level=channel&format=text&channel=HHZ,BHZ&nodata=404' -o geofon.sta
curl -k 'https://ws.resif.fr/fdsnws/station/1/query?network=FR&station=OLIV&channel=HHZ&level=response&format=xml&nodata=404' -o OLIV.xml
exit

