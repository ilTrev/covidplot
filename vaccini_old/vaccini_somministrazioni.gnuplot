set datafile separator ","

set xdata time 			
set timefmt "%Y-%m-%d"

set format x "%d-%b"

unset key
set style line 100 lt 1 lc rgb "grey" lw .5

set grid y2tics lt 0 lw 0.5 lc rgb "#888888"
set grid xtics lt 0 lw 0.5 lc rgb "#888888"

set style line 1 pointtype 7 pointsize 0.25 linecolor "#000000"
set style line 2 pointtype 7 pointsize 0.25 linecolor "#0000ff"
set style line 3 pointtype 7 pointsize 0.25 linecolor "#00aa00"
set style line 4 pointtype 7 pointsize 0.25 linecolor "#ff0000"
set style line 5 pointtype 7 pointsize 0.25 linecolor "#aaaa00"
set style line 6 pointtype 7 pointsize 0.25 linecolor "#ff00ff"
set style line 7 pointtype 7 linewidth 0.1 pointsize 0.25 linecolor "#000000"
set style line 8 pointtype 7 linewidth 0.1 pointsize 0.25 linecolor "#0000ff"
set style line 9 pointtype 7 pointsize 0.25 linecolor "#00aa00"
set style line 10 pointtype 7 pointsize 0.25 linecolor "#ff0000"
set style line 11 pointtype 7 pointsize 0.25 linecolor "#ff00ff"
set style line 12 pointtype 7 pointsize 0.25 linecolor "#000000"
set style line 13 pointtype 7 pointsize 0.25 linecolor "#0000ff"
set style line 14 pointtype 7 pointsize 0.25 linecolor "#00aa00"
set style line 15 pointtype 7 pointsize 0.25 linecolor "#ff0000"
set style line 16 pointtype 7 pointsize 0.25 linecolor "#aaaa00"
set style line 17 pointtype 7 pointsize 0.25 linecolor "#ff00ff"
set style line 18 pointtype 7 pointsize 0.25 linecolor "#000000"
set style line 19 pointtype 7 pointsize 0.25 linecolor "#0000ff"
set style line 20 pointtype 7 pointsize 0.25 linecolor "#00aa00"
set style line 21 pointtype 7 pointsize 0.25 linecolor "#ff0000"

set terminal svg size 1920,1080 linewidth 1
set title font "Arial,20" 

set title "Vaccini somministrati"
set y2label "Vaccinati"
set y2tics
set y2range [0:*]
unset ytics

plot 'out/somministrazioni_Abruzzo.csv' using 7:2 with linespoints axis x1y2 linestyle 1 title columnhead at end, \
'out/somministrazioni_Basilicata.csv' using 7:2 with linespoints axis x1y2 linestyle 2 title columnhead at end, \
'out/somministrazioni_Calabria.csv' using 7:2 with linespoints axis x1y2 linestyle 3 title columnhead at end, \
'out/somministrazioni_Campania.csv' using 7:2 with linespoints axis x1y2 linestyle 4 title columnhead at end, \
'out/somministrazioni_Emilia-Romagna.csv' using 7:2 with linespoints axis x1y2 linestyle 5 title columnhead at end, \
'out/somministrazioni_Friuli-Venezia Giulia.csv' using 7:2 with linespoints axis x1y2 linestyle 6 title columnhead at end, \
'out/somministrazioni_Lazio.csv' using 7:2 with linespoints axis x1y2 linestyle 7 title columnhead at end, \
'out/somministrazioni_Liguria.csv' using 7:2 with linespoints axis x1y2 linestyle 8 title columnhead at end, \
'out/somministrazioni_Lombardia.csv' using 7:2 with linespoints axis x1y2 linestyle 9 title columnhead at end, \
'out/somministrazioni_Marche.csv' using 7:2 with linespoints axis x1y2 linestyle 10 title columnhead at end, \
'out/somministrazioni_Molise.csv' using 7:2 with linespoints axis x1y2 linestyle 11 title columnhead at end, \
'out/somministrazioni_P.A. Bolzano.csv' using 7:2 with linespoints axis x1y2 linestyle 12 title columnhead at end, \
'out/somministrazioni_P.A. Trento.csv' using 7:2 with linespoints axis x1y2 linestyle 13 title columnhead at end, \
'out/somministrazioni_Piemonte.csv' using 7:2 with linespoints axis x1y2 linestyle 14 title columnhead at end, \
'out/somministrazioni_Puglia.csv' using 7:2 with linespoints axis x1y2 linestyle 15 title columnhead at end, \
'out/somministrazioni_Sardegna.csv' using 7:2 with linespoints axis x1y2 linestyle 16 title columnhead at end, \
'out/somministrazioni_Sicilia.csv' using 7:2 with linespoints axis x1y2 linestyle 17 title columnhead at end, \
'out/somministrazioni_Toscana.csv' using 7:2 with linespoints axis x1y2 linestyle 18 title columnhead at end, \
'out/somministrazioni_Umbria.csv' using 7:2 with linespoints axis x1y2 linestyle 19 title columnhead at end, \
"out/somministrazioni_Valle Aosta.csv" using 7:2 with linespoints axis x1y2 linestyle 20 title columnhead at end, \
'out/somministrazioni_Veneto.csv' using 7:2 with linespoints axis x1y2 linestyle 21 title columnhead at end


