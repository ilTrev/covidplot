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
RTCSVFILE="$OUTPATH/rt.csv"
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
DAYSAMOUNT=60

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

		REGIONEPATH="$OUTPATH/$REGIONEFORMAT"
		HTMLFILE="$REGIONEPATH/index.html"

		INDENT=" - "
		POPOLAZIONE=$(cat "$MYPATH/regioni.csv"| grep "$REGIONE" | cut -f2 -d",")
		POSTITERAPIAINTENSIVA=$(cat $MYPATH/regioni.csv | grep "$REGIONE" | cut -f3 -d",") 
		
		TMPREGIONECSVFILE="$REGIONEPATH/covid"$REGIONEFORMAT"tmp.csv"
		PROVINCEREGIONECSVFILE="$REGIONEPATH/covidProvinceLatest.csv"
		PROVINCEREGIONEFULLCSVFILE="$REGIONEPATH/covidProvinceFull.csv"
		CSVFILE="$REGIONEPATH/covid.csv"
		CSVFILESHORT="$REGIONEPATH/covidshort.csv"

		echo "$REGIONE - pop.: $POPOLAZIONE"

		if [ ! -d "$REGIONEPATH" ]; then 
			mkdir "$REGIONEPATH"
		fi

		if [ ! -d "$REGIONEPATH/province" ]; then 
			mkdir "$REGIONEPATH/province"	
		fi
	fi
fi

if [ -z "$REGIONE" ]; then
	POPOLAZIONE=$(cat $MYPATH/regioni.csv | grep "Italia" | cut -f2 -d",") 
	POSTITERAPIAINTENSIVA=$(cat $MYPATH/regioni.csv | grep "Italia" | cut -f3 -d",") 
	echo "ITALIA - pop. $POPOLAZIONE"	
fi

if [ -z "$REGIONE" ]; then
	IMGFILE="$OUTPATH/covid.svg"
	IMGFILESHORT="$OUTPATH/covidshort.svg"
	RTIMGFILE="$OUTPATH/rt.svg"
else
	IMGFILE="$REGIONEPATH/covid$REGIONEFORMAT.svg"
	RTIMGFILE="$REGIONEPATH/rt.svg"
	IMGFILESHORT="$REGIONEPATH/covid$REGIONEFORMAT""short.svg"
	REGIONEIMGFILE="$REGIONEPATH/covidProvince$REGIONEFORMAT.svg"
	REGIONEIMGFILESHORT="$REGIONEPATH/covidProvince$REGIONEFORMAT""short.svg"
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
/opt/bin/git fetch >"$MYPATH/out/git.log" 2>&1
if [ $(wc -l "$MYPATH/out/git.log" | cut -f1 -d" ") -gt 0 ]; then
	/opt/bin/git pull >>"$LOGFILE" 2>&1
fi

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

	head -1 "$PROVINCEFULLCSVFILE" >"$PROVINCEREGIONEFULLCSVFILE"
	cat "$PROVINCEFULLCSVFILE" | grep ",$REGIONE," | sed "s/In fase di definizione/In aggiornamento/g" >>"$PROVINCEREGIONEFULLCSVFILE"

	TMPCSVFILE=$TMPREGIONECSVFILE

	cat <<EOF >"$REGIONEPATH/covidProvince.gnuplot"
set datafile separator ","

unset key
set xdata time 			
set timefmt "%Y-%m-%d"
set format x "%d-%b"
set key autotitle columnhead

#set xrange ["2020-03-01":*]

set style line 100 lt 1 lc rgb "grey" lw .5
set grid y2tics lt 0 lw 0.5 lc rgb "#888888"
set grid xtics lt 0 lw 0.5 lc rgb "#888888"
set style line 101 lt 1 lw 2

set terminal svg size 1600,800 linewidth 1
set multiplot layout 1,1
set title font "Arial,20" 

set title "Province"
set y2label "Casi totali"
set y2tics
unset ytics

