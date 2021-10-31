#!/usr/bin/env python3
"""
Very simple HTTP server in python
Usage::
    ./server.py [<port>]
"""
from http.server import BaseHTTPRequestHandler, HTTPServer
import logging
import os
import requests

nxurl = 'http://localhost:7001/ec2/saveEventRule'
nxuser = 'admin'
nxpasswd = ''

url = nxurl
headers = {'content-type': 'application/json'}
armdata1 = open('/home/administrator/camect/json/inschakelen_disable.json').read()
armdata2 = open('/home/administrator/camect/json/uitschakelen_enable.json').read()
disarmdata1 = open('/home/administrator/camect/json/uitschakelen_disable.json').read()
disarmdata2 = open('/home/administrator/camect/json/inschakelen_enable.json').read()

def armfunction ():
    resp = requests.post(url, data=armdata1, headers=headers, auth=(nxuser, nxpasswd))
    resp = requests.post(url, data=armdata2, headers=headers, auth=(nxuser, nxpasswd)) 

def disarmfunction ():
    resp = requests.post(url, data=disarmdata1, headers=headers, auth=(nxuser, nxpasswd))
    resp = requests.post(url, data=disarmdata2, headers=headers, auth=(nxuser, nxpasswd))





class S(BaseHTTPRequestHandler):
    def _set_response(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

    def do_GET(self):
        logging.info("GET request,\nPath: %s\nHeaders:\n%s\n", str(self.path), str(self.headers))
        self._set_response()
        self.wfile.write("GET request for {}".format(self.path).encode('utf-8'))



#HTTP API
        if self.path == '/arm' :
                print ('ARM')
                os.system("sudo systemctl enable camectapi.service")
                os.system("sudo systemctl start camectapi.service")
                armfunction()
                return

        if self.path == '/disarm' :
                print ('DISARM')
                os.system("sudo systemctl disable camectapi.service")
                os.system("sudo systemctl stop camectapi.service")
                disarmfunction()
                return
##########

    def do_POST(self):
        content_length = int(self.headers['Content-Length']) # <--- Gets the size of data
        post_data = self.rfile.read(content_length) # <--- Gets the data itself
        logging.info("POST request,\nPath: %s\nHeaders:\n%s\n\nBody:\n%s\n",
                str(self.path), str(self.headers), post_data.decode('utf-8'))

        self._set_response()
        self.wfile.write("POST request for {}".format(self.path).encode('utf-8'))

def run(server_class=HTTPServer, handler_class=S, port=8080):
    logging.basicConfig(level=logging.INFO)
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    logging.info('Starting httpd...\n')
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    httpd.server_close()
    logging.info('Stopping httpd...\n')

if __name__ == '__main__':
    from sys import argv

    if len(argv) == 2:
        run(port=int(argv[1]))
    else:
        run()




        