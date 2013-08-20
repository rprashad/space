#!bin/python

from bottle import route, run
from pprint import pprint
import json

def import_file(file):
    json_data=open(file)
    data = json.load(json_data)
    json_data.close()
    return data


data = import_file("list.json")

@route('/hello')
def hello():
    return json.dumps(data)

@route('/update/<jdata>')
def update(jdata):
    data = jdata;

run(host='localhost', port=8080, debug=True)
