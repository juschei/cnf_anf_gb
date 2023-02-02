for ((startidx=1; startidx<=$1; startidx++))
do
    /usr/bin/sage batch_processor.sage --startidx $startidx
done