1. Download the Camect API folder and place it at /home/administrator, change the name to camect
/home/administrator/camect

Install camectapi: sudo pip3 install camect-py
https://github.com/camect/camect-py

2. Disable HTTPS traffic only in NX Witness server.

3. Visit https://camect.local and accept the terms.
Login: admin
Password: email prefix 
For example service@company.com password = service

4. Change persmissions for the setup.sh file
sudo chmod +x setup.sh

5. Execute setup file
sudo ./setup.sh

6. After the setup the Camect API is ready for use!