#!/bin/bash
FILE="./COVID-19/dati-json/dpc-covid19-ita-andamento-nazionale.json"
OUTFILE="out/covidtmp.csv"

TOTRIGHE=$(jq length $FILE)
RIGA=0

echo "data,stato,ricoverati_con_sintomi,terapia_intensiva,totale_ospedalizzati,isolamento_domiciliare,totale_positivi,variazione_totale_positivi,nuovi_positivi,dimessi_guariti,deceduti,casi_da_sospetto_diagnostico,casi_da_screening,totale_casi,tamponi,casi_testati,note" >$OUTFILE

while [ $RIGA -lt $TOTRIGHE ]; do
	GIORNO=$(cat $FILE | jq ".[$RIGA]")
	data=$(echo $GIORNO | jq ".data")
	stato=$(echo $GIORNO | jq ".stato") 
	ricoverati_con_sintomi=$(echo $GIORNO | jq ".ricoverati_con_sintomi")
	terapia_intensiva=$(echo $GIORNO | jq ".terapia_intensiva")
	totale_ospedalizzati=$(echo $GIORNO | jq ".totale_ospedalizzati")
	isolamento_domiciliare=$(echo $GIORNO | jq ".isolamento_domiciliare")
	totale_positivi=$(echo $GIORNO | jq ".totale_positivi")
	variazione_totale_positivi=$(echo $GIORNO | jq ".variazione_totale_positivi")
	nuovi_positivi=$(echo $GIORNO | jq ".nuovi_positivi")
	dimessi_guariti=$(echo $GIORNO | jq ".dimessi_guariti")
	deceduti=$(echo $GIORNO | jq ".deceduti")
	casi_da_sospetto_diagnostico=$(echo $GIORNO | jq ".casi_da_sospetto_diagnostico")
	casi_da_screening=$(echo $GIORNO | jq ".casi_da_screening")
	totale_casi=$(echo $GIORNO | jq ".totale_casi")
	tamponi=$(echo $GIORNO | jq ".tamponi")
	casi_testati=$(echo $GIORNO | jq ".casi_testati")
	note=$(echo $GIORNO | jq ".note")

	echo "$data,$stato,$ricoverati_con_sintomi,$terapia_intensiva,$totale_ospedalizzati,$isolamento_domiciliare,$totale_positivi,$variazione_totale_positivi,$nuovi_positivi,$dimessi_guariti,$deceduti,$casi_da_sospetto_diagnostico,$casi_da_screening,$totale_casi,$tamponi,$casi_testati,$note" | sed "s/null//g"
	((RIGA+=1))
done
