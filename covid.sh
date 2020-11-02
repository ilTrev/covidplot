#!/bin/sh

MYPATH="/share/Public/bin/covid"
OUTPATH="$MYPATH/out"
LATESTFILE="$MYPATH/COVID-19/dati-andamento-nazionale/dpc-covid19-ita-andamento-nazionale-latest.csv"
TMPREGIONIFILE="$MYPATH/COVID-19/dati-regioni/dpc-covid19-ita-regioni.csv"
PROVINCECSVFILE="$MYPATH/COVID-19/dati-province/dpc-covid19-ita-province-latest.csv"
LATESTDONEFILE="$OUTPATH/covidLatestDone.txt"
TMPSINGOLAREGIONEFILE="$OUTPATH/$REGIONEFORMAT/covidLatest.tmp"
TMPCSVFILE="$MYPATH/COVID-19/dati-andamento-nazionale/dpc-covid19-ita-andamento-nazionale.csv"
CSVFILE="$OUTPATH/covid.csv"
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

if [ -z "$REGIONE" ]; then
	IMGFILE="$OUTPATH/covid.svg"
else
	IMGFILE="$OUTPATH/$REGIONEFORMAT/covid$REGIONEFORMAT.svg"
fi

echo "$INDENT""Start.....: $(date) $FORCED" >>"$LOGFILE"

LATESTDONE=$(cat "$LATESTDONEFILE")
TODAY=$(date +"%Y-%m"-%d)

if [ -z "$FORCED" ] && [ "$LATESTDONE" = "$TODAY" ]; then
	echo "$INDENT""Already Updated" >>"$LOGFILE"
	echo "$INDENT""End (NoOp): $(date)" >>"$LOGFILE"
	exit
fi

cd "$MYPATH/COVID-19"
git pull >"$LOGFILE" 2>&1
cd "$MYPATH"

LATESTDOWNLOAD=$(tail -1 $LATESTFILE | cut -f1 -d"T")

if [ -z "$REGIONE" ]; then
	echo "Latest download: $LATESTDOWNLOAD" >>"$LOGFILE"
	echo "Latest done....: $LATESTDONE" >>"$LOGFILE"
	echo "Today..........: $TODAY" >>"$LOGFILE"
fi

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

if [ ! -z "$REGIONE" ]; then
	head -1 "$TMPREGIONIFILE" | cut -f1,2,7- -d"," >"$TMPREGIONECSVFILE"
	cat "$TMPREGIONIFILE" | grep ",$REGIONE," | cut -f1,2,7- -d"," >>"$TMPREGIONECSVFILE"
	cat "$PROVINCECSVFILE" | grep ",$REGIONE," >"$PROVINCEREGIONECSVFILE"
	TMPCSVFILE=$TMPREGIONECSVFILE
fi

export TAMPONITOTALIIERI=0
export DECESSITOTALIIERI=0
export COUNT=0
export RECORDTAMPONI=0
export RECORDTERINT=0
export RECORDCASI=0
export RECORDDECESSI=0

