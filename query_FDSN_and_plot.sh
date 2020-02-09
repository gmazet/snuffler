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

#WS=$(whiptail --inputbox "Ex: RESIF, RASP, INGV" 0 48 "INGV" --title "FDSN Webservice" 3>&1 1>&2 2>&3)
#exitstatus=$?
#myexitstatus

WS=$(whiptail --title "FDSN Webservice" --radiolist "Ex: RESIF, RASP" 20 78 4 "RESIF" "1" ON "RASP" "1" OFF "INGV" "1" OFF 3>&1 1>&2 2>&3)
exitstatus=$?
myexitstatus

if [ $WS = "RESIF" ] ; then
	URL_ROOT="ws.resif.fr"
	DEFAULTNET="FR"
	DEFAULTSTA="SMPL,CORF"
	DEFAULTCHAN="HHZ"
	DEFAULTLOCCODE="00"
else
	if [ $WS = "RASP" ] ; then
		URL_ROOT="fdsnws.raspberryshakedata.com"
		DEFAULTNET="AM"
		DEFAULTSTA="R9F1B,RDF31"
		DEFAULTCHAN="SHZ"
		DEFAULTLOCCODE="00"
	else
		if [ $WS = "INGV" ] ; then
			URL_ROOT="webservices.ingv.it"
			DEFAULTNET="MN,IV"
			#DEFAULTSTA="AIO,ATN,EPIT,GMB,IACL,IFIL,ILLI,IST3,ISTR,IVGP,IVPL,IVUG,JOPP,MCPD,MCSR,ME12,ME15,MILZ,MMME,MPNC,MRCB,MSCL,MSFR,MSRU,MTTG,MUCR,NOV,STR4"
			DEFAULTSTA="MPNC,IST3,ISTR,ILLI,IVUG,IVGP,IVPL,MILZ,IFIL,JOPP,MSRU,CAR1,CEL,USI"
			DEFAULTSTA="IST3,ISTR,ILLI,IVUG,IVPL,MILZ,IFIL,MSRU,MPNC,MUCR,NOV,AIO,MSFR"
			DEFAULTSTA="EMSG,EPIT,GMB,GIB,CSLB"
			DEFAULTSTA="MPG,SOLUN,USI,CET2,BULG"
			DEFAULTSTA="ILLI,IVUG,IVPG,IVPL,MILZ,MSRU,CEL"
			DEFAULTSTA="VSL,CGL,DGI,CENA"
			DEFAULTSTA="CRTO,OVO,VBKN,VRCE,VTIR,VVDG"
			DEFAULTCHAN="HHZ"
			DEFAULTLOCCODE=""
		else
			exit
		fi
	fi
fi


NET=$(whiptail --inputbox "Ex: AM, FR,R* " 0 48 $DEFAULTNET --title "Network code" 3>&1 1>&2 2>&3)
exitstatus=$?
myexitstatus

STA=$(whiptail --inputbox "Ex: CH?F,A*" 8 48 $DEFAULTSTA --title "Station code" 3>&1 1>&2 2>&3)
exitstatus=$?
myexitstatus

CHAN=$(whiptail --inputbox "Ex: HHZ,BH?" 8 48 $DEFAULTCHAN --title "Channel" 3>&1 1>&2 2>&3)
exitstatus=$?
myexitstatus

LOCCODE=$(whiptail --inputbox "Ex: 00, 0*, ?  ou vide" 8 48 $DEFAULTLOCCODE --title "Location code" 3>&1 1>&2 2>&3)
exitstatus=$?
myexitstatus

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

LENGTH=$(whiptail --inputbox "Durée (en minutes) ?" 8 48 "10" --title "Length" 3>&1 1>&2 2>&3)
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


URL="https://$URL_ROOT/fdsnws/dataselect/1/query?network=$NET&station=$STA&location=$LOCCODE&channel=$CHAN&quality=B&starttime=$MINTIME&endtime=$MAXTIME&nodata=404"
echo $URL

echo "URL: "$URL > req.result
REQ=$(whiptail --yesno "Lancer la requête ? $URL" 0 0 --title "URL" 3>&1 1>&2 2>&3)
exitstatus=$?
myexitstatus
##whiptail --textbox ./req.result 12 80

curl -k $URL -o ./snuffler_data/$MINTIME.mseed

snuffler --stations=./stations.txt ./snuffler_data/$MINTIME.mseed

exit
###



python << EOF 
from obspy import read
file="./$STA.mseed"
st = read(file)
st.filter("bandpass", freqmin=$FREQMIN, freqmax=$FREQMAX)
st.plot()
EOF

exit
dt = st[0].stats.starttime
st.plot( color='red', number_of_ticks=7,
                   tick_rotation=5, tick_format='%I:%M %p',
                   starttime=dt + 60*60, endtime=dt + 60*60 + 120)

