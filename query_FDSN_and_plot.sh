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
#exit

#WS=$(whiptail --inputbox "Ex: RESIF, RASP, INGV" 0 48 "INGV" --title "FDSN Webservice" 3>&1 1>&2 2>&3)
#exitstatus=$?
#myexitstatus

WS=$(whiptail --title "FDSN Webservice" --radiolist "Ex: RESIF, RASP" 30 78 6 "RESIF" "1" ON "RASP" "1" OFF "INGV" "1" OFF "IRIS" "1" OFF "GEOFON" "1" OFF "LDG" "1" OFF 3>&1 1>&2 2>&3)
exitstatus=$?
myexitstatus

if [ $WS = "RESIF" ] ; then
	URL_ROOT="https://ws.resif.fr"
	DEFAULTNET="FR"
	DEFAULTSTA="SMPL,CORF"
	DEFAULTCHAN="HHZ"
	DEFAULTLOCCODE="00"
else
	if [ $WS = "RASP" ] ; then
		URL_ROOT="https://fdsnws.raspberryshakedata.com"
		DEFAULTNET="AM"
		DEFAULTSTA="R9F1B,RAC94,R8F32"
		DEFAULTCHAN="SHZ"
		DEFAULTLOCCODE="00"
	else
		if [ $WS = "INGV" ] ; then
			URL_ROOT="https://webservices.ingv.it"
			DEFAULTNET="MN,IV"
			#DEFAULTSTA="AIO,ATN,EPIT,GMB,IACL,IFIL,ILLI,IST3,ISTR,IVGP,IVPL,IVUG,JOPP,MCPD,MCSR,ME12,ME15,MILZ,MMME,MPNC,MRCB,MSCL,MSFR,MSRU,MTTG,MUCR,NOV,STR4"
			DEFAULTSTA="MPNC,IST3,ISTR,ILLI,IVUG,IVGP,IVPL,MILZ,IFIL,JOPP,MSRU,CAR1,CEL,USI"
			DEFAULTSTA="IST3,ISTR,ILLI,IVUG,IVPL,MILZ,IFIL,MSRU,MPNC,MUCR,NOV,AIO,MSFR"
			DEFAULTSTA="EMSG,EPIT,GMB,GIB,CSLB"
			DEFAULTSTA="MPG,SOLUN,USI,CET2,BULG"
			DEFAULTSTA="VSL,CGL,DGI,CENA"
			DEFAULTSTA="CRTO,OVO,VBKN,VRCE,VTIR,VVDG"
			DEFAULTSTA="IFIL,USI,MILZ,MSRU,ISTR,ME12"
			DEFAULTCHAN="HHZ"
			DEFAULTLOCCODE=""
		else
			if [ $WS = "IRIS" ] ; then
				URL_ROOT="https://services.iris.edu"
				DEFAULTNET="GT"
				DEFAULTSTA="DBIC"
				DEFAULTCHAN="BHZ,HHZ"
				DEFAULTLOCCODE="00"
			else
				if [ $WS = "GEOFON" ] ; then
					URL_ROOT="http://geofon.gfz-potsdam.de"
					DEFAULTNET="GE"
					DEFAULTSTA="ACRG"
					DEFAULTCHAN="BHZ"
					DEFAULTLOCCODE=""
				else
					if [ $WS = "LDG" ] ; then
						URL_ROOT="http://vq-jallouvre:8080"
						DEFAULTNET="RD"
						DEFAULTSTA="BGF"
						DEFAULTCHAN="SHZ"
						DEFAULTLOCCODE=""
					else
						exit
					fi
				fi
			fi
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

# ---------------------------------
# Query xml response files
# ---------------------------------
for s in $(echo $STA | sed 's/,/ /g') ; do
	echo $s
	if [ ! -s ./xml/$s.xml ] ; then
		curl -k "$URL_ROOT/fdsnws/station/1/query?network=$NET&station=$s&channel=HHZ&format=xml&level=response&nodata=404" -o ./xml/$s.xml
		ls -l ./xml/$s.xml
	fi
done


# ---------------------------------
# Query data
# ---------------------------------
URL="$URL_ROOT/fdsnws/dataselect/1/query?network=$NET&station=$STA&location=$LOCCODE&channel=$CHAN&quality=B&starttime=$MINTIME&endtime=$MAXTIME&nodata=404"
echo $URL

#echo "URL: "$URL > /tmp/req.result
REQ=$(whiptail --yesno "Lancer la requête ? $URL" 0 0 --title "URL" 3>&1 1>&2 2>&3)
exitstatus=$?
myexitstatus

MINTIME=$(echo $MINTIME | sed 's/://g')
curl -k $URL -o ./snuffler_data/$MINTIME.mseed
snuffler --stations=./stations.txt ./snuffler_data/$MINTIME.mseed

