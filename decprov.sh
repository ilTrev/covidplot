cat out/Lombardia/covidProvinceFull.csv | grep -v "Fuori Regione" | grep -v "In aggiornamento" | grep -v "denominazione" | while read RIGA; do
	IFS="," read uno due tre quattro cinque PROVINCIA sette otto nove CASI resto <<<"$RIGA"
	ABITANTI=$(grep "$PROVINCIA" province.csv | cut -f2 -d",")
	echo "$PROVINCIA $ABITANTI $CASI $FORMULA"
done
