set datafile separator ","

set key left
set xdata time 			
set timefmt "%Y-%m-%dT%H:%M"
set format x "%d-%b"
set key autotitle columnhead

set style line 100 lt 1 lc rgb "grey" lw .5
set grid ls 100 
set style line 101 lt 1 lw 2

set terminal svg size 1600,3700 linewidth 1
set multiplot layout 4,1
set title font "Arial,20" 

set y2tics
set title "Tamponi"
set ylabel "Tamponi giorno"
set y2label "Positivi / Tamponi"
plot "/tmp/covid.csv" using 1:19 with lines, "/tmp/covid.csv" using 1:18 with lines  axis x1y2

set title "Casi positivi"
set ylabel "Nuovi positivi / variazione totale"
set y2label "Totale positivi"
plot "/tmp/covid.csv" using 1:8 with lines, "/tmp/covid.csv" using 1:9 with lines,  "/tmp/covid.csv" using 1:7 with lines axis x1y2

set title "Deceduti"
set y2tics
set ylabel "Totale deceduti"
set y2label "Deceduti giorno"
plot "/tmp/covid.csv" using 1:11 with lines, "/tmp/covid.csv" using 1:20 with lines axis x1y2

unset y2tics

set title "Ricoverati"
set ylabel "Ricoverati / terapie intensive"
set y2label "Dimessi / guariti"
plot "/tmp/covid.csv" using 1:3 with lines, "/tmp/covid.csv" using 1:4 with lines, "/tmp/covid.csv" using 1:5 with lines, "/tmp/covid.csv" using 1:10 with lines axis x1y2

unset multiplot