cat "$TMPCSVFILE" | while read LINE; do
	LINE=$(echo $LINE | sed "s///g")

	if [ $COUNT -eq 0 ]; then
		echo "$LINE,\"positivi/tamponi\",\"tamponi giorno\",\"deceduti giorno\",\"record tamponi\",\"record casi\",\"record decessi\",\"media nuovi casi 7gg\",\"variazione media 7gg\",\"media deceduti 7gg\",\"media tamponi 7gg\",\"media ricoverati 7gg\",\"media ter. int. 7gg\",\"media ter. int. 14gg\",\"media ricoverati 14gg\",\"media decessi 14gg\",\"media tamponi 14gg\",\"media nuovi casi 14gg\",\"max terapie int.\"" | sed "s/_/ /g" >"$CSVFILE"
		((COUNT+=1))
		continue
	fi

	CASIIERI=$CASI
	CASI=$(echo "$LINE" | cut -f9 -d",")
	TAMPONITOTALI=$(echo "$LINE" | cut -f15 -d",")
	TAMPONIIERI=$TAMPONIOGGI
	TAMPONIOGGI=$(echo "$TAMPONITOTALI $TAMPONITOTALIIERI - p" | dc)

	TERINTOGGI=$(echo "$LINE" | cut -f4 -d",")
	TERINT7GG=("${TERINT7GG[@]}" "$TERINTOGGI")
	if [ "${#TERINT7GG[@]}" -gt 7 ]; then
		TERINT7GG=("${TERINT7GG[@]:1}")
		let MEDIATERINT7GG=$(IFS=+; echo "$((${TERINT7GG[*]}))")/7
	else
		MEDIATERINT7GG=0
	fi

	TERINT14GG=("${TERINT14GG[@]}" "$TERINTOGGI")
	if [ "${#TERINT14GG[@]}" -gt 14 ]; then
		TERINT14GG=("${TERINT14GG[@]:1}")
		let MEDIATERINT14GG=$(IFS=+; echo "$((${TERINT14GG[*]}))")/14
	else
		MEDIATERINT14GG=0
	fi

	RICOVERATIOGGI=$(echo "$LINE" | cut -f3 -d",")
	RICOVERATI7GG=("${RICOVERATI7GG[@]}" "$RICOVERATIOGGI")
	if [ "${#RICOVERATI7GG[@]}" -gt 7 ]; then
		RICOVERATI7GG=("${RICOVERATI7GG[@]:1}")
		let MEDIARICOVERATI7GG=$(IFS=+; echo "$((${RICOVERATI7GG[*]}))")/7
	else
		MEDIARICOVERATI7GG=0
	fi

	RICOVERATI14GG=("${RICOVERATI14GG[@]}" "$RICOVERATIOGGI")
	if [ "${#RICOVERATI14GG[@]}" -gt 14 ]; then
		RICOVERATI14GG=("${RICOVERATI14GG[@]:1}")
		let MEDIARICOVERATI14GG=$(IFS=+; echo "$((${RICOVERATI14GG[*]}))")/14
	else
		MEDIARICOVERATI14GG=0
	fi

	TAMPONI7GG=("${TAMPONI7GG[@]}" "$TAMPONIOGGI")
	if [ "${#TAMPONI7GG[@]}" -gt 7 ]; then
		TAMPONI7GG=("${TAMPONI7GG[@]:1}")
		let MEDIATAMPONI7GG=$(IFS=+; echo "$((${TAMPONI7GG[*]}))")/7
	else
		MEDIATAMPONI7GG=0
	fi

	TAMPONI14GG=("${TAMPONI14GG[@]}" "$TAMPONIOGGI")
	if [ "${#TAMPONI14GG[@]}" -gt 14 ]; then
		TAMPONI14GG=("${TAMPONI14GG[@]:1}")
		let MEDIATAMPONI14GG=$(IFS=+; echo "$((${TAMPONI14GG[*]}))")/14
	else
		MEDIATAMPONI14GG=0
	fi

	CASI7GG=("${CASI7GG[@]}" "$CASI")
	if [ "${#CASI7GG[@]}" -gt 7 ]; then
		CASI7GG=("${CASI7GG[@]:1}")
		let MEDIACASI7GG=$(IFS=+; echo "$((${CASI7GG[*]}))")/7
	else
		MEDIACASI7GG=0
	fi

	CASI14GG=("${CASI14GG[@]}" "$CASI")
	if [ "${#CASI14GG[@]}" -gt 14 ]; then
		CASI14GG=("${CASI14GG[@]:1}")
		let MEDIACASI14GG=$(IFS=+; echo "$((${CASI14GG[*]}))")/14
	else
		MEDIACASI14GG=0
	fi

	VARIAZIONE=$(echo "$LINE" | cut -f8 -d",")
	VARIAZIONI7GG=("${VARIAZIONI7GG[@]}" "$VARIAZIONE")
	if [ "${#VARIAZIONI7GG[@]}" -gt 7 ]; then
		VARIAZIONI7GG=("${VARIAZIONI7GG[@]:1}")
		let MEDIAVARIAZIONI=$(IFS=+; echo "$((${VARIAZIONI7GG[*]}))")/7
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

	DECESSI7GG=("${DECESSI7GG[@]}" "$DECESSIOGGI")
	if [ "${#DECESSI7GG[@]}" -gt 7 ]; then
		DECESSI7GG=("${DECESSI7GG[@]:1}")
		let MEDIADECESSI7GG=$(IFS=+; echo "$((${DECESSI7GG[*]}))")/7
	else
		MEDIADECESSI7GG=0
	fi

	DECESSI14GG=("${DECESSI14GG[@]}" "$DECESSIOGGI")
	if [ "${#DECESSI14GG[@]}" -gt 14 ]; then
		DECESSI14GG=("${DECESSI14GG[@]:1}")
		let MEDIADECESSI14GG=$(IFS=+; echo "$((${DECESSI14GG[*]}))")/14
	else
		MEDIADECESSI14GG=0
	fi

	if [ $TERINTOGGI -gt $RECORDTERINT ]; then
		RECORDTERINT=$TERINTOGGI
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

	echo "$LINE,$RAPPORTO,$TAMPONIOGGI,$DECESSIOGGI,$RECORDTAMPONI,$RECORDCASI,$RECORDDECESSI,$MEDIACASI7GG,$MEDIAVARIAZIONI,$MEDIADECESSI7GG,$MEDIATAMPONI7GG,$MEDIARICOVERATI7GG,$MEDIATERINT7GG,$MEDIATERINT14GG,$MEDIARICOVERATI14GG,$MEDIADECESSI14GG,$MEDIATAMPONI14GG,$MEDIACASI14GG,$RECORDTERINT" >>"$CSVFILE"

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
RECORDTERINT=$(echo $DATIOGGI | cut -f35 -d",")