EOF

	PLOT="plot "
	cat $PROVINCEREGIONECSVFILE | grep -v "definizione" | grep -v "Fuori Regione" | while read RIGAPROVINCIA; do
		PROVINCIA=$(echo "$RIGAPROVINCIA" | cut -f6 -d"," | sed "s/\/.*//g")
		head -1 $PROVINCEREGIONEFULLCSVFILE | sed "s/totale_casi/$PROVINCIA/g" >"$REGIONEPATH/province/covid$REGIONE$PROVINCIA.csv"
		cat "$PROVINCEREGIONEFULLCSVFILE" | grep ",$PROVINCIA," >>"$REGIONEPATH/province/covid$REGIONE$PROVINCIA.csv"

		head -1 "$REGIONEPATH/province/covid$REGIONE$PROVINCIA.csv" >"$REGIONEPATH/province/covid$REGIONE$PROVINCIA""short"
		tail -$DAYSAMOUNT "$REGIONEPATH/province/covid$REGIONE$PROVINCIA.csv" >>"$REGIONEPATH/province/covid$REGIONE$PROVINCIA""short"

		echo "$PLOT\"$REGIONEPATH/province/covid$REGIONE$PROVINCIA.csv\" using 1:10 with linespoints pointtype 7 pointsize 0.25 axis x1y2 title \"$PROVINCIA\" at end, \\" >>"$REGIONEPATH/covidProvince.gnuplot"

		PLOT=""
	done
fi

TAMPONITOTALI=0
TAMPONITOTALIIERI=0
DECESSITOTALIIERI=0
RECORDTAMPONI=0
RECORDTERINT=0
RECORDCASI=0
RECORDDECESSI=0
RECORDRICOVERATI=0

MEDIACASI7GG=0
MEDIADECESSI7GG=0
MEDIARICOVERATI7GG=0
MEDIATAMPONI7GG=0
MEDIATERINT7GG=0
MEDIAVARIAZIONI=0

CASI7GG=(0 0 0 0 0 0 0)
DECESSI7GG=(0 0 0 0 0 0 0)
RICOVERATI7GG=(0 0 0 0 0 0 0)
TAMPONI7GG=(0 0 0 0 0 0 0)
TERINT7GG=(0 0 0 0 0 0 0)
VARIAZIONI7GG=(0 0 0 0 0 0 0)

CASI14GG=(0 0 0 0 0 0 0 0 0 0 0 0 0 0)
DECESSI14GG=(0 0 0 0 0 0 0 0 0 0 0 0 0 0)
RICOVERATI14GG=(0 0 0 0 0 0 0 0 0 0 0 0 0 0)
TAMPONI14GG=(0 0 0 0 0 0 0 0 0 0 0 0 0 0)
TERINT14GG=(0 0 0 0 0 0 0 0 0 0 0 0 0 0)
VARIAZIONI14GG=(0 0 0 0 0 0 0 0 0 0 0 0 0 0)

LINES=$(wc -l "$TMPCSVFILE" | cut -f1 -d" ")
((LINES-=1))

echo "$(head -1 $TMPCSVFILE | sed "s///g"),\"positivi/tamponi\",\"tamponi giorno\",\"deceduti giorno\",\"record tamponi\",\"record casi\",\"record decessi\",\"media nuovi casi 7gg\",\"variazione media 7gg\",\"media deceduti 7gg\",\"media tamponi 7gg\",\"media ricoverati 7gg\",\"media ter. int. 7gg\",\"media ter. int. 14gg\",\"media ricoverati 14gg\",\"media decessi 14gg\",\"media tamponi 14gg\",\"media nuovi casi 14gg\",\"max terapie int.\",\"max. ricoverati\"" | sed "s/_/ /g" >"$CSVFILE"

