#!/bin/sh

MYPATH="/share/Public/bin/covid"
OUTPATH="$MYPATH/out"
LATESTFILE="$MYPATH/COVID-19/dati-andamento-nazionale/dpc-covid19-ita-andamento-nazionale-latest.csv"
TMPREGIONIFILE="$MYPATH/COVID-19/dati-regioni/dpc-covid19-ita-regioni.csv"
REGIONILATESTFILE="$MYPATH/COVID-19/dati-regioni/dpc-covid19-ita-regioni-latest.csv"
PROVINCECSVFILE="$MYPATH/COVID-19/dati-province/dpc-covid19-ita-province-latest.csv"
PROVINCEFULLCSVFILE="$MYPATH/COVID-19/dati-province/dpc-covid19-ita-province.csv"
LATESTDONEFILE="$OUTPATH/covidLatestDone.txt"
TMPSINGOLAREGIONEFILE="$OUTPATH/$REGIONEFORMAT/covidLatest.tmp"
TMPCSVFILE="$MYPATH/COVID-19/dati-andamento-nazionale/dpc-covid19-ita-andamento-nazionale.csv"
CSVFILE="$OUTPATH/covid.csv"
CSVFILESHORT="$OUTPATH/covidshort.csv"
HTMLFILE="$OUTPATH/index.html"
HTMLFILETMP="$OUTPATH/indextmp.html"
RTHTMLFILE="$OUTPATH/rt.html"
RTCSVFILE="$OUTPATH/rtItalia.csv"
LOGFILE="$OUTPATH/covid.log"
CREDENTIALS=$(cat $MYPATH/ftpcredentials.credential)

REGIONE="RT"

if [ $# -eq 1 ] && [ "$1" != "-f" ]; then
	REGIONE="$1"
	REGIONEFORMAT=$(echo "$REGIONE" | sed "s/[^[:alnum:]]//g")
	REGIONEPATH="$OUTPATH/$REGIONEFORMAT"
	POPOLAZIONE=$(cat "$MYPATH/regioni.csv"| grep "$REGIONE" | cut -f2 -d",")
	CSVFILE="$REGIONEPATH/covid.csv"
	RTCSVFILE="$REGIONEPATH/rt.csv"
fi

echo "Data,$REGIONE" >"$RTCSVFILE"

END=30

for ((i=END;i>=1;i--)); do
	(( i2 = i + 4 ))
	DATIZERO=$(tail -$i "$CSVFILE" | head -1)
	DATIMENOQUATTRO=$(tail -$i2 "$CSVFILE" | head -1)

	#dimessi guariti
	ALPHAZERO=$(echo $DATIZERO | cut -f10 -d",") 
	ALPHAMENOQUATTRO=$(echo $DATIMENOQUATTRO | cut -f10 -d",") 
	#infetti
	BETAZERO=$(echo $DATIZERO | cut -f14 -d",") 
	BETAMENOQUATTRO=$(echo $DATIMENOQUATTRO | cut -f14 -d",") 
	#deceduti
	GAMMAZERO=$(echo $DATIZERO | cut -f11 -d",") 
	GAMMAMENOQUATTRO=$(echo $DATIMENOQUATTRO | cut -f11 -d",") 

	DATAZERO=$(echo $DATIZERO | cut -f1 -d"," | sed "s/T.*//g") 

	(( ALPHA = ALPHAZERO - ALPHAMENOQUATTRO ))
	(( BETA = BETAZERO - BETAMENOQUATTRO ))
	(( GAMMA = GAMMAZERO - GAMMAMENOQUATTRO ))
	
	(( ALPHAPIUGAMMA = ALPHA + GAMMA ))

	if [ $ALPHAPIUGAMMA = 0 ]; then
		ALPHAPIUGAMMA="0.1"
	fi
	RT=$(printf "%.2f" $(/opt/bin/bc -l <<< "$BETA / $ALPHAPIUGAMMA"))
	echo "$DATAZERO,$RT" >>"$RTCSVFILE"

#	echo "$DATAZERO - $ALPHAZERO - $BETAZERO - $GAMMAZERO - $DATIZERO"
done
