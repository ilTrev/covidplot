set datafile separator ","

set xdata time 			
set timefmt "%Y-%m-%dT%H:%M"
set format x "%d-%b"

set y2range [0:20]
set y2tics mirror 0,1,20

unset key
set style line 1 pointtype 7 pointsize 0.35 linecolor "#6633ff"

set grid x y2

set terminal svg size 1920,720 linewidth 1
unset title

plot filename using 1:2 with linespoints linestyle 1 axis x1y2
