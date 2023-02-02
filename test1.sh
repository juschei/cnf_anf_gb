for ((jobidx=1; jobidx<=$1; jobidx++))
do
    /usr/bin/sage worker.sage --nr $jobidx
done