TOTALEPOSITIVI=$(echo $DATIOGGI | cut -f7 -d",")
PERCPOSITIVI=$(echo "$TOTALEPOSITIVI $POPOLAZIONE / 100 * p" | dc)

MEDIACASI7GG=$(echo $DATIOGGI | cut -f24 -d",")
MEDIADECESSI7GG=$(echo $DATIOGGI | cut -f26 -d",")
MEDIATAMPONI7GG=$(echo $DATIOGGI | cut -f27 -d",")
MEDIARICOVERATI7GG=$(echo $DATIOGGI | cut -f28 -d",")
MEDIATERINT7GG=$(echo $DATIOGGI | cut -f29 -d",")
MEDIATERINT14GG=$(echo $DATIOGGI | cut -f30 -d",")
MEDIARICOVERATI14GG=$(echo $DATIOGGI | cut -f31 -d",")
MEDIADECESSI14GG=$(echo $DATIOGGI | cut -f32 -d",")
MEDIATAMPONI14GG=$(echo $DATIOGGI | cut -f33 -d",")
MEDIACASI14GG=$(echo $DATIOGGI | cut -f34 -d",")

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
<!DOCTYPE html>
<html lang="it">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<meta property="og:image" content="https://upload.wikimedia.org/wikipedia/commons/8/82/SARS-CoV-2_without_background.png">
<meta name="viewport" content="width=device-width">
<!-- Global site tag (gtag.js) - Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=UA-180932911-1"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', 'UA-180932911-1');
</script>


<link href='https://fonts.googleapis.com/css?family=Roboto%20Mono' rel='stylesheet'>
<style>
#responsive-image { width: 100%;  height: auto;}
body {
  font-family: 'Roboto Mono';
  font-size: 10px; 
}

.highlight {
  font-size:12px;
  font-weight:bold;
}

table {
  max-width: 90%;
  margin: 0 auto;
  border: 1px solid #DDDDDD;
  border-collapse: collapse;
}

table, th {
  border: 1px solid #DDDDDD;
  border-collapse: collapse;
  padding: 10px;
  font-size: 10px;
}

td {
  border: 1px solid #DDDDDD;
  border-collapse: collapse;
  padding:10px;
  text-align: right;
  font-size: 10px;
}

pre { 
  font-family: 'Roboto Mono';
  font-size: 10px; 
}
h3 {
  font-weight:bold;
  text-align:center;
  font-size:14px;
} 

</style>
EOF

echo "<title>Covid-19 $REGIONEWEB</title>" >>"$HTMLFILE"

