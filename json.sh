#!/bin/bash
OUTFILE="out/covidtmp.csv"
RIGA=0

if [ $# -eq 0 ]; then
	FILE="./COVID-19/dati-json/dpc-covid19-ita-andamento-nazionale.json"
else
	FILE="./COVID-19/dati-json/dpc-covid19-ita-regioni.json"
fi

TOTRIGHE=$(jq length $FILE)

if [ $# -eq 0 ]; then
	echo "data,stato,ricoverati_con_sintomi,terapia_intensiva,totale_ospedalizzati,isolamento_domiciliare,totale_positivi,variazione_totale_positivi,nuovi_positivi,dimessi_guariti,deceduti,casi_da_sospetto_diagnostico,casi_da_screening,totale_casi,tamponi,casi_testati,note"
else
	echo "data,stato,denominazione_regione,ricoverati_con_sintomi,terapia_intensiva,totale_ospedalizzati,isolamento_domiciliare,totale_positivi,variazione_totale_positivi,nuovi_positivi,dimessi_guariti,deceduti,casi_da_sospetto_diagnostico,casi_da_screening,totale_casi,tamponi,casi_testati,note"
fi

while [ $RIGA -lt $TOTRIGHE ]; do
	GIORNO=$(cat $FILE | jq ".[$RIGA]")
	#echo $GIORNO | jq -r '.data, .stato, .ricoverati_con_sintomi, .terapia_intensiva' | read data stato ricoverati_con_sintomi terapia_intensiva
	read data stato ricoverati_con_sintomi terapia_intensiva < <(echo $(echo $GIORNO | jq -r '.data, .stato, .ricoverati_con_sintomi, .terapia_intensiva'))


	#data=$(jq ".data" <<<$GIORNO)
	#stato=$( jq ".stato" <<<$GIORNO) 
	#ricoverati_con_sintomi=$( jq ".ricoverati_con_sintomi" <<<$GIORNO)
	#terapia_intensiva=$( jq ".terapia_intensiva" <<<$GIORNO)
	totale_ospedalizzati=$( jq ".totale_ospedalizzati" <<<$GIORNO)
	isolamento_domiciliare=$( jq ".isolamento_domiciliare" <<<$GIORNO)
	totale_positivi=$( jq ".totale_positivi" <<<$GIORNO)
	variazione_totale_positivi=$( jq ".variazione_totale_positivi" <<<$GIORNO)
	nuovi_positivi=$( jq ".nuovi_positivi" <<<$GIORNO)
	dimessi_guariti=$( jq ".dimessi_guariti" <<<$GIORNO)
	deceduti=$( jq ".deceduti" <<<$GIORNO)
	casi_da_sospetto_diagnostico=$( jq ".casi_da_sospetto_diagnostico" <<<$GIORNO)
	casi_da_screening=$( jq ".casi_da_screening" <<<$GIORNO)
	totale_casi=$( jq ".totale_casi" <<<$GIORNO)
	tamponi=$( jq ".tamponi" <<<$GIORNO)
	casi_testati=$( jq ".casi_testati" <<<$GIORNO)
	note=$( jq ".note" <<<$GIORNO)

	if [ $# != 0 ]; then
		denominazione_regione=$( jq ".denominazione_regione" <<<$GIORNO | sed "s/\"//g")
		echo "$data,$stato,$denominazione_regione,$ricoverati_con_sintomi,$terapia_intensiva,$totale_ospedalizzati,$isolamento_domiciliare,$totale_positivi,$variazione_totale_positivi,$nuovi_positivi,$dimessi_guariti,$deceduti,$casi_da_sospetto_diagnostico,$casi_da_screening,$totale_casi,$tamponi,$casi_testati,$note" | sed "s/null//g"
	else
		echo "$data,$stato,$ricoverati_con_sintomi,$terapia_intensiva,$totale_ospedalizzati,$isolamento_domiciliare,$totale_positivi,$variazione_totale_positivi,$nuovi_positivi,$dimessi_guariti,$deceduti,$casi_da_sospetto_diagnostico,$casi_da_screening,$totale_casi,$tamponi,$casi_testati,$note" | sed "s/null//g"
	fi

	((RIGA+=1))
done
