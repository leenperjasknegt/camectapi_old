#!/bin/bash

echo Welcom to Camect API!
echo
echo Creating Camect API Service
systemctl daemon-reload
systemctl stop camectapi 
systemctl stop http_api 
cp camectapi.service /etc/systemd/system/camectapi.service
cp http_api.service /etc/systemd/system/http_api.service
sleep 2
systemctl enable camectapi
systemctl enable http_api
chmod +x default.sh

echo NX server password:
read varnxpassword
if [ -z "$varnxpassword" ]
then
      echo "Nothing changed"
else
sed -i "14c\nxpassword = '$varnxpassword'" camectapi.py
sed -i "14c\nxpasswd = '$varnxpassword'" http_api.py
fi

echo Camect password:
read varcamectpassword
if [ -z "$varcamectpassword" ]
then
      echo "Nothing changed"
else
sed -i "15c\camectpassword = '$varcamectpassword'" camectapi.py
fi

echo Camera ID 1:
read varnxcamid1
if [ -z "$varnxcamid1" ]
then
      echo "Nothing changed"
else
sed -i "18c\cam1id = '$varnxcamid1'" camectapi.py
fi

echo Camera ID 2:
read varnxcamid2
if [ -z "$varnxcamid2" ]
then
      echo "Nothing changed"
else
sed -i "19c\cam2id = '$varnxcamid2'" camectapi.py
fi

echo Camera ID 3:
read varnxcamid3
if [ -z "$varnxcamid3" ]
then
      echo "Nothing changed"
else
sed -i "20c\cam3id = '$varnxcamid3'" camectapi.py
fi

echo Camera ID 4:
read varnxcamid4
if [ -z "$varnxcamid4" ]
then
      echo "Nothing changed"
else
sed -i "21c\cam4id = '$varnxcamid4'" camectapi.py
fi

echo Camera ID 5:
read varnxcamid5
if [ -z "$varnxcamid5" ]
then
      echo "Nothing changed"
else
sed -i "22c\cam5id = '$varnxcamid5'" camectapi.py
fi

echo Camera ID 6:
read varnxcamid6
if [ -z "$varnxcamid6" ]
then
      echo "Nothing changed"
else
sed -i "23c\cam6id = '$varnxcamid6'" camectapi.py
fi

echo Camera ID 7:
read varnxcamid7
if [ -z "$varnxcamid7" ]
then
      echo "Nothing changed"
else
sed -i "24c\cam7id = '$varnxcamid7'" camectapi.py
fi

echo Camera ID 8:
read varnxcamid8
if [ -z "$varnxcamid8" ]
then
      echo "Nothing changed"
else
sed -i "25c\cam8id = '$varnxcamid8'" camectapi.py
fi



echo
echo Starting Camect API

systemctl start camectapi  
systemctl start http_api


echo Setting up NX Witness soft triggers
sleep 5
curl http://localhost:9000/disarm 
curl http://localhost:9000/arm