cat <<EOF >>"$HTMLFILE"
<link rel="shortcut icon" type="image/png" href="https://www.iltrev.it/covid/favicon.png"/>
</head>
<body>
<label>Seleziona regione:</label>
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
echo "<br><a href="mailto:instantcovid@iltrev.it">Contattami</a>" >>"$HTMLFILE"


echo "<h3>Situazione COVID-19 - $REGIONEWEB<br>" >>"$HTMLFILE"
echo "<!-- data -->" $(date +"%d-%m-%Y - %H:%M") >>"$HTMLFILE"
echo "<br><i>(dati del $DATAULTIMO)</i></h3>" >>"$HTMLFILE"

echo "<table><thead><tr><th></th><th>Ultimo</th><th>Preced.</th><th>Max</th><th>Media 7gg</th><th>Media 14gg</th></tr></thead>" >>"$HTMLFILE"
echo "<tbody><tr><td>Tamponi</td><td>$TAMPONIOGGI</td><td>$TAMPONIIERI</td><td>$RECORDTAMPONI</td><td>$MEDIATAMPONI7GG</td><td>$MEDIATAMPONI14GG</td></tr>" >>"$HTMLFILE"
echo "<tr><td>Nuovi casi</td><td class="highlight">$CASIOGGI</td><td>$CASIIERI</td><td>$RECORDCASI</td><td>$MEDIACASI7GG</td><td>$MEDIACASI14GG</td></tr>" >>"$HTMLFILE"
echo "<tr><td>%posit./tamponi</td><td>$RAPPORTOCASITAMPONIOGGI</td><td>$RAPPORTOCASITAMPONIIERI</td><td>n/a</td><td>n/a</td><td>n/a</td></tr>" >>"$HTMLFILE"
echo "<tr><td>Decessi</td><td class="highlight">$DECESSIOGGI</td><td>$DECESSIIERI</td><td>$RECORDDECESSI</td><td>$MEDIADECESSI7GG</td><td>$MEDIADECESSI14GG</td></tr>" >>"$HTMLFILE"
echo "<tr><td>Ricoverati</td><td class="highlight">$RICOVERATI</td><td>$RICOVERATIIERI</td><td>n/a</td><td>$MEDIARICOVERATI7GG</td><td>$MEDIARICOVERATI14GG</td></tr>" >>"$HTMLFILE"
echo "<tr><td>Terapie int.</td><td class="highlight">$TERAPIEINTENSIVE</td><td>$TERAPIEINTENSIVEIERI</td><td>$RECORDTERINT</td><td>$MEDIATERINT7GG</td><td>$MEDIATERINT14GG</td></tr>" >>"$HTMLFILE"
echo "<tr><td>% positivi<br>($POPOLAZIONE abit.)</td><td>$(printf "%.3f" $PERCPOSITIVI)</td><td>n/a</td><td>n/a</td><td>n/a</td><td>n/a</td></tr>" >>"$HTMLFILE"
echo "</tbody></table>" >>"$HTMLFILE"

if [ ! -z "$REGIONE" ]; then

	echo "<br>" >>"$HTMLFILE"

	TOTALECASIREGIONE=$(tail -1 "$CSVFILE" | cut -f14 -d",")
	echo "<pre>Totale casi da inizio pandemia: <b>$TOTALECASIREGIONE</b>" >>"$HTMLFILE"
	echo "<br>di cui:" >>"$HTMLFILE"

	cat $PROVINCEREGIONECSVFILE | while read RIGAPROVINCIA; do
		PROVINCIA=$(echo "$RIGAPROVINCIA" | cut -f6 -d"," | sed "s/ì/\&igrave;/g")
		TOTALECASIPROVINCIA=$(echo "$RIGAPROVINCIA" | cut -f10 -d",")
		if [ "$TOTALECASIPROVINCIA" != "0" ]; then
			echo "   $PROVINCIA: <b>$TOTALECASIPROVINCIA</b>" >>"$HTMLFILE"
		fi
	done
fi

echo "</pre><p><img style="width:100%" alt="Grafici" src="https://www.iltrev.it/covid/covid$REGIONEFORMAT.svg" id="responsive-image" /></p>" >>"$HTMLFILE"

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