tail -$LINES "$TMPCSVFILE" | sed "s///g" | while read LINE; do
	CASIIERI=$CASI
	TAMPONIIERI=$TAMPONIOGGI
	TAMPONITOTALIIERI=$TAMPONITOTALI

	LINEDATA=$(cut -f1 -d"T" <<<$LINE)
	LINE=$(cut -f2- -d"," <<<$LINE | sed "s/.*/$LINEDATA,&/g")

	IFS="," read UNO DUE RICOVERATIOGGI TERINTOGGI CINQUE SEI SETTE VARIAZIONE CASI DIECI DECESSITOTALI DODICI TREDICI QUATTORDICI TAMPONITOTALI SEDICI NOTE <<<"$LINE"

	if [ "$NOTE" != "" ]; then
		NOTEFIXED=$(sed "s/\,//g" <<<$NOTE)
		LINE=$(cut -f1-16 -d"," <<<$LINE)",$NOTEFIXED"
	fi

	(( TAMPONIOGGI = TAMPONITOTALI - TAMPONITOTALIIERI ))
	(( DECESSIOGGI = DECESSITOTALI - DECESSITOTALIIERI ))

	if (( DECESSIOGGI < 0 )) ; then
		DECESSIOGGI=0
	fi

	CASI7GG=("${CASI7GG[@]}" "$CASI")
	DECESSI7GG=("${DECESSI7GG[@]}" "$DECESSIOGGI")
	RICOVERATI7GG=("${RICOVERATI7GG[@]}" "$RICOVERATIOGGI")
	TAMPONI7GG=("${TAMPONI7GG[@]}" "$TAMPONIOGGI")
	TERINT7GG=("${TERINT7GG[@]}" "$TERINTOGGI")
	VARIAZIONI7GG=("${VARIAZIONI7GG[@]}" "$VARIAZIONE")

	CASI7GG=("${CASI7GG[@]:1}")
	DECESSI7GG=("${DECESSI7GG[@]:1}")
	RICOVERATI7GG=("${RICOVERATI7GG[@]:1}")
	TAMPONI7GG=("${TAMPONI7GG[@]:1}")
	TERINT7GG=("${TERINT7GG[@]:1}")
	VARIAZIONI7GG=("${VARIAZIONI7GG[@]:1}")

	let MEDIACASI7GG=$((${CASI7GG[@]/%/+}0))/7
	let MEDIADECESSI7GG=$((${DECESSI7GG[@]/%/+}0))/7
	let MEDIARICOVERATI7GG=$((${RICOVERATI7GG[@]/%/+}0))/7
	let MEDIATAMPONI7GG=$((${TAMPONI7GG[@]/%/+}0))/7
	let MEDIATERINT7GG=$((${TERINT7GG[@]/%/+}0))/7
	let MEDIAVARIAZIONI=$((${VARIAZIONI7GG[@]/%/+}0))/7

	TERINT14GG=("${TERINT14GG[@]}" "$TERINTOGGI")
	RICOVERATI14GG=("${RICOVERATI14GG[@]}" "$RICOVERATIOGGI")
	TAMPONI14GG=("${TAMPONI14GG[@]}" "$TAMPONIOGGI")
	CASI14GG=("${CASI14GG[@]}" "$CASI")
	DECESSI14GG=("${DECESSI14GG[@]}" "$DECESSIOGGI")

	CASI14GG=("${CASI14GG[@]:1}")
	DECESSI14GG=("${DECESSI14GG[@]:1}")
	RICOVERATI14GG=("${RICOVERATI14GG[@]:1}")
	TAMPONI14GG=("${TAMPONI14GG[@]:1}")
	TERINT14GG=("${TERINT14GG[@]:1}")

	let MEDIACASI14GG=$((${CASI14GG[@]/%/+}0))/14
	let MEDIADECESSI14GG=$((${DECESSI14GG[@]/%/+}0))/14
	let MEDIARICOVERATI14GG=$((${RICOVERATI14GG[@]/%/+}0))/14
	let MEDIATAMPONI14GG=$((${TAMPONI14GG[@]/%/+}0))/14
	let MEDIATERINT14GG=$((${TERINT14GG[@]/%/+}0))/14

	if (( TAMPONIOGGI <= 0 )); then
		TAMPONIOGGI=0
		RAPPORTO=0
	else
		RAPPORTO=$(/opt/bin/bc -l <<<"$CASI / $TAMPONIOGGI")
		if (( $(/opt/bin/bc -l <<< "$RAPPORTO < 0") )); then
			RAPPORTO=0
		fi
	fi

	#Valori massimi rilevati

	if (( TERINTOGGI > RECORDTERINT )); then
		RECORDTERINT=$TERINTOGGI
	fi

	if (( CASI > RECORDCASI )); then
		RECORDCASI=$CASI
	fi

	if (( TAMPONIOGGI > RECORDTAMPONI )); then
		RECORDTAMPONI=$TAMPONIOGGI
	fi

	if (( DECESSIOGGI > RECORDDECESSI )); then
		RECORDDECESSI=$DECESSIOGGI
	fi

	if (( RICOVERATIOGGI > RECORDRICOVERATI )); then
		RECORDRICOVERATI=$RICOVERATIOGGI
	fi
	echo "$LINE,$RAPPORTO,$TAMPONIOGGI,$DECESSIOGGI,$RECORDTAMPONI,$RECORDCASI,$RECORDDECESSI,$MEDIACASI7GG,$MEDIAVARIAZIONI,$MEDIADECESSI7GG,$MEDIATAMPONI7GG,$MEDIARICOVERATI7GG,$MEDIATERINT7GG,$MEDIATERINT14GG,$MEDIARICOVERATI14GG,$MEDIADECESSI14GG,$MEDIATAMPONI14GG,$MEDIACASI14GG,$RECORDTERINT,$RECORDRICOVERATI" >>"$CSVFILE" 

	DECESSITOTALIIERI=$DECESSITOTALI

