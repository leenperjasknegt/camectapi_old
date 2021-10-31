######
# Camect API by JL #


import requests
import time
import datetime
import camect


# NX Witness server
nxip = 'localhost'
nxlogin = 'admin'
nxpassword = ''


# Camera ID's
cam1id = '124da43b-1974-6927-ac35-9dfff8df74fa'
cam2id = '124da43b-1974-6927-ac35-9dfff8df74fa'
cam3id = '124da43b-1974-6927-ac35-9dfff8df74fa'
cam4id = '124da43b-1974-6927-ac35-9dfff8df74fa'
cam5id = '124da43b-1974-6927-ac35-9dfff8df74fa'
cam6id = '124da43b-1974-6927-ac35-9dfff8df74fa'
cam7id = '124da43b-1974-6927-ac35-9dfff8df74fa'
cam8id = '124da43b-1974-6927-ac35-9dfff8df74fa'


# Cameranamen
cam1 = "1"
cam2 = "2"
cam3 = "3"
cam4 = "4"
cam5 = "5"
cam6 = "6"
cam7 = "7"
cam8 = "8"


# HTTP Generic event URL voor NX Witness server
url1 = 'http://' + nxip + ':7001/api/createEvent?caption=cam1&metadata={"cameraRefs":["' + cam1id + '"]}'
url2 = 'http://' + nxip + ':7001/api/createEvent?caption=cam2&metadata={"cameraRefs":["' + cam2id + '"]}'
url3 = 'http://' + nxip + ':7001/api/createEvent?caption=cam3&metadata={"cameraRefs":["' + cam3id + '"]}'
url4 = 'http://' + nxip + ':7001/api/createEvent?caption=cam4&metadata={"cameraRefs":["' + cam4id + '"]}'
url5 = 'http://' + nxip + ':7001/api/createEvent?caption=cam5&metadata={"cameraRefs":["' + cam5id + '"]}'
url6 = 'http://' + nxip + ':7001/api/createEvent?caption=cam6&metadata={"cameraRefs":["' + cam6id + '"]}'
url7 = 'http://' + nxip + ':7001/api/createEvent?caption=cam7&metadata={"cameraRefs":["' + cam7id + '"]}'
url8 = 'http://' + nxip + ':7001/api/createEvent?caption=cam8&metadata={"cameraRefs":["' + cam8id + '"]}'

# Camect HUB Settings
###################
#! Wachtwoord aanpassen !

home = camect.Home("camect.local:443", "admin", "")
home.get_name()
for cam in home.list_cameras():
    print("%s(%s) @%s(%s)" % (cam["name"], cam["make"], cam["ip_addr"], cam["mac_addr"]))

# Alerts enable/disable
#home.enable_alert(["ccaa732ebafa1030d2c8"], "inbraakalarm")


def handle_event(evt):
    print_event(evt)

def print_event(evt):

    if "person" in (evt['detected_obj']) and cam1 in (evt["cam_name"]):
        print ('Cam1 has detected a person')
        r = requests.get(url1, auth=(nxlogin, nxpassword))

    if "person" in (evt['detected_obj']) and cam2 in (evt["cam_name"]):
        print ('Cam2 has detected a person')
        r = requests.get(url1, auth=(nxlogin, nxpassword))

    if "person" in (evt['detected_obj']) and cam3 in (evt["cam_name"]):
        print ('Cam3 has detected a person')
        r = requests.get(url1, auth=(nxlogin, nxpassword))

    if "person" in (evt['detected_obj']) and cam4 in (evt["cam_name"]):
        print ('Cam4 has detected a person')
        r = requests.get(url1, auth=(nxlogin, nxpassword))

    if "person" in (evt['detected_obj']) and cam5 in (evt["cam_name"]):
        print ('Cam4 has detected a person')
        r = requests.get(url1, auth=(nxlogin, nxpassword))

    if "person" in (evt['detected_obj']) and cam6 in (evt["cam_name"]):
        print ('Cam4 has detected a person')
        r = requests.get(url1, auth=(nxlogin, nxpassword))

###################
#! Wachtwoord aanpassen !

if __name__ == '__main__':
    camect.Home(
        'camect.local',
        'admin',
        ''
    ).add_event_listener(
        lambda event: handle_event(event)
    )
    while True:
        # keep running while events trigger
        time.sleep( 5 )