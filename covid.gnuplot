set datafile separator ","

set xdata time 			
set timefmt "%Y-%m-%d"
set format x "%d-%b"

unset key
set style line 100 lt 1 lc rgb "grey" lw .5

set grid y2tics lt 0 lw 0.5 lc rgb "#888888"
set grid ytics lt 0 lw 0.5 lc rgb "#888888"
set grid xtics lt 0 lw 0.5 lc rgb "#888888"

set style line 1 pointtype 7 pointsize 0.25 linecolor "#ff6633"
set style line 2 pointtype 7 pointsize 0.25 linecolor "#33bb44"
set style line 3 pointtype 7 pointsize 0.25 linecolor "#6633ff"
set style line 4 pointtype 7 pointsize 0.25 linecolor "#000000"

set terminal svg size 1600,3200 linewidth 1
set multiplot layout 4,1
set title font "Arial,20" 
#set xrange ["2020-03-01":*]

set y2tics
set title "Tamponi"
set ylabel "Tamponi giorno"
set y2label "Positivi/Tamponi"
set y2range [0:1]
plot filename using 1:19 with linespoints linestyle 1 title columnhead at end, \
           "" using 1:18 with linespoints linestyle 2 axis x1y2 title columnhead at end
set y2range [*:*]

set title "Casi positivi"
set ylabel "Nuovi positivi / variazione totale"
set y2label "Totale positivi"
set key title "N.B.: il totale positivi e la variazione totale positivi sono la differenza tra nuovi casi e decessi/guariti" top left 

plot "" using 1:25 with linespoints linestyle 1 linecolor "#ff6633" title columnhead at end, \
     "" using 1:24 with linespoints linestyle 2 linecolor "#33bb44" title columnhead at end, \
     "" using 1:7  with linespoints linestyle 3 linecolor "#6633ff" axis x1y2 title columnhead at end

unset key
set title "Deceduti"
set y2tics
set ylabel "Totale deceduti"
set y2label "Deceduti giorno"
plot "" using 1:11 with linespoints linestyle 1 title columnhead at end, \
     "" using 1:26 with linespoints linestyle 2 axis x1y2 title columnhead at end

set title "Ricoverati"
set ylabel "Ricoverati - terapie intensive"
set y2label "Dimessi - guariti"
plot "" using 1:3 with linespoints linestyle 1 title columnhead at end, \
     "" using 1:4 with linespoints linestyle 4 title columnhead at end, \
     "" using 1:5 with linespoints linestyle 3 title columnhead at end, \
     "" using 1:10 with linespoints linestyle 2 axis x1y2 title columnhead at end

unset multiplot
