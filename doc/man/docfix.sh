for i in $(ls *.sgml)
do
sed -i 's/rsaddclients/rs_addclients/g' $i

sed -i 's/rsaddclients/rs_addclients/g' $i

sed -i 's/rscpimage/rs_cpimage/g' $i

sed -i 's/rsgetimage/rs_getimage/g' $i

sed -i 's/rslsimage/rs_lsimage/g' $i

sed -i 's/rsmkautoinstallcd/rs_mkautoinstallcd/g' $i

sed -i 's/rsmkautoinstallscript/rs_mkautoinstallscript/g' $i

sed -i 's/rsmkbootpackage/rs_mkbootpackage/g' $i

sed -i 's/rsmkbootserver/rs_mkbootserver/g' $i

sed -i 's/rsmkclientnetboot/rs_mkclientnetboot/g' $i

sed -i 's/rsmkdhcpserver/rs_mkdhcpserver/g' $i

sed -i 's/rsmkdhcpstatic/rs_mkdhcpstatic/g' $i

sed -i 's/rsmkrsyncd_conf/rs_mkrsyncd_conf/g' $i

sed -i 's/rsmvimage/rs_mvimage/g' $i

sed -i 's/rsprepareclient/rs_prepareclient/g' $i

sed -i 's/rsprepareclient/rs_prepareclient/g' $i

sed -i 's/rsupdateclient/rs_updateclient/g' $i

sed -i 's/dann@debian.org/william@a9group.net/g' $i
done