done


head -1 $CSVFILE >$CSVFILESHORT
tail -$DAYSAMOUNT $CSVFILE >>$CSVFILESHORT

NOTA=$(tail -1 $TMPCSVFILE | cut -f17- -d"," | sed "s/\"//g")

DATIMENOQUATTRO=$(tail -5 "$CSVFILE" | head -1)
DATIALTROIERI=$(tail -3 "$CSVFILE" | head -1)
DATIIERI=$(tail -2 "$CSVFILE" | head -1)
DATIOGGI=$(tail -1 "$CSVFILE")

DECESSITOTALIALTROIERI=$(echo $DATIALTROIERI | cut -f11 -d",")
TAMPONITOTALIALTROIERI=$(echo $DATIALTROIERI | cut -f15 -d",")

IFS="," read v1 v2 RICOVERATIIERI TERAPIEINTENSIVEIERI v5 v6 TOTALEPOSITIVIIERI v8 CASIIERI v10 DECESSITOTALIIERI v12 v13 v14 TAMPONITOTALIIERI v16 v17 v18 v19 DECESSIIERI RESTO <<<"$DATIIERI"
IFS="," read v1 v2 RICOVERATI     TERAPIEINTENSIVE v5 v6 TOTALEPOSITIVI v8 CASIOGGI DIMESSIGUARITI DECESSITOTALI v12 v13 TOTALECASI TAMPONITOTALI v16 v17 v18 v19 DECESSIOGGI RECORDTAMPONI RECORDCASI RECORDDECESSI MEDIACASI7GG v25 MEDIADECESSI7GG MEDIATAMPONI7GG MEDIARICOVERATI7GG MEDIATERINT7GG MEDIATERINT14GG MEDIARICOVERATI14GG MEDIADECESSI14GG MEDIATAMPONI14GG MEDIACASI14GG RECORDTERINT RECORDRICOVERATI RESTO <<<"$DATIOGGI"

(( TAMPONIIERI = TAMPONITOTALIIERI - TAMPONITOTALIALTROIERI ))
(( TAMPONIOGGI = TAMPONITOTALI - TAMPONITOTALIIERI ))

PERCPOSITIVIIERI=$(echo "$TOTALEPOSITIVIIERI / $POPOLAZIONE * 100" | /opt/bin/bc -l)
PERCPOSITIVI=$(echo "$TOTALEPOSITIVI / $POPOLAZIONE * 100" | /opt/bin/bc -l)

RAPPORTOCASITAMPONIIERI=$(printf "%.2f" $(echo "$CASIIERI / $TAMPONIIERI * 100" | /opt/bin/bc -l))
RAPPORTOCASITAMPONIOGGI=$(printf "%.2f" $(echo "$CASIOGGI / $TAMPONIOGGI * 100" | /opt/bin/bc -l))
RAPPORTOCASITAMPONI7GG=$(printf "%.2f" $(echo "$MEDIACASI7GG / $MEDIATAMPONI7GG * 100" | /opt/bin/bc -l))
RAPPORTOCASITAMPONI14GG=$(printf "%.2f" $(echo "$MEDIACASI14GG / $MEDIATAMPONI14GG * 100" | /opt/bin/bc -l))

