1. Download the Camect API folder and place it at /home/administrator, change the name to camect
/home/administrator/camect

2. Install camectapi: sudo pip3 install camect-py
https://github.com/camect/camect-py

3. (Install curl): sudo apt install curl

4. Disable HTTPS traffic only in NX Witness server.

5. Visit https://camect.local and accept the terms.
Login: admin
Password: email prefix 
For example service@company.com password = service

6. Name the cameras in the Camect HUB accordingly: 1, 2, 3, 4, 5, 6, 7, 8

7. Change persmissions for the setup.sh file
sudo chmod +x setup.sh

8. Execute setup file
sudo ./setup.sh

9. After the setup the Camect API is ready for use!