#!/bin/bash

curl -s "https://raw.githubusercontent.com/ondata/covid19italia/master/webservices/vaccini/processing/somministrazioni.csv" | sed "s/Valle d'Aosta/Valle Aosta/g" | sed "s/[0-9]*:[0-9]*:[0-9]*$//g" >out/somministrazioni.csv 

cat regioni.csv | cut -f1 -d"," | while read REGIONE; do 
	echo "Regione,$REGIONE,Percentuale,Dosi consegnate,Data,Codice,Data" >"out/somministrazioni_$REGIONE.csv"
	grep "$REGIONE" out/somministrazioni.csv | sort -t, -u -r -k7 | sort -t, -k7 >>"out/somministrazioni_$REGIONE.csv"

	/opt/bin/gnuplot -e "filename='out/somministrazioni_$REGIONE.csv'" vaccini_dosi.gnuplot >"out/svg/dosi_$REGIONE.svg"
done

/opt/bin/gnuplot vaccini_somministrazioni.gnuplot >out/svg/vaccini_somministrazioni.svg


curl -s "https://raw.githubusercontent.com/ondata/covid19italia/master/webservices/vaccini/processing/fasceEta.csv" >out/fasce_eta_somministrazioni.csv 

cat fasce_eta.csv | while read FASCIAETA; do 
	echo "$FASCIAETA,data" >"out/somministrazioni_fascia_$FASCIAETA.csv"
	grep "$FASCIAETA" out/fasce_eta_somministrazioni.csv | sed "s/[0-9]*:[0-9]*:[0-9]*$//g" | sort -t, -u -r -k4 | sort -t, -k4 | cut -f2,4 -d"," >>"out/somministrazioni_fascia_$FASCIAETA.csv"
done

/opt/bin/gnuplot vaccini_fasceeta.gnuplot >out/svg/vaccini_fasceeta.svg


echo "maschi,femmine,dataAggiornamento" >out/sesso_somministrazioni.csv
curl -s "https://raw.githubusercontent.com/ondata/covid19italia/master/webservices/vaccini/processing/sesso.csv" | tail -n +2 | sed "s/[0-9]*:[0-9]*:[0-9]*$//g" | sort -t, -u -r -k4 | sort -t, -k4 | cut -f1,2,4 -d",">>out/sesso_somministrazioni.csv 
/opt/bin/gnuplot vaccini_sesso.gnuplot >out/svg/vaccini_sesso.svg


ULTIMO=$(tail -1 out/somministrazioni.csv | cut -f5 -d",")
echo "Ultimo rilevamento: $ULTIMO"