DATAULTIMOTMP=$(echo $DATIOGGI | cut -f1 -d"," | sed "s/T/ /g" | sed "s/\"//g")
DATAULTIMO=$(date -d"$DATAULTIMOTMP" +"%d-%m-%Y")

# Rt
#dimessi guariti
ALPHAMENOQUATTRO=$(echo $DATIMENOQUATTRO | cut -f10 -d",") 
#infetti
BETAMENOQUATTRO=$(echo $DATIMENOQUATTRO | cut -f14 -d",") 
#deceduti
GAMMAMENOQUATTRO=$(echo $DATIMENOQUATTRO | cut -f11 -d",") 
ALPHAOGGI=$DIMESSIGUARITI
BETAOGGI=$TOTALECASI
GAMMAOGGI=$DECESSITOTALI

(( ALPHA = ALPHAOGGI - ALPHAMENOQUATTRO ))
(( BETA = BETAOGGI - BETAMENOQUATTRO ))
(( GAMMA = GAMMAOGGI - GAMMAMENOQUATTRO ))
RT=$(echo "$BETA / ( $ALPHA + $GAMMA )" | bc -l)
RT=$(printf "%.2f" $RT)

echo "dati meno quattro: $DATIMENOQUATTRO" >>"$LOGFILE"
echo "dati oggi: $DATIOGGI" >>"$LOGFILE"
echo "alpha meno quattro: $ALPHAMENOQUATTRO" >>"$LOGFILE"
echo "alpha: $ALPHAOGGI" >>"$LOGFILE"
echo "beta meno quattro: $BETAMENOQUATTRO" >>"$LOGFILE"
echo "beta: $BETAOGGI" >>"$LOGFILE"
echo "gamma meno quattro: $GAMMAMENOQUATTRO" >>"$LOGFILE"
echo "gamma: $GAMMAOGGI" >>"$LOGFILE"
echo "RT: $RT"

if [ -z "$REGIONE" ]; then
	cat <<EOF >"$RTHTMLFILE"

<!DOCTYPE html>
<html lang="it">
<head>
<meta name="robots" content="noindex">
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
body {
  font-family: 'Roboto Mono';
  font-size: 10px; 
}
</style>

</head>
<body>
Valore Rt calcolato secondo il <a href="https://sciencecue.it/coronavirus-come-si-calcola-indice-contagiosita-rt/21898/">modello INFN</a><br>
(<b><i>NON</i></b> quello ISS, basato su parametri non a nostra disposizione)<br><br>
Rt = &beta; / ( &alpha; + &gamma; )<br><br>
Con:<br><br>
&alpha; = differenza tra individui <i>guariti</i> all'ultimo rilevamento e quattro giorni prima<br>
&beta; = differenza tra individui <i>contagiati</i> all'ultimo rilevamento e quattro giorni prima<br>
&gamma; = differenza tra individui <i>deceduti</i> all'ultimo rilevamento e quattro giorni prima<br><br>
EOF
	echo "<b>Rt Nazionale: $RT</b><br>" >>"$RTHTMLFILE"
	echo "<br><table><thead><tr><td>Regione</td><td>Rt</td></tr></thead>" >>"$RTHTMLFILE"
	echo >$RTCSVFILE

	/opt/bin/gnuplot -e "filename='/share/Public/bin/covid/out/covid.csv'" /share/Public/bin/covid/covid.gnuplot  >"$IMGFILE" 2>>"$LOGFILE"
	/opt/bin/gnuplot -e "filename='/share/Public/bin/covid/out/covidshort.csv'" /share/Public/bin/covid/covid.gnuplot  >"$IMGFILESHORT" 2>>"$LOGFILE"
