set datafile separator ","

set xdata time 			
set timefmt "%Y-%m-%d %H:%M:%S"

set format x "%d-%b"

unset key
set style line 100 lt 1 lc rgb "grey" lw .5

set grid y2tics lt 0 lw 0.5 lc rgb "#888888"
set grid xtics lt 0 lw 0.5 lc rgb "#888888"

set style line 1 pointtype 7 pointsize 0.25 linecolor "#ff6633"
set style line 2 pointtype 7 pointsize 0.25 linecolor "#33bb44"
set style line 3 pointtype 7 pointsize 0.25 linecolor "#6633ff"
set style line 4 pointtype 7 pointsize 0.25 linecolor "#000000"

set terminal svg size 1920,1080 linewidth 1
set title font "Arial,20" 

set title "Dosi consegnate / percentuale somministrata"
set y2label "Dosi consegnate"
set y2tics
set ylabel "Percentuale somministrata"
set yrange [0:100]
set y2range [0:*]

plot filename using 7:3 with linespoints linestyle 1 title columnhead at end, \
           "" using 7:4 with linespoints axis x1y2 linestyle 1 title columnhead at end
