import jobs
import checkchanges
from os.path import join
from os import path

script_dir = path.dirname(path.realpath(__file__))

jobs = jobs.get_jobs()
print(checkchanges.checkChanges(join(script_dir, 'nimbixinstances.txt'), jobs))

