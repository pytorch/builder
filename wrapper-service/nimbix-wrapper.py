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
import argparse
import logging


logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

script_dir = path.dirname(path.dirname(path.realpath(__file__)))
api_url = 'https://api.jarvice.com/jarvice'

parser = argparse.ArgumentParser()
parser.add_argument('--configfile', default=join(script_dir, 'nimbix.yaml'))
args = parser.parse_args()


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
        commit_hash = request.get('h', None)

        # validation
        client_ip = request.remote_user
        if client_ip not in ['127.0.0.1', wrapper_config['allowed_client_ip']]:  # 127.0.0.1 should be ok...
            raise Exception('client ip doesnt match that in config => ignoring')
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
        instancetype = wrapper_config['instancetype']
        
        # ftp the script to drop host
        scriptPath = '/tmp/~job.sh'
        with open(scriptPath, 'w') as f:
            f.write(wrapper_config['script'])
        scriptName = '~job.sh'
        with pysftp.Connection(drop_host, username=username, password=apikey) as sftp:
            try:
              sftp.mkdir('temp')
            except:
              pass
            sftp.put(scriptPath, "temp/%s" % scriptName)

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
            "command": "bash /data/temp/%s" % scriptName,
            "ephemeral": False,   # this is important: means read/write, and can only launch this image once at a time
            "staging": True,
            "interactive": False,
            "walltime": "0:%s:00" % wrapper_config['max_time_minutes'],
          }
        }

        res = requests.post('%s/submit' % api_url, json=launch_data)
        logger.info(res.status_code, res.content)
        return "OK"
    except Exception as e:
        logger.exception(e)
        return ""

app.run(host='0.0.0.0', port=3237)

