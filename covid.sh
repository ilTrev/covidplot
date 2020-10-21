#!/bin/sh

LATESTFILE=/tmp/covidLatest.csv
OLDLATESTFILE=/tmp/covidoldLatest.csv
JSONFILE=/tmp/covid.json
OLDJSONFILE=/tmp/covidold.json
TMPCSVFILE=/tmp/covidtmp.csv
CSVFILE=/tmp/covid.csv
HTMLFILE=/tmp/index.html
HTMLFILETMP=/tmp/indextmp.html
MYPATH="/share/Public/bin/covid"
LOGFILE=$MYPATH/covid.log
CREDENTIALS=$(cat $MYPATH/ftpcredentials.credential)
TELEGRAM_BOT_TOKEN=$(cat $MYPATH/telegramtoken.credential)
FORCED=""
REGIONE=""

if [ "$1" = "-f" ]; then
	FORCED="(forced)"
else
	if [ $# -eq 1 ]; then
		REGIONE="$1"
		FORCED="($REGIONE)"

		REGIONEFORMAT=$(echo "$REGIONE" | sed "s/[^[:alnum:]]//g")

		HTMLFILE="/tmp/$REGIONEFORMAT/index.html"
		TMPREGIONIFILE="/tmp/$REGIONEFORMAT/covidLatest.tmp"

		echo "$REGIONE"

		if [ ! -d "/tmp/$REGIONEFORMAT" ]; then 
			mkdir /tmp/"$REGIONEFORMAT"
		fi
	fi
fi

IMGFILE="/tmp/covid$REGIONEFORMAT.svg"

echo "Start: $(date) $FORCED" >>"$LOGFILE"

mv "$LATESTFILE" "$OLDLATESTFILE"

curl https://raw.githubusercontent.com/pcm-dpc/COVID-19/master/dati-andamento-nazionale/dpc-covid19-ita-andamento-nazionale-latest.csv >"$LATESTFILE" 2>/dev/null

diff "$LATESTFILE" "$OLDLATESTFILE"
if [ $? -eq 0 ] && [ -z "$FORCED" ]; then
	DATAOGGI=$(date +"%d-%m-%Y - %H:%M")
	cat "$HTMLFILE" | sed "s/<!-- data -->.*/<!-- data --> $DATAOGGI/g" >>"$HTMLFILETMP"
	mv "$HTMLFILETMP" "$HTMLFILE"
	curl -T "$HTMLFILE" -u "$CREDENTIALS" "ftp://iltrev.it/" 2>/dev/null
	echo "End (noop): $(date)" >>"$LOGFILE"
	exit
fi

if [ ! -z "$REGIONE" ]; then
	curl https://raw.githubusercontent.com/pcm-dpc/COVID-19/master/dati-regioni/dpc-covid19-ita-regioni.csv >"$TMPREGIONIFILE" 2>/dev/null
	head -1 "$TMPREGIONIFILE" | cut -f1,2,7- -d"," >"$TMPCSVFILE"
	cat "$TMPREGIONIFILE" | grep ",$REGIONE," | cut -f1,2,7- -d"," >>"$TMPCSVFILE"
else
	curl https://raw.githubusercontent.com/pcm-dpc/COVID-19/master/dati-andamento-nazionale/dpc-covid19-ita-andamento-nazionale.csv >"$TMPCSVFILE" 2>/dev/null
fi

export TAMPONITOTALIIERI=0
export DECESSITOTALIIERI=0
export COUNT=0
export RECORDTAMPONI=0
export RECORDCASI=0
export RECORDDECESSI=0

cat "$TMPCSVFILE" | while read LINE; do
	if [ $COUNT -eq 0 ]; then
		echo "$LINE,\"positivi/tamponi\",\"tamponi giorno\",\"deceduti giorno\",\"record tamponi\",\"record casi\",\"record decessi\"" | sed "s/_/ /g" >"$CSVFILE"
		((COUNT+=1))
		continue
	fi

	CASIIERI=$CASI
	CASI=$(echo "$LINE" | cut -f9 -d",")
	TAMPONITOTALI=$(echo "$LINE" | cut -f15 -d",")
	TAMPONIIERI=$TAMPONIOGGI
	TAMPONIOGGI=$(echo "$TAMPONITOTALI $TAMPONITOTALIIERI - p" | dc)
	
	if [ "$TAMPONIOGGI" -le "0" ] ; then
		TAMPONIOGGI=0
		RAPPORTO=0
	else
		RAPPORTO=$(echo "$CASI $TAMPONIOGGI / p" | dc)
	fi

	echo "$RAPPORTO" | cut -f1 -d"." | grep "-" >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		RAPPORTO=0
	fi

	TAMPONITOTALIIERI=$TAMPONITOTALI

	DECESSITOTALI=$(echo "$LINE" | cut -f11 -d",")
	DECESSIOGGI=$(echo "$DECESSITOTALI $DECESSITOTALIIERI - p" | dc)

	if [ $CASI -gt $RECORDCASI ]; then
		RECORDCASI=$CASI
	fi

	if [ $TAMPONIOGGI -gt $RECORDTAMPONI ]; then
		RECORDTAMPONI=$TAMPONIOGGI
	fi

	if [ $DECESSIOGGI -gt $RECORDDECESSI ]; then
		RECORDDECESSI=$DECESSIOGGI
	fi

	echo "$LINE,$RAPPORTO,$TAMPONIOGGI,$DECESSIOGGI,$RECORDTAMPONI,$RECORDCASI,$RECORDDECESSI" >>"$CSVFILE"

	DECESSITOTALIIERI=$DECESSITOTALI

done

DATIALTROIERI=$(tail -3 "$CSVFILE" | head -1)
DATIIERI=$(tail -2 "$CSVFILE" | head -1)
DATIOGGI=$(tail -1 "$CSVFILE")

RICOVERATIIERI=$(echo $DATIIERI | cut -f3 -d",")
RICOVERATI=$(echo $DATIOGGI | cut -f3 -d",")

TERAPIEINTENSIVEIERI=$(echo $DATIIERI | cut -f4 -d",")
TERAPIEINTENSIVE=$(echo $DATIOGGI | cut -f4 -d",")

DECESSITOTALIALTROIERI=$(echo $DATIALTROIERI | cut -f11 -d",")
DECESSITOTALIIERI=$(echo $DATIIERI | cut -f11 -d",")
DECESSITOTALI=$(echo $DATIOGGI | cut -f11 -d",")
DECESSIIERI=$(echo $DATIIERI | cut -f20 -d",")
DECESSIOGGI=$(echo $DATIOGGI | cut -f20 -d",")

TAMPONITOTALIALTROIERI=$(echo $DATIALTROIERI | cut -f15 -d",")
TAMPONITOTALIIERI=$(echo $DATIIERI | cut -f15 -d",")
TAMPONITOTALI=$(echo $DATIOGGI | cut -f15 -d",")
TAMPONIIERI=$(echo "$TAMPONITOTALIIERI $TAMPONITOTALIALTROIERI - p" | dc)
TAMPONIOGGI=$(echo "$TAMPONITOTALI $TAMPONITOTALIIERI - p" | dc)

CASIIERI=$(echo $DATIIERI | cut -f9 -d",")
CASIOGGI=$(echo $DATIOGGI | cut -f9 -d",")

RAPPORTOCASITAMPONIIERI=$(printf "%.2f" $(echo "$CASIIERI $TAMPONIIERI / 100 * p" | dc))
RAPPORTOCASITAMPONIOGGI=$(printf "%.2f" $(echo "$CASIOGGI $TAMPONIOGGI / 100 * p" | dc))

DATAULTIMOTMP=$(echo $DATIOGGI | cut -f1 -d"," | sed "s/T/ /g" | sed "s/\"//g")
DATAULTIMO=$(date -d"$DATAULTIMOTMP" +"%d-%m-%Y - %H:%M:%S")

RECORDTAMPONI=$(echo $DATIOGGI | cut -f21 -d",")
RECORDCASI=$(echo $DATIOGGI | cut -f22 -d",")
RECORDDECESSI=$(echo $DATIOGGI | cut -f23 -d",")

gnuplot /share/Public/bin/covid/covid.gnuplot  >"$IMGFILE"
curl -T "$IMGFILE" -u "$CREDENTIALS" "ftp://iltrev.it/" 2>/dev/null

if [ ! -z "$REGIONE" ]; then
	REGIONEWEB="$REGIONE"
else
	REGIONEWEB="Italia"
fi

cat <<EOF >"$HTMLFILE"
<html>
<head>
<!-- Global site tag (gtag.js) - Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=UA-180932911-1"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', 'UA-180932911-1');
</script>

<link href='https://fonts.googleapis.com/css?family=Roboto Mono' rel='stylesheet'>
<style>
#responsive-image { width: 100%;  height: auto;}
body { font-family: 'Roboto Mono';font-size: 18px; }
pre { font-family: 'Roboto Mono';font-size: 18px; }
</style>
EOF

echo "<title>Covid-19 $REGIONEWEB</title>" >>"$HTMLFILE"

cat <<EOF >>"$HTMLFILE"
<link rel="shortcut icon" type="image/png" href="https://www.iltrev.it/covid/favicon.png"/>
</head>
<body>
EOF

echo "<h3><center>Situazione COVID-19 - $REGIONEWEB<br>" >>"$HTMLFILE"
echo "<!-- data -->" $(date +"%d-%m-%Y - %H:%M") >>"$HTMLFILE"
echo "<br><i>(dati del $DATAULTIMO)</i></center></h3>" >>"$HTMLFILE"
echo "<br><pre>Nuovi tamponi: <b>$TAMPONIOGGI</b> (precedente: $TAMPONIIERI)" >>$HTMLFILE
echo "          Max: $RECORDTAMPONI" >>"$HTMLFILE"
echo "   Nuovi casi: <b>$CASIOGGI $RAPPORTOCASITAMPONIOGGI%</b> (precedente: $CASIIERI $RAPPORTOCASITAMPONIIERI%)" >>$HTMLFILE
echo "          Max: $RECORDCASI" >>"$HTMLFILE"
echo "Nuovi decessi: <b>$DECESSIOGGI</b> (precedente: $DECESSIIERI)" >>$HTMLFILE
echo "          Max: $RECORDDECESSI" >>"$HTMLFILE"
echo "   Ricoverati: <b>$RICOVERATI</b> (precedente: $RICOVERATIIERI)" >>"$HTMLFILE"
echo " Terapie int.: <b>$TERAPIEINTENSIVE</b> (precedente: $TERAPIEINTENSIVEIERI)</pre>" >>"$HTMLFILE"
echo "<p><img src="https://www.iltrev.it/covid/covid$REGIONEFORMAT.svg" id="responsive-image" /></p>" >>"$HTMLFILE"

cat <<EOF >> $HTMLFILE
Elaborazione dati forniti dal Dipartimento della Protezione Civile (fonte: <a href="https://github.com/pcm-dpc/COVID-19">https://github.com/pcm-dpc/COVID-19</a>)
</body>
</html> 
EOF

WEBPATH="ftp://iltrev.it/"

if [ ! -z "$REGIONE" ]; then
	WEBPATH="$WEBPATH$REGIONEFORMAT/"
fi

curl -T $HTMLFILE -u $CREDENTIALS $WEBPATH  2>/dev/null

if [ -z "$REGIONE" ]; then
	$MYPATH/covid.sh "Abruzzo"
	$MYPATH/covid.sh "Basilicata"
	$MYPATH/covid.sh "Calabria"
	$MYPATH/covid.sh "Campania"
	$MYPATH/covid.sh "Emilia-Romagna"
	$MYPATH/covid.sh "Friuli Venezia Giulia"
	$MYPATH/covid.sh "Lazio"
	$MYPATH/covid.sh "Liguria"
	$MYPATH/covid.sh "Lombardia"
	$MYPATH/covid.sh "Marche"
	$MYPATH/covid.sh "Molise"
	$MYPATH/covid.sh "P.A. Bolzano"
	$MYPATH/covid.sh "P.A. Trento"
	$MYPATH/covid.sh "Piemonte"
	$MYPATH/covid.sh "Puglia"
	$MYPATH/covid.sh "Sardegna"
	$MYPATH/covid.sh "Sicilia"
	$MYPATH/covid.sh "Toscana"
	$MYPATH/covid.sh "Umbria"
	$MYPATH/covid.sh "Valle d'Aosta"
	$MYPATH/covid.sh "Veneto"
fi

if [ -z "$FORCED" ]; then
	echo "Telegram"
	curl -X POST -H 'Content-Type: application/json' -d "{ \"chat_id\": \"@instantcovid\", \"text\": \"Aggiornamento COVID-19\nNuovi Casi: $CASIOGGI ($RAPPORTOCASITAMPONIOGGI%)\nTamponi: $TAMPONIOGGI\nDecessi: $DECESSIOGGI\nRicoverati: $RICOVERATI ($TERAPIEINTENSIVE t.i.)\n\nMaggiori informazioni:\nhttps://www.iltrev.it/covid\" }" https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage
fi

echo "End..: $(date)" >>"$LOGFILE"
