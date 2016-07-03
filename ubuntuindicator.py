# based on https://bitbucket.org/cpbotha/indicator-cpuspeed/src

# work in progress...

# to run it, you'll need to, after installgin your env3 virtualenv:
# pushd env3/lib/python3.5/site-packages
# ln -s /usr/lib/python3/dist-packages/gi/ .
# popd

from __future__ import print_function, division
from os import path
from os.path import join
import os.path
import traceback
import yaml
import sys
import argparse
import requests
import json
import subprocess
from gi.repository import Gtk, GLib

try: 
       from gi.repository import AppIndicator3 as AppIndicator  
except:  
       from gi.repository import AppIndicator

import re
import jobs
import launch

script_dir = path.dirname(path.realpath(__file__))
api_url = 'https://api.jarvice.com/jarvice'

parser = argparse.ArgumentParser()
parser.add_argument('--configfile', default=join(script_dir, 'nimbix.yaml'))
parser.add_argument('--iconfile')
args = parser.parse_args()
with open(args.configfile, 'r') as f:
  config = yaml.load(f)

username = config['username']
apikey = config['apikey']
ssh_command = config['ssh_command']
type_by_instance = config.get('type_by_instance', {})

class IndicatorCPUSpeed(object):
    def __init__(self):
        # param1: identifier of this indicator
        # param2: name of icon. this will be searched for in the standard them
        # dirs
        # finally, the category. We're monitoring CPUs, so HARDWARE.
        self.ind = AppIndicator.Indicator.new(
                            "indicator-cpuspeed", 
                            "onboard-mono",
                            AppIndicator.IndicatorCategory.HARDWARE)
        if args.iconfile is not None:
            theme_path = path.dirname(args.iconfile)
            icon = path.basename(args.iconfile).split('.')[0]
            print('theme_path', theme_path, 'icon', icon)
            self.ind.set_icon_theme_path(theme_path)
            self.ind.set_icon(icon)
            
#        self.ind.set_icon_theme_path(join(script_dir, 'img'))
#        self.ind.set_icon('nimbix')

        # some more information about the AppIndicator:
        # http://developer.ubuntu.com/api/ubuntu-12.04/python/AppIndicator3-0.1.html
        # http://developer.ubuntu.com/resources/technologies/application-indicators/

        # need to set this for indicator to be shown
        self.ind.set_status (AppIndicator.IndicatorStatus.ACTIVE)

        # have to give indicator a menu
        self.menu = Gtk.Menu()

        # you can use this menu item for experimenting
        item = Gtk.MenuItem()
        item.set_label("Poll")
        item.connect("activate", self.handler_menu_test)
        item.show()
        self.menu.append(item)

        # this is for exiting the app
        item = Gtk.MenuItem()
        item.set_label("Exit")
        item.connect("activate", self.handler_menu_exit)
        item.show()
        self.menu.append(item)

        for image, instancetype in type_by_instance.items():
            item = Gtk.MenuItem()
            item.set_label("Launch %s" % image)
            item.target_image = image
            item.target_type = instancetype
            item.connect("activate", self.handler_instance_launch)
            item.show()
            self.menu.insert(item, 0)

        self.menu.show()
        self.ind.set_menu(self.menu)

        # initialize cpu speed display
        self.instance_items = []
        self.update_cpu_speeds()
        # then start updating every 2 seconds
        # http://developer.gnome.org/pygobject/stable/glib-functions.html#function-glib--timeout-add-seconds
        GLib.timeout_add_seconds(180, self.handler_timeout)
        
    def handler_poll_onetime(self):
       self.update_cpu_speeds()
       return False

    def handler_menu_exit(self, evt):
        Gtk.main_quit()

    def handler_menu_test(self, evt):
        # we can change the icon at any time
#        self.ind.set_icon("indicator-messages-new")
        self.update_cpu_speeds()

    def handler_timeout(self):
        """This will be called every few seconds by the GLib.timeout.
        """
        self.update_cpu_speeds()
        # return True so that we get called again
        # returning False will make the timeout stop
        return True

    def handler_instance_launch(self, evt):
        self.instance_launch(evt.target_image, evt.target_type)

    def handler_instance_ssh(self, evt):
        self.instance_ssh(evt.job_number, evt.target_image)

    def handler_instance_kill(self, evt):
        self.instance_kill(evt.job_number, evt.target_image)

    def instance_launch(self, image, instancetype):
        launch.launch(config, image, instancetype)
        GLib.timeout_add_seconds(10, self.handler_poll_onetime)

    def instance_ssh(self, job_number, target_image):
        res = requests.get('%s/connect?username=%s&apikey=%s&number=%s' % (api_url, username, apikey, job_number))
        res = json.loads(res.content.decode('utf-8'))
        ip_address = res['address']
        subprocess.Popen(ssh_command.format(
            ip_address=ip_address,
            image=target_image
        ).split())

    def instance_kill(self, job_number, target_image):
        res = requests.get('%s/shutdown?username=%s&apikey=%s&number=%s' % (api_url, username, apikey, job_number))
        res = json.loads(res.content.decode('utf-8'))
        GLib.timeout_add_seconds(10, self.handler_poll_onetime)

    def update_cpu_speeds(self):
        label = 'failed'
        try:
            jobslist = jobs.get_jobs(config)
            label = ''
            for item in self.instance_items:
                self.menu.remove(item)
            self.instance_items.clear()
            for job in jobslist:
                if label != '':
                     label += ' '
                label += job['type']

                item = Gtk.MenuItem()
                item.set_label('ssh to %s' % job['image'])
                item.connect("activate", self.handler_instance_ssh)
                item.target_image = job['image']
                item.job_number = job['number']
                item.show()
                self.menu.insert(item, 0)
                self.instance_items.append(item)

                item = Gtk.MenuItem()
                item.set_label('kill %s' % job['image'])
                item.connect("activate", self.handler_instance_kill)
                item.target_image = job['image']
                item.job_number = job['number']
                item.show()
                self.menu.insert(item, 0)
                self.instance_items.append(item)

        except Exception as e:
            label = 'exception occurred'
            try:
                print(traceback.format_exc())
            except:
                print('exception in exception :-P')
        self.ind.set_label(label, "")

    def main(self):
        Gtk.main()

if __name__ == "__main__":
    ind = IndicatorCPUSpeed()
    ind.main()

