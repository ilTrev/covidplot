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

set terminal svg size 1920,1080 linewidth 1
set title font "Arial,20" 

set title "Vaccini somministrati per fasce di età"
set y2label "Dosi"
set y2tics
set y2range [0:*]
unset ytics

plot 'out/somministrazioni_fascia_16-19.csv' using 2:1 with linespoints axis x1y2 linestyle 1 title columnhead at end, \
'out/somministrazioni_fascia_20-29.csv' using 2:1 with linespoints axis x1y2 linestyle 2 title columnhead at end, \
'out/somministrazioni_fascia_30-39.csv' using 2:1 with linespoints axis x1y2 linestyle 3 title columnhead at end, \
'out/somministrazioni_fascia_40-49.csv' using 2:1 with linespoints axis x1y2 linestyle 4 title columnhead at end, \
'out/somministrazioni_fascia_50-59.csv' using 2:1 with linespoints axis x1y2 linestyle 5 title columnhead at end, \
'out/somministrazioni_fascia_60-69.csv' using 2:1 with linespoints axis x1y2 linestyle 6 title columnhead at end, \
'out/somministrazioni_fascia_70-79.csv' using 2:1 with linespoints axis x1y2 linestyle 7 title columnhead at end, \
'out/somministrazioni_fascia_80-89.csv' using 2:1 with linespoints axis x1y2 linestyle 8 title columnhead at end, \
'out/somministrazioni_fascia_90+.csv' using 2:1 with linespoints axis x1y2 linestyle 9 title columnhead at end


