#!/bin/sh

MYPATH="/share/Public/bin/covid"
OUTPATH="$MYPATH/out"
LATESTFILE="$OUTPATH/covidLatest.csv"
TMPREGIONIFILE="$OUTPATH/covidLatestRegioni.csv"
LATESTDONEFILE="$OUTPATH/covidLatestDone.txt"
TMPSINGOLAREGIONEFILE="$OUTPATH/$REGIONEFORMAT/covidLatest.tmp"
TMPCSVFILE="$OUTPATH/covidtmp.csv"
CSVFILE="$OUTPATH/covid.csv"
PROVINCECSVFILE="$OUTPATH/covidProvince.csv"
HTMLFILE="$OUTPATH/index.html"
HTMLFILETMP="$OUTPATH/indextmp.html"
LOGFILE="$OUTPATH/covid.log"
CREDENTIALS=$(cat $MYPATH/ftpcredentials.credential)
TELEGRAM_BOT_TOKEN=$(cat $MYPATH/telegramtoken.credential)
FORCED=""
REGIONE=""
REGIONI=( \
	"Abruzzo" \
	"Basilicata" \
	"Calabria" \
	"Campania" \
	"Emilia-Romagna" \
	"Friuli Venezia Giulia" \
	"Lazio" \
	"Liguria" \
	"Lombardia" \
	"Marche" \
	"Molise" \
	"P.A. Bolzano" \
	"P.A. Trento" \
	"Piemonte" \
	"Puglia" \
	"Sardegna" \
	"Sicilia" \
	"Toscana" \
	"Umbria" \
	"Valle d'Aosta" \
	"Veneto" \
)

if [ $(cat "$LOGFILE" | wc -l) -gt 1000 ]; then 
	tail -1000 "$LOGFILE" >/tmp/covid.log
	mv /tmp/covid.log "$LOGFILE"
fi

if [ "$1" = "-f" ]; then
	FORCED="(forced)"
