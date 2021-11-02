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

rm camectapi.py
rm http_api.py

cp /default/camectapi.py camectapi.py
cp /default/http_api.py http_api.py
echo
echo Done!
