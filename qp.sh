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

LAT=$(whiptail --inputbox "Latitude ?" 8 48 "45" --title "Latitude" 3>&1 1>&2 2>&3)
exitstatus=$?
myexitstatus

LON=$(whiptail --inputbox "Longitude ?" 8 48 "5" --title "Longitude" 3>&1 1>&2 2>&3)
exitstatus=$?
myexitstatus

RAYON=$(whiptail --inputbox "Rayon (deg) ?" 8 48 "0.2" --title "Rayon" 3>&1 1>&2 2>&3)
exitstatus=$?
myexitstatus

WS=$(whiptail --title "FDSN Webservice" --radiolist "Ex: RESIF, RASP" 20 78 4 "RESIF" "1" ON "RASP" "1" OFF "INGV" "1" OFF "IRIS" "1" OFF "GEOFON" "1" OFF 3>&1 1>&2 2>&3)
exitstatus=$?
myexitstatus

CHANLIST="HHZ,BHZ,HNZ"
if [ $WS = "RESIF" ] ; then URL_ROOT="https://ws.resif.fr"; fi
if [ $WS = "RASP" ] ; then URL_ROOT="https://fdsnws.raspberryshakedata.com"; CHANLIST="SHZ" ; fi
if [ $WS = "INGV" ] ; then URL_ROOT="https://webservices.ingv.it" ; fi
if [ $WS = "IRIS" ] ; then URL_ROOT="https://services.iris.edu"; fi
if [ $WS = "GEOFON" ] ; then URL_ROOT="http://geofon.gfz-potsdam.de" ; fi

STAFILE=./selected.stations
#wget "https://service.iris.edu/fdsnws/station/1/query?latitude=7.1&longitude=-5.0&maxradius=2&level=channel&format=text&channel=HHZ,BHZ&nodata=404"
URL="$URL_ROOT/fdsnws/station/1/query?latitude=$LAT&longitude=$LON&maxradius=$RAYON&level=channel&format=text&channel=$CHANLIST&endafter=2020-04-16T17:59:07&nodata=404"

if [ $WS = "RESIF" ] ; then URL=$URL"&net=FR,RA" ; fi

echo $URL
curl -k $URL -o $STAFILE

vi $STAFILE

ok=0
if [ -s $cachefile ] ; then
	if [ $(grep -c "^MINTIME=" $cachefile) -eq 1 ] ; then
		ok=1
		CURDATE=$(grep "^MINTIME=" $cachefile | awk -F"=" '{print $2}')
	fi
fi

if [ $ok -eq 0 ] ; then
	CURDATE=$(date -u -d '-60minutes' +'%Y-%m-%dT%H:%M:00')
	##CURDATE="2019-07-03T14:44:00"
fi
echo $CURDATE

MINTIME=$(whiptail --inputbox "Ex: 2020-01-30T12:28:00" 8 48 $CURDATE --title "Begin time (UTC)" 3>&1 1>&2 2>&3)
exitstatus=$?
myexitstatus

LENGTH=$(whiptail --inputbox "Durée (en minutes) ?" 8 48 "5" --title "Length" 3>&1 1>&2 2>&3)
exitstatus=$?
myexitstatus

:> $cachefile
cat << EOF >> $cachefile
URL_ROOT=$URL_ROOT
NET=$NET
STA=$STA
CHAN=$CHAN
LOCCODE=$LOCCODE
MINTIME=$MINTIME
LENGTH=$LENGTH
EOF


DATEFIN=$(echo $MINTIME $LENGTH | sed 's/T/ /' | awk '{print $1,$2,"+0000 +"$3"minutes"}')
MAXTIME=$(date -u -d "$DATEFIN" +'%Y-%m-%dT%H:%M:00')
exitstatus=$?
myexitstatus

datedir=$(mktemp -d)

nbsta=$(wc -l $STAFILE | awk '{print $1}')
i=2
while ( [ $i -le $nbsta ] ) ; do
	tail -n +$i $STAFILE | head -1 > ./staline
	cat ./staline

	NET=$(cat ./staline | awk -F"|" '{print $1}')
	STA=$(cat ./staline | awk -F"|" '{print $2}')
	LOCCODE=$(cat ./staline | awk -F"|" '{print $3}')
	CHAN=$(cat ./staline | awk -F"|" '{print $4}')

	i=$(expr $i + 1)

	URL="$URL_ROOT/fdsnws/dataselect/1/query?network=$NET&station=$STA&location=$LOCCODE&channel=$CHAN&quality=B&starttime=$MINTIME&endtime=$MAXTIME&nodata=404"
	echo $URL

	curl -k $URL -o $datedir/$NET.$STA.$CHAN.$LOCCODE.mseed

done

#snuffler --stations=./stations.txt $datedir/*.mseed
ls -l $datedir/*.mseed
snuffler $datedir/*.mseed

