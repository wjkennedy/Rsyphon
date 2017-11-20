for file in $(ack -l rs_yphon)
do
	sed -i 's/rs_yphon/rsyphon/g' $i
	echo $i
done

for file in $(ack -l rs_yphon)
do
	sed -i 's/rs_yncd/rsyncd/g' $i
	echo $i
done