else
	if [ $# -eq 1 ]; then
		REGIONE="$1"
		FORCED="($REGIONE)"

		REGIONEFORMAT=$(echo "$REGIONE" | sed "s/[^[:alnum:]]//g")

		HTMLFILE="$OUTPATH/$REGIONEFORMAT/index.html"
		INDENT=" - "
		POPOLAZIONE=$(cat "$MYPATH/regioni.txt"| grep "$REGIONE" | cut -f2 -d",")
		
		TMPREGIONECSVFILE="$OUTPATH/$REGIONEFORMAT/covid"$REGIONEFORMAT"tmp.csv"
		PROVINCEREGIONECSVFILE="$OUTPATH/$REGIONEFORMAT/covidProvince.csv"
		CSVFILE="$OUTPATH/$REGIONEFORMAT/covid.csv"

		echo "$REGIONE - pop.: $POPOLAZIONE"

		if [ ! -d "$OUTPATH/$REGIONEFORMAT" ]; then 
			mkdir "$OUTPATH/$REGIONEFORMAT"
		fi
	fi
fi

if [ -z "$REGIONE" ]; then
	POPOLAZIONE=$(cat $MYPATH/regioni.txt | grep "Italia" | cut -f2 -d",") 
	echo "ITALIA - pop. $POPOLAZIONE"	
fi

IMGFILE="$OUTPATH/covid$REGIONEFORMAT.svg"

echo "$INDENT""Start.....: $(date) $FORCED" >>"$LOGFILE"

LATESTDONE=$(cat "$LATESTDONEFILE")
TODAY=$(date +"%Y-%m"-%d)

if [ -z "$FORCED" ] && [ "$LATESTDONE" = "$TODAY" ]; then
	echo "$INDENT""Already Updated" >>"$LOGFILE"
	echo "$INDENT""End (NoOp): $(date)" >>"$LOGFILE"
	exit
fi

curl -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/pcm-dpc/COVID-19/master/dati-andamento-nazionale/dpc-covid19-ita-andamento-nazionale-latest.csv >"$LATESTFILE" 2>/dev/null

LATESTDOWNLOAD=$(tail -1 $LATESTFILE | cut -f1 -d"T")

echo "Latest download: $LATESTDOWNLOAD" >>"$LOGFILE"
echo "Latest done....: $LATESTDONE" >>"$LOGFILE"
echo "Today..........: $TODAY" >>"$LOGFILE"

if [ "$LATESTDONE" != "$LATESTDOWNLOAD" ] && [ "$TODAY" = "$LATESTDOWNLOAD" ]; then
	echo "Update found!" >>"$LOGFILE"
else
	if [ -z "$FORCED" ]; then
		DATAOGGI=$(date +"%d-%m-%Y - %H:%M")
		cat "$HTMLFILE" | sed "s/<!-- data -->.*/<!-- data --> $DATAOGGI/g" >>"$HTMLFILETMP"
		mv "$HTMLFILETMP" "$HTMLFILE"
		curl -T "$HTMLFILE" -u "$CREDENTIALS" "ftp://iltrev.it/" 2>/dev/null
		echo "$INDENT""End (NoOp): $(date)" >>"$LOGFILE"
		exit
	fi
fi

echo "$LATESTDOWNLOAD" > "$LATESTDONEFILE"

if [ -z "$REGIONE" ]; then
	curl -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/pcm-dpc/COVID-19/master/dati-andamento-nazionale/dpc-covid19-ita-andamento-nazionale.csv >"$TMPCSVFILE" 2>/dev/null
	curl -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/pcm-dpc/COVID-19/master/dati-regioni/dpc-covid19-ita-regioni.csv >"$TMPREGIONIFILE" 2>/dev/null
	curl -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/pcm-dpc/COVID-19/master/dati-province/dpc-covid19-ita-province-latest.csv >"$PROVINCECSVFILE" 2>/dev/null
else
	head -1 "$TMPREGIONIFILE" | cut -f1,2,7- -d"," >"$TMPREGIONECSVFILE"
	cat "$TMPREGIONIFILE" | grep ",$REGIONE," | cut -f1,2,7- -d"," >>"$TMPREGIONECSVFILE"
	cat "$PROVINCECSVFILE" | grep ",$REGIONE," >"$PROVINCEREGIONECSVFILE"
	TMPCSVFILE=$TMPREGIONECSVFILE
fi

export TAMPONITOTALIIERI=0
export DECESSITOTALIIERI=0
export COUNT=0
export RECORDTAMPONI=0
export RECORDCASI=0
export RECORDDECESSI=0

cat "$TMPCSVFILE" | while read LINE; do
	if [ $COUNT -eq 0 ]; then
		echo "$LINE,\"positivi/tamponi\",\"tamponi giorno\",\"deceduti giorno\",\"record tamponi\",\"record casi\",\"record decessi\",\"media nuovi casi 7gg\",\"variazione media 7gg\",\"media deceduti 7gg\"" | sed "s/_/ /g" >"$CSVFILE"
		((COUNT+=1))
		continue
	fi

	CASIIERI=$CASI
	CASI=$(echo "$LINE" | cut -f9 -d",")
	TAMPONITOTALI=$(echo "$LINE" | cut -f15 -d",")
	TAMPONIIERI=$TAMPONIOGGI
	TAMPONIOGGI=$(echo "$TAMPONITOTALI $TAMPONITOTALIIERI - p" | dc)

	CASISETTEGIORNI=("${CASISETTEGIORNI[@]}" "$CASI")
	if [ "${#CASISETTEGIORNI[@]}" -gt 7 ]; then
		CASISETTEGIORNI=("${CASISETTEGIORNI[@]:1}")
		let MEDIACASI=$(IFS=+; echo "$((${CASISETTEGIORNI[*]}))")/7
	else
		MEDIACASI=0
	fi

	VARIAZIONE=$(echo "$LINE" | cut -f8 -d",")
	VARIAZIONISETTEGIORNI=("${VARIAZIONISETTEGIORNI[@]}" "$VARIAZIONE")
	if [ "${#VARIAZIONISETTEGIORNI[@]}" -gt 7 ]; then
		VARIAZIONISETTEGIORNI=("${VARIAZIONISETTEGIORNI[@]:1}")
		let MEDIAVARIAZIONI=$(IFS=+; echo "$((${VARIAZIONISETTEGIORNI[*]}))")/7
	else
		MEDIAVARIAZIONI=0
	fi
	
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

	if [ "$DECESSIOGGI" -le "0" ] ; then
		DECESSIOGGI=0
	fi

	DECESSISETTEGIORNI=("${DECESSISETTEGIORNI[@]}" "$DECESSIOGGI")
	if [ "${#DECESSISETTEGIORNI[@]}" -gt 7 ]; then
		DECESSISETTEGIORNI=("${DECESSISETTEGIORNI[@]:1}")
		let MEDIADECESSI=$(IFS=+; echo "$((${DECESSISETTEGIORNI[*]}))")/7
	else
		MEDIADECESSI=0
	fi

	if [ $CASI -gt $RECORDCASI ]; then
		RECORDCASI=$CASI
	fi

	if [ $TAMPONIOGGI -gt $RECORDTAMPONI ]; then
		RECORDTAMPONI=$TAMPONIOGGI
	fi

	if [ $DECESSIOGGI -gt $RECORDDECESSI ]; then
		RECORDDECESSI=$DECESSIOGGI
	fi

	echo "$LINE,$RAPPORTO,$TAMPONIOGGI,$DECESSIOGGI,$RECORDTAMPONI,$RECORDCASI,$RECORDDECESSI,$MEDIACASI,$MEDIAVARIAZIONI,$MEDIADECESSI" >>"$CSVFILE"

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

TOTALEPOSITIVI=$(echo $DATIOGGI | cut -f7 -d",")
PERCPOSITIVI=$(echo "$TOTALEPOSITIVI $POPOLAZIONE / 100 * p" | dc)

if [ -z "$REGIONE" ]; then
	/opt/bin/gnuplot /share/Public/bin/covid/covid.gnuplot  >"$IMGFILE" 2>>"$LOGFILE"
else
	GNUPLOTCSVFILE="$REGIONEFORMAT""\/covid.csv"
	cat "$MYPATH""/covid.gnuplot" | sed "s/covid.csv/$GNUPLOTCSVFILE/g" >"$MYPATH/out/$REGIONEFORMAT/covidRegione.gnuplot" 2>>"$LOGFILE"
	/opt/bin/gnuplot "$MYPATH/out/$REGIONEFORMAT/covidRegione.gnuplot" >"$IMGFILE" 2>>"$LOGFILE"
fi

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
<label for="Regioni">Seleziona regione:</label>
<select name="forma" onchange="location = this.value;">
EOF

echo "<option value=\"https://www.iltrev.it/covid\">ITALIA</option>" >>"$HTMLFILE"

for REG in "${REGIONI[@]}"; do
	REGFORMAT=$(echo "$REG" | sed "s/[^[:alnum:]]//g")
	if [ "$REGFORMAT" = "$REGIONEFORMAT" ]; then
		SELECTED="selected=\"selected\""
	else
		SELECTED=""
	fi
	echo "<option $SELECTED value=\"https://www.iltrev.it/covid/$REGFORMAT\">$REG</option>" >>"$HTMLFILE"
done

echo "</select>" >>"$HTMLFILE"
echo "<br>Iscriviti al <a href=\"https://t.me/instantcovid\" target="_blank">Canale Telegram</a>" >>"$HTMLFILE"


echo "<h3><center>Situazione COVID-19 - $REGIONEWEB<br>" >>"$HTMLFILE"
echo "<!-- data -->" $(date +"%d-%m-%Y - %H:%M") >>"$HTMLFILE"
echo "<br><i>(dati del $DATAULTIMO)</i></center></h3>" >>"$HTMLFILE"
echo "<br><pre>Nuovi tamponi: <b>$TAMPONIOGGI</b> (precedente: $TAMPONIIERI)" >>"$HTMLFILE"
echo "          Max: $RECORDTAMPONI" >>"$HTMLFILE"
echo "   Nuovi casi: <b>$CASIOGGI $RAPPORTOCASITAMPONIOGGI%</b> (precedente: $CASIIERI $RAPPORTOCASITAMPONIIERI%)" >>"$HTMLFILE"
echo "          Max: $RECORDCASI" >>"$HTMLFILE"
echo "Nuovi decessi: <b>$DECESSIOGGI</b> (precedente: $DECESSIIERI)" >>"$HTMLFILE"
echo "          Max: $RECORDDECESSI" >>"$HTMLFILE"
echo "   Ricoverati: <b>$RICOVERATI</b> (precedente: $RICOVERATIIERI)" >>"$HTMLFILE"
echo " Terapie int.: <b>$TERAPIEINTENSIVE</b> (precedente: $TERAPIEINTENSIVEIERI)" >>"$HTMLFILE"
echo "   % positivi: <b>$(printf "%.3f" $PERCPOSITIVI)</b> ($TOTALEPOSITIVI su $POPOLAZIONE abitanti)" >>"$HTMLFILE"

if [ ! -z "$REGIONE" ]; then

	echo "<br>" >>"$HTMLFILE"

	cat $PROVINCEREGIONECSVFILE | while read RIGAPROVINCIA; do
	PROVINCIA=$(echo "$RIGAPROVINCIA" | cut -f6 -d"," | sed "s/ì/\&igrave;/g")
		
		POSITIVIPROVINCIA=$(echo "$RIGAPROVINCIA" | cut -f10 -d",")
		if [ "$POSITIVIPROVINCIA" != "0" ]; then
			echo "   $PROVINCIA: $POSITIVIPROVINCIA" >>"$HTMLFILE"
		fi
	done
fi

echo "</pre><p><img src="https://www.iltrev.it/covid/covid$REGIONEFORMAT.svg" id="responsive-image" /></p>" >>"$HTMLFILE"

cat <<EOF >> $HTMLFILE
Elaborazione dati forniti dal Dipartimento della Protezione Civile 
<br>(fonte: <a href="https://github.com/pcm-dpc/COVID-19" target="_blank">https://github.com/pcm-dpc/COVID-19</a>)
</body>
</html> 
EOF

WEBPATH="ftp://iltrev.it/"

if [ ! -z "$REGIONE" ]; then
	WEBPATH="$WEBPATH$REGIONEFORMAT/"
fi

curl -T $HTMLFILE -u $CREDENTIALS $WEBPATH  2>/dev/null

if [ -z "$FORCED" ]; then
	echo "Started Telegram post: $(date)" >>"$LOGFILE"
	curl -X POST -H 'Content-Type: application/json' -d "{ \"chat_id\": \"@instantcovid\", \"text\": \"Aggiornamento COVID-19\nNuovi Casi: $CASIOGGI ($RAPPORTOCASITAMPONIOGGI%)\nTamponi: $TAMPONIOGGI\nDecessi: $DECESSIOGGI\nRicoverati: $RICOVERATI ($TERAPIEINTENSIVE t.i.)\n\nMaggiori informazioni:\nhttps://www.iltrev.it/covid\" }" https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage 2>&1 | tee -a "$LOGFILE"
	echo "Done Telegram post..: $(date)" >>"$LOGFILE"
fi


# esecuzione di tutto il procedimento tra tutte le regioni
if [ -z "$REGIONE" ]; then
	for REG in "${REGIONI[@]}"; do
		$MYPATH/covid.sh "$REG"
	done
fi

echo "$INDENT""End.......: $(date)" >>"$LOGFILE"