else

	echo "$RT,$REGIONE" >>$RTCSVFILE

	GNUPLOTCSVFILE="$REGIONEFORMAT""/covid.csv"
	/opt/bin/gnuplot -e "filename='/share/Public/bin/covid/out/$GNUPLOTCSVFILE" /share/Public/bin/covid/covid.gnuplot  >"$IMGFILE" 2>>"$LOGFILE"
	GNUPLOTCSVFILE="$REGIONEFORMAT""/covidshort.csv"
	/opt/bin/gnuplot -e "filename='/share/Public/bin/covid/out/$GNUPLOTCSVFILE" /share/Public/bin/covid/covid.gnuplot  >"$IMGFILESHORT" 2>>"$LOGFILE"

	/opt/bin/gnuplot "$REGIONEPATH/covidProvince.gnuplot" >"$REGIONEIMGFILE" 2>>"$LOGFILE"
	curl -T "$REGIONEIMGFILE" -u "$CREDENTIALS" "ftp://iltrev.it/" 2>/dev/null

	ls "$REGIONEPATH/province/"*short | while read FILE; do
		NEWFILE=$(echo $FILE | sed "s/short$//g")
		mv "$FILE" "$NEWFILE.csv"
	done
	/opt/bin/gnuplot "$REGIONEPATH/covidProvince.gnuplot" >"$REGIONEIMGFILESHORT" 2>>"$LOGFILE"
	curl -T "$REGIONEIMGFILESHORT" -u "$CREDENTIALS" "ftp://iltrev.it/" 2>/dev/null
fi

curl -T "$IMGFILE" -u "$CREDENTIALS" "ftp://iltrev.it/" 2>/dev/null
curl -T "$IMGFILESHORT" -u "$CREDENTIALS" "ftp://iltrev.it/" 2>/dev/null

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
echo "<link rel=\"shortcut icon\" type=\"image/png\" href=\"https://www.iltrev.it/covid/favicon.png\"/>" >>"$HTMLFILE"
echo "</head>" >>"$HTMLFILE"
echo "<body>" >>"$HTMLFILE"
echo "<p id=\"inizio\"><p>" >>"$HTMLFILE"
echo "<br>Iscriviti al <a href=\"https://t.me/instantcovid\" target="_blank">Canale Telegram</a>" >>"$HTMLFILE"
echo "<br><a href="mailto:instantcovid@iltrev.it">Contattami</a>" >>"$HTMLFILE"
echo "<h3>Situazione COVID-19 - " >>"$HTMLFILE"
echo "<select name=\"forma\" onchange=\"location = this.value;\">" >>"$HTMLFILE"
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
echo "<br><i>(dati del $DATAULTIMO)</i></h3>" >>"$HTMLFILE"

