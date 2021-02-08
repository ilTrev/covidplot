set datafile separator ","

set xdata time 			
set timefmt "%Y-%m-%d"

set format x "%d-%b"

unset key
set style line 100 lt 1 lc rgb "grey" lw .5

set grid y2tics lt 0 lw 0.5 lc rgb "#888888"
set grid xtics lt 0 lw 0.5 lc rgb "#888888"

set style line 1 pointtype 7 pointsize 0.25 linecolor "#00aa00"
set style line 2 pointtype 7 pointsize 0.25 linecolor "#0000aa"

set terminal svg size 1920,1080 linewidth 1
set title font "Arial,20" 

set title "Dosi per sesso"
set y2label "Dosi somministrate"
set y2tics
set y2range [0:*]
unset ytics

plot "out/sesso_somministrazioni.csv" using 3:1 with linespoints axis x1y2 linestyle 1 title columnhead at end, \
           "" using 3:2 with linespoints axis x1y2 linestyle 2 title columnhead at end





