set datafile separator ","

set xdata time 			
set timefmt "%Y-%m-%d"
set format x "%d-%m-%y"
unset ytics
set y2tics

set style line 1 pointtype 7 pointsize 0.35 linecolor "#6633ff"

set grid x y2

set terminal svg size 1920,720 linewidth 1

plot "out/consegne-LOM.csv" using 4:3 with linespoints linestyle 1 axis x1y2