if [ ${#NOTA} -gt 1 ];then
	echo "<p style=\"text-align:center; width: 70%; margin: 0 auto;\"><b>NOTA:</b> $NOTA</p><br>" >>"$HTMLFILE"
fi




echo "<table><thead><tr><th></th><th>Ultimo</th><th>Preced.</th><th>Media<br>7gg</th><th>Media<br>14gg</th><th>Max</th></tr></thead>" >>"$HTMLFILE"
echo "<tbody><tr><td>Tamponi</td><td>$TAMPONIOGGI</td><td>$TAMPONIIERI</td><td>$MEDIATAMPONI7GG</td><td>$MEDIATAMPONI14GG</td><td>$RECORDTAMPONI</td></tr>" >>"$HTMLFILE"
echo "<tr><td>Nuovi casi</td><td class="highlight">$CASIOGGI</td><td>$CASIIERI</td><td>$MEDIACASI7GG</td><td>$MEDIACASI14GG</td><td>$RECORDCASI</td></tr>" >>"$HTMLFILE"
echo "<tr><td>%posit./tamp.</td><td>$RAPPORTOCASITAMPONIOGGI</td><td>$RAPPORTOCASITAMPONIIERI</td><td>$RAPPORTOCASITAMPONI7GG</td><td>$RAPPORTOCASITAMPONI14GG</td><td>n/a</td></tr>" >>"$HTMLFILE"
echo "<tr><td>Decessi</td><td class="highlight">$DECESSIOGGI</td><td>$DECESSIIERI</td><td>$MEDIADECESSI7GG</td><td>$MEDIADECESSI14GG</td><td>$RECORDDECESSI</td></tr>" >>"$HTMLFILE"
echo "<tr><td>Ricoverati</td><td class="highlight">$RICOVERATI</td><td>$RICOVERATIIERI</td><td>$MEDIARICOVERATI7GG</td><td>$MEDIARICOVERATI14GG</td><td>$RECORDRICOVERATI</td></tr>" >>"$HTMLFILE"
echo "<tr><td>Terapie int.<br>(posti: $POSTITERAPIAINTENSIVA)</td><td class="highlight">$TERAPIEINTENSIVE</td><td>$TERAPIEINTENSIVEIERI</td><td>$MEDIATERINT7GG</td><td>$MEDIATERINT14GG</td><td>$RECORDTERINT</td></tr>" >>"$HTMLFILE"
echo "<tr><td>% attualmente<br>positivi<br>($POPOLAZIONE abit.)</td><td>$(printf "%.2f" $PERCPOSITIVI)</td><td>$(printf "%.3f" $PERCPOSITIVIIERI)</td><td>n/a</td><td>n/a</td><td>n/a</td></tr>" >>"$HTMLFILE"
echo "</tbody></table>" >>"$HTMLFILE"

if [ ! -z "$REGIONE" ]; then

	echo "<br>" >>"$HTMLFILE"

	TOTALECASIREGIONE=$(tail -1 "$CSVFILE" | cut -f14 -d",")
	echo "<table><thead><tr><th colspan=\"3\"><b>$TOTALECASIREGIONE</b> casi da inizio pandemia, di cui:</th></tr>" >>"$HTMLFILE"
	echo "<tr><th><b>Provincia</b></th><th><b>Casi</b></th><th><b>% abitanti<br>(totali)</b></th></tr></thead>" >>"$HTMLFILE"

	cat $PROVINCEREGIONECSVFILE | cut -f6 -d"," | sed "s/Fuori Regione \/ Provincia Autonoma/_&/g" | sed "s/In fase di definizione\/aggiornamento/_&/g" | sort | while read PROVINCIA; do
		PROVINCIA=$(echo "$PROVINCIA" | sed "s/_//g")
		TOTALECASIPROVINCIA=$(grep "$PROVINCIA" "$PROVINCEREGIONECSVFILE" | cut -f10 -d",")
		if [ "$TOTALECASIPROVINCIA" != "0" ]; then
			PERCENTO="n/a"

			if [ "$PROVINCIA" = "Fuori Regione / Provincia Autonoma" ]; then
				ABITANTIPROVINCIA=""
				PROVINCIA="Fuori regione"
			elif [ "$PROVINCIA" = "In fase di definizione/aggiornamento" ]; then
				ABITANTIPROVINCIA=""
				PROVINCIA="In aggiornamento"
			else
				ABITANTIPROVINCIA=$(grep "$PROVINCIA" "$MYPATH/province.csv" | cut -f2 -d",")
				PERCENTODEC=$(echo "$TOTALECASIPROVINCIA / $ABITANTIPROVINCIA * 100" | /opt/bin/bc -l)
				PERCENTO=$(printf "%.2f" $PERCENTODEC)
			fi

			echo "<tr><td>$PROVINCIA</td><td><b>$TOTALECASIPROVINCIA</b></td><td>$PERCENTO<br>$ABITANTIPROVINCIA</td></tr>" >>"$HTMLFILE"
		fi
	done

	echo "</table>" >>"$HTMLFILE"
fi

if [ "$REGIONEWEB" = "Italia" ]; then
	echo "<br>Note:<br>" >>"$HTMLFILE"

	tail -21 "$REGIONILATESTFILE" | while read RIGA; do
		NOTA=$(echo "$RIGA" | cut -f21- -d"," | sed '/^[[:space:]]*$/d'  | sed -E 's/[[:space:]]([:,.?!])/\1/g' | sed "s/\"//g")
		if [ "$NOTA" != "" ];then
			REGIONENOTA=$(echo "$RIGA" | cut -f4 -d",")
			echo "<b>$REGIONENOTA</b> - $NOTA<br>" >>"$HTMLFILE"
		fi
	done

	echo "<br>" >>"$HTMLFILE"
fi

echo "<a href=\"#recenti\">Vai a ultimi $DAYSAMOUNT giorni</a><br>" >>"$HTMLFILE"

if [ ! -z "$REGIONEIMGFILE" ]; then
	echo "<p><img style=\"width:100%\" alt=\"Grafico province\" src=\"https://www.iltrev.it/covid/covidProvince$REGIONEFORMAT.svg\"  /></p>" >>"$HTMLFILE"
fi
echo "<p><img style=\"width:100%\" alt=\"Grafici\" src=\"https://www.iltrev.it/covid/covid$REGIONEFORMAT.svg\"  /></p>" >>"$HTMLFILE"

echo "<p id=\"recenti\"><p>" >>"$HTMLFILE"
echo "<a href=\"#inizio\">Torna all'inizio</a><br>" >>"$HTMLFILE"
echo "<h3>Ultimi $DAYSAMOUNT giorni</h3>" >>"$HTMLFILE"
if [ ! -z "$REGIONEIMGFILESHORT" ]; then
	echo "<p><img style=\"width:100%\" alt=\"Grafico province\" src=\"https://www.iltrev.it/covid/covidProvince$REGIONEFORMAT""short.svg\"  /></p>" >>"$HTMLFILE"
fi
echo "<p><img style=\"width:100%\" alt=\"Grafici\" src=\"https://www.iltrev.it/covid/covid$REGIONEFORMAT""short.svg\"  /></p>" >>"$HTMLFILE"

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
	curl -X POST -H 'Content-Type: application/json' -d "{ \"disable_web_page_preview\": \"true\", \"chat_id\": \"@instantcovid\", \"text\": \"Aggiornamento COVID-19\nNuovi Casi: $CASIOGGI ($RAPPORTOCASITAMPONIOGGI%)\nTamponi: $TAMPONIOGGI\nDecessi: $DECESSIOGGI\nRicoverati: $RICOVERATI ($TERAPIEINTENSIVE t.i.)\n\nMaggiori informazioni:\nhttps://www.iltrev.it/covid\" }" https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage 2>&1 | tee -a "$LOGFILE"
	echo "Done Telegram post..: $(date)" >>"$LOGFILE"
fi


# esecuzione di tutto il procedimento tra tutte le regioni
if [ -z "$REGIONE" ]; then
	for REG in "${REGIONI[@]}"; do
		$MYPATH/covid.sh "$REG"
	done

	sort -t "." -n -k1,1 -k2,2 "$RTCSVFILE" | while read LINE; do
		IFS="," read RT REG <<<"$LINE"
		echo "<tr><td>$REG</td><td>$RT</td></tr>" >>"$RTHTMLFILE"
	done

	echo "</table><br>" >>"$RTHTMLFILE"
	echo "<p><h3>Italia</h3><br><img style=\"width:100%\" alt=\"Grafico Rt\" src=\"https://www.iltrev.it/covid/rt.svg\"/></p><br>" >>"$RTHTMLFILE"
	for REG in "${REGIONI[@]}"; do
		REGFORMAT=$(echo "$REG" | sed "s/[^[:alnum:]]//g")
		echo "<p><h3>$REG</h3><br><img style=\"width:100%\" alt=\"Grafico Rt\" src=\"https://www.iltrev.it/covid/$REGFORMAT/rt.svg\"/></p><br>" >>"$RTHTMLFILE"
	done
	echo "</body></html>" >>"$RTHTMLFILE"

	curl -T $RTHTMLFILE -u $CREDENTIALS $WEBPATH 2>/dev/null

	$MYPATH/rt.sh
	/opt/bin/gnuplot -e "filename='$OUTPATH/rtItalia.csv'" $MYPATH/rt.gnuplot >"$RTIMGFILE" 2>/dev/null
	curl -T $RTIMGFILE -u $CREDENTIALS $WEBPATH 2>/dev/null
else
	$MYPATH/rt.sh "$REGIONE"
	/opt/bin/gnuplot -e "filename='$REGIONEPATH/rt.csv'" $MYPATH/rt.gnuplot >"$RTIMGFILE" 2>/dev/null
	curl -T "$RTIMGFILE" -u $CREDENTIALS $WEBPATH 2>/dev/null
fi


echo "$INDENT""End.......: $(date)" >>"$LOGFILE"
