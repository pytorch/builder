"""
Thin webservice, that wraps nimbix api, is responsible for knowing the apikey, but can only run very specific scripts in very specific ways.  Its use-case is to reduce the risk that someone spawns a zillion read-only images, running arbitrary scripts.

Jenkins then (for example), can then point at this service, not know the apikey itself.  jenkins security doesnt have to then be quite so fort-knox tight (although, if it has 'push' access to your repos, it should be fairly tight...), since jenkins doesnt then have the power to bankrupt your overnight :-P
"""
from flask import Flask, request
import os
from os import path
from os.path import join
import sys
import yaml
import requests
import json
import argparse
import logging
import pysftp


logging.basicConfig()
logger = logging.getLogger(__name__)
# logger.setLevel(logging.INFO)

script_dir = path.dirname(path.dirname(path.realpath(__file__)))
api_url = 'https://api.jarvice.com/jarvice'
drop_host = 'drop.jarvice.com'

parser = argparse.ArgumentParser()
parser.add_argument('--configfile', default=join(script_dir, 'nimbix.yaml'))
parser.add_argument('--loglevel', default='info')
args = parser.parse_args()

logger.setLevel(logging.__dict__[args.loglevel.upper()])


with open(args.configfile, 'r') as f:
  config = yaml.load(f)

with open(join(script_dir, 'wrapper-service/config.yaml'), 'r') as f:
  wrapper_config = yaml.load(f)

username = config['username']
apikey = config['apikey']
type_by_instance = config.get('type_by_instance', {})


app = Flask(__name__)

@app.route('/run', methods=['POST'])
def run():
    try:
        commit_hash = request.values.get('h', None)
        secret = request.values.get('s', None)

        # validation
        client_ip = request.remote_addr
        if client_ip not in ['127.0.0.1', wrapper_config['allowed_client_ip']]:  # 127.0.0.1 should be ok...
            logger.info('client ip %s config ip %s' % (client_ip, wrapper_config['allowed_client_ip']))
            raise Exception('client ip doesnt match that in config => ignoring')
        if secret != wrapper_config['shared_secret']:
            raise Exception('shared secret not correct, or absent => ignoring')
        if commit_hash is None:
            raise Exception('no commit_hash provided => ignoring')
        commit_hash = str(commit_hash)
        if len(commit_hash) > 40:
            raise Exception('commit_hash exceeds length 40 => ignoring')
        for c in commit_hash:  # probably is a faster way of doing this.  anyway...
            if c not in "abcdef0123456789":
                raise Exception('illegal character found => ignoring')

        # if we got here, we assume validation is ok
        username = config['username']
        apikey = config['apikey']
        image = wrapper_config['image']
        instancetype = wrapper_config['instance_type']
        
        # ftp the script to drop host
        scriptPath = '/tmp/~job.sh'
        with open(scriptPath, 'w') as f:
            f.write(wrapper_config['script'].format(commit_hash=commit_hash))
        scriptName = '~job.sh'
        logger.debug('doing ftp...')
        with pysftp.Connection(drop_host, username=username, password=apikey) as sftp:
            #try:
            #  sftp.mkdir('temp')
            #except Exception as e:
            #  print('exception %s' % str(e))
            #  pass
            sftp.put(scriptPath, "%s" % scriptName)
        logger.debug('... ftp done')

        # start the job...
        launch_data = {
          "machine": {
            "nodes": "1",
            "type": instancetype
          },
          "vault": {
            "readonly": False,
            "force": False,
            "name": "drop.jarvice.com"
          },
          "user": {
            "username": username,
            "apikey": apikey
          },
          "nae": {
            "force": False,
            "name": image,
            "command": "bash /data/%s" % scriptName,
            "ephemeral": False,   # this is important: means read/write, and can only launch this image once at a time
            "staging": True,
            "interactive": False,
            "walltime": "0:%s:00" % wrapper_config['max_time_minutes'],
          }
        }

        logger.debug('launch_data %s' % json.dumps(launch_data))
        res = requests.post('%s/submit' % api_url, json=launch_data)
        logger.info('%s %s' % (res.status_code, res.content))
        return "OK"
    except Exception as e:
        logger.exception(e)
        return ""

app.run(host='0.0.0.0', port=3237)

