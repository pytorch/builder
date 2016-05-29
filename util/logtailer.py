import requests
import json

api_url = 'https://api.jarvice.com/jarvice'

class LogTailer(object):
  def __init__(self, username, apikey, jobnumber):
    self.lines_printed = 0
    self.jobnumber = jobnumber
    self.username = username
    self.apikey = apikey

  @staticmethod
  def get_last_nonblank_index(target):
    index = len(target) - 1
    while index > 0 and target[index] == '':
      index -= 1
    return index

  def updateFromTail(self):
    res = requests.get('%s/tail?username=%s&apikey=%s&number=%s&lines=10000' % (
      api_url, self.username, self.apikey, self.jobnumber))
    if res.content.decode('utf-8') == '{\n    "error": "Running job is not found"\n}\n':
      return
    full_log = res.content.decode('utf-8').split('\n')
    last_nonblank_line = self.get_last_nonblank_index(full_log)
    full_log = full_log[:last_nonblank_line + 1]
    new_numlines = len(full_log)
    if new_numlines != self.lines_printed:
      print('\n'.join(full_log[self.lines_printed:]))
      self.lines_printed = new_numlines

  def updateFromOutput(self):
    res = requests.get('%s/output?username=%s&apikey=%s&number=%s' % (
      api_url, self.username, self.apikey, self.jobnumber))
    full_log = res.content.decode('utf-8').replace('\r', '').split('\n')
    last_nonblank_line = self.get_last_nonblank_index(full_log)
    full_log = full_log[:last_nonblank_line + 1]
    new_numlines = len(full_log)
    if new_numlines != self.lines_printed:
      print('\n'.join(full_log[self.lines_printed:]))
      self.lines_printed = new_numlines

