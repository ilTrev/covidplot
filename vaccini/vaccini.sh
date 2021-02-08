#!/bin/bash

MYPATH="/share/Public/bin/covid/vaccini"
REPODIR="$MYPATH/covid19-opendata-vaccini"

cd $REPODIR
#git pull
cd ..

HEADER=$(head -1 $REPODIR/dati/consegne-vaccini-latest.csv)

cat "$MYPATH/regioni.csv" | while read REGIONELINE; do
	IFS="," read REGIONE REGIONESHORT <<<"$REGIONELINE"

	echo "$HEADER" > "out/consegne-""$REGIONESHORT"".csv"	

	cat $REPODIR/dati/consegne-vaccini-latest.csv | grep "$REGIONESHORT" | while read CONSEGNELINE; do
		echo $CONSEGNELINE >>"out/consegne-""$REGIONESHORT"".csv"	
	done

	cat $REPODIR/dati/somministrazioni-vaccini-latest.csv | grep "$REGIONESHORT" | while read CONSEGNELINE; do
		echo $CONSEGNELINE >>"out/somministrazioni-""$REGIONESHORT"".csv"	
	done

done
	
