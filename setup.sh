#!/bin/bash

echo Welcom to Camect API!
echo
echo Do not forget to turn off HTTPS traffic only in NX Witness server!
echo Do not forget to accept the terms at https://camect.local
ecgi
echo Creating Camect API Service
systemctl stop camectapi 
systemctl stop http_api 
cp /home/administrator/camect/camectapi.service /etc/systemd/system/camectapi.service
cp /home/administrator/camect/http_api.service /etc/systemd/system/http_api.service
systemctl daemon-reload
systemctl enable camectapi
systemctl enable http_api


echo NX server password:
if [ -z "$varnxpassword" ]
then
      echo "Nothing changed"
else
sed -i "18c\nxpassword = '$varnxpassword'" /home/administrator/camect/camectapi.py
sed -i "14c\nxpasswd = '$varnxpassword'" /home/administrator/camect/http_api.py
fi

echo Camect password:
if [ -z "$varcamectpassword" ]
then
      echo "Nothing changed"
else
sed -i "53c\home = camect.Home("camect.local:443", "admin", "$varnxpassword")" /home/administrator/camect/camectapi.py
sed -i "98c\        '$varnxpassword'" /home/administrator/camect/camectapi.py
fi

echo Camera ID 1:
if [ -z "$varnxcamid1" ]
then
      echo "Nothing changed"
else
sed -i "18c\cam1id = '$varnxcamid1'" /home/administrator/camect/camectapi.py
fi

echo Camera ID 2:
if [ -z "$varnxcamid2" ]
then
      echo "Nothing changed"
else
sed -i "19c\cam2id = '$varnxcamid2'" /home/administrator/camect/camectapi.py
fi

echo Camera ID 3:
if [ -z "$varnxcamid3" ]
then
      echo "Nothing changed"
else
sed -i "20c\cam3id = '$varnxcamid3'" /home/administrator/camect/camectapi.py
fi

echo Camera ID 4:
if [ -z "$varnxcamid4" ]
then
      echo "Nothing changed"
else
sed -i "21c\cam4id = '$varnxcamid4'" /home/administrator/camect/camectapi.py
fi

echo Camera ID 5:
if [ -z "$varnxcamid5" ]
then
      echo "Nothing changed"
else
sed -i "22c\cam5id = '$varnxcamid5'" /home/administrator/camect/camectapi.py
fi

echo Camera ID 6:
if [ -z "$varnxcamid6" ]
then
      echo "Nothing changed"
else
sed -i "23c\cam6id = '$varnxcamid6'" /home/administrator/camect/camectapi.py
fi

echo Camera ID 7:
if [ -z "$varnxcamid7" ]
then
      echo "Nothing changed"
else
sed -i "24c\cam7id = '$varnxcamid7'" /home/administrator/camect/camectapi.py
fi

echo Camera ID 8:
if [ -z "$varnxcamid8" ]
then
      echo "Nothing changed"
else
sed -i "25c\cam8id = '$varnxcamid8'" /home/administrator/camect/camectapi.py
fi



echo
echo Starting Camect API


systemctl start camectapi  
systemctl start http_api

echo Setting up NX Witness soft triggers

curl http://localhost:9000/disarm 
curl http://localhost:9000/arm
