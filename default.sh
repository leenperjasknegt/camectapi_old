#!/bin/bash


read -p "Are you sure to set Camect API to default (y/n)?" choice
case "$choice" in 
  y|Y ) echo "yes";;
  n|N ) exit ;;
  * ) echo "invalid";;
esac


echo Resetting Camect API ...

systemctl stop camectapi
systemctl stop http_api

rm /home/camect/camectapi.py
rm /home/camect/http_api.py

cp /home/camect/default/camectapi.py /home/camect/camectapi.py
cp /home/camect/default/http_api.py /home/camect/http_api.py
echo
echo Done!
