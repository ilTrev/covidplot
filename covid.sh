#!/bin/sh

export LATESTFILE=/tmp/covidLatest.csv
export OLDLATESTFILE=/tmp/covidoldLatest.csv
export JSONFILE=/tmp/covid.json
export OLDJSONFILE=/tmp/covidold.json
export TMPCSVFILE=/tmp/covidtmp.csv
export CSVFILE=/tmp/covid.csv
export IMGFILE=/tmp/covid.svg
export HTMLFILE=/tmp/index.html
export HTMLFILETMP=/tmp/indextmp.html
export LOGFILE=/share/Public/bin/covid/covid.log
export CREDENTIALS="covid@iltrev.it:IlCovid765"

echo "Start: $(date)" >>$LOGFILE

mv $LATESTFILE $OLDLATESTFILE

curl https://raw.githubusercontent.com/pcm-dpc/COVID-19/master/dati-andamento-nazionale/dpc-covid19-ita-andamento-nazionale-latest.csv >$LATESTFILE
diff $LATESTFILE $OLDLATESTFILE
if [ $? -eq 0 ] && [ "$1" != "-f" ]; then
	DATAOGGI=$(date +"%d-%m-%Y - %H:%M")
	cat $HTMLFILE | sed "s/<!-- data -->.*/<!-- data --> $DATAOGGI/g" >>$HTMLFILETMP
	mv $HTMLFILETMP $HTMLFILE
	curl -T $HTMLFILE -u $CREDENTIALS "ftp://iltrev.it/"
	echo "End (noop): $(date)" >>$LOGFILE
	exit
fi

curl https://raw.githubusercontent.com/pcm-dpc/COVID-19/master/dati-andamento-nazionale/dpc-covid19-ita-andamento-nazionale.csv >$TMPCSVFILE

export TAMPONITOTALIIERI=0
export DECESSITOTALIIERI=0
export COUNT=0
export RECORDTAMPONI=0
export RECORDCASI=0
export RECORDDECESSI=0

cat $TMPCSVFILE | while read LINE; do
	if [ $COUNT -eq 0 ]; then
		echo $LINE ",\"positivi/tamponi\",\"tamponi giorno\",\"deceduti giorno\",\"record tamponi\",\"record casi\",\"record decessi\"" | sed "s/_/ /g" >$CSVFILE
		((COUNT+=1))
		continue
	fi

	CASIIERI=$CASI
	CASI=$(echo $LINE | cut -f9 -d",")
	TAMPONITOTALI=$(echo $LINE | cut -f15 -d",")
	TAMPONIIERI=$TAMPONIOGGI
	TAMPONIOGGI=$(echo "$TAMPONITOTALI $TAMPONITOTALIIERI - p" | dc)

	RAPPORTO=$(echo "$CASI $TAMPONIOGGI / p" | dc)

	TAMPONITOTALIIERI=$TAMPONITOTALI

	DECESSITOTALI=$(echo $LINE | cut -f11 -d",")
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

	echo $LINE ",$RAPPORTO,$TAMPONIOGGI,$DECESSIOGGI,$RECORDTAMPONI,$RECORDCASI,$RECORDDECESSI" >>$CSVFILE

	DECESSITOTALIIERI=$DECESSITOTALI

done

DATIALTROIERI=$(tail -3 $CSVFILE | head -1)
DATIIERI=$(tail -2 $CSVFILE | head -1)
DATIOGGI=$(tail -1 $CSVFILE)

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

gnuplot /share/Public/bin/covid/covid.gnuplot  >$IMGFILE 
curl -T $IMGFILE -u $CREDENTIALS "ftp://iltrev.it/"

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
</style>
<title>Covid-19</title>
<link rel="shortcut icon" type="image/png" href="https://www.iltrev.it/covid/favicon.png"/>
</head>
<body>
EOF

echo "<h3><center>Situazione COVID-19 in Italia al" >>$HTMLFILE
echo "<!-- data -->" $(date +"%d-%m-%Y - %H:%M") >>$HTMLFILE
echo "<br><i>(dati del $DATAULTIMO)</i></center></h3>" >>$HTMLFILE
echo "<br>Nuovi tamponi: <b>$TAMPONIOGGI</b> (precedente: $TAMPONIIERI) Record: $RECORDTAMPONI" >>$HTMLFILE
echo "<br>Nuovi casi:    <b>$CASIOGGI - $RAPPORTOCASITAMPONIOGGI%</b> (precedente: $CASIIERI - $RAPPORTOCASITAMPONIIERI%) Record: $RECORDCASI" >>$HTMLFILE
echo "<br>Nuovi decessi: <b>$DECESSIOGGI</b> (precedente: $DECESSIIERI) Record: $RECORDDECESSI" >>$HTMLFILE
echo "<br>Ricoverati:    <b>$RICOVERATI</b> (precedente: $RICOVERATIIERI) Terapie intensive: $TERAPIEINTENSIVE (precedente: $TERAPIEINTENSIVEIERI)" >>$HTMLFILE

cat <<EOF >> $HTMLFILE
<p><img src="https://www.iltrev.it/covid/covid.svg" id="responsive-image" /></p>
Elaborazione dati forniti dal Dipartimento della Protezione Civile (fonte: <a href="https://github.com/pcm-dpc/COVID-19">https://github.com/pcm-dpc/COVID-19</a>)
</body>
</html> 
EOF

curl -T $HTMLFILE -u $CREDENTIALS "ftp://iltrev.it/"
echo "End..: $(date)" >>$LOGFILE
