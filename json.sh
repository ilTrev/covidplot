#!/bin/bash
OUTFILE="out/covidtmp.csv"
RIGA=0

FILENAZIONALE="./COVID-19/dati-json/dpc-covid19-ita-andamento-nazionale.json"
TOTRIGHENAZIONALE=$(jq length $FILENAZIONALE)

echo "data,stato,ricoverati_con_sintomi,terapia_intensiva,totale_ospedalizzati,isolamento_domiciliare,totale_positivi,variazione_totale_positivi,nuovi_positivi,dimessi_guariti,deceduti,casi_da_sospetto_diagnostico,casi_da_screening,totale_casi,tamponi,casi_testati,note,ingressi_terapia_intensiva,note_test,note_casi" >./out/coviddajson.csv

while [ $RIGA -lt $TOTRIGHE ]; do
	
	GIORNO=$(cat $FILE | jq ".[$RIGA]")

	read data stato ricoverati_con_sintomi terapia_intensiva totale_ospedalizzati isolamento_domiciliare totale_positivi variazione_totale_positivi nuovi_positivi dimessi_guariti deceduti casi_da_sospetto_diagnostico casi_da_screening totale_casi tamponi casi_testati note ingressi_terapia_intensiva note_test note_casi <<<$(jq -r '.data, .stato, .ricoverati_con_sintomi, .terapia_intensiva, .totale_ospedalizzati, .isolamento_domiciliare, .totale_positivi, .variazione_totale_positivi, .nuovi_positivi, .dimessi_guariti, .deceduti, .casi_da_sospetto_diagnostico, .casi_da_screening, .totale_casi, .tamponi, .casi_testati, .note, .ingressi_terapia_intensiva, .note_test, .note_casi' <<<"$GIORNO")

	note=$(echo "$note" | sed "s/\,//g")
	note_test=$(echo "$note_test" | sed "s/\,//g")
	note_casi=$(echo "$note_casi" | sed "s/\,//g")

	echo "\"$data\",\"$stato\",\"$ricoverati_con_sintomi\",\"$terapia_intensiva\",\"$totale_ospedalizzati\",\"$isolamento_domiciliare\",\"$totale_positivi\",\"$variazione_totale_positivi\",\"$nuovi_positivi\",\"$dimessi_guariti\",\"$deceduti\",\"$casi_da_sospetto_diagnostico\",\"$casi_da_screening\",\"$totale_casi\",\"$tamponi\",\"$casi_testati\",\"$note\",\"$ingressi_terapia_intensiva\",\"$note_test\",\"$note_casi\"" | sed "s/\"null\"//g"

	((RIGA+=1))
done
