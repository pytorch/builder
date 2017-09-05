import botocore
import boto3
import os
from os import walk
from tqdm import tqdm
import gzip

if not os.path.exists('cache'):
    os.makedirs('cache')

s3 = boto3.resource('s3')
client = boto3.client('s3')
bucket = s3.Bucket('pytorch')

print('Downloading log files')
for key in tqdm(bucket.objects.filter(Prefix='cflogs')):
    # print(key.key)
    remote_fname = key.key
    local_fname = os.path.join('cache', remote_fname)
    if not os.path.exists(local_fname):
        dirname = os.path.dirname(local_fname)
        if not os.path.exists(dirname):
            os.makedirs(dirname)
        client.download_file("pytorch", remote_fname, local_fname)


size_cache = dict()
def get_size(name):
    if name[0] == '/':
        name = name[1:]
    if name not in size_cache:
        for key in bucket.objects.filter(Prefix=name):
            size_cache[name] = key.size

    return size_cache[name]

valid_cache = dict()
def is_valid(name):
    if name not in valid_cache:
        exists = False
        try:
            s3.Object('pytorch', name).load()
        except botocore.exceptions.ClientError as e:
            if e.response['Error']['Code'] == "404":
                exists = False
            else:
                raise
        else:
            exists = True
        valid_cache[name] = exists
    return valid_cache[name]

# parse all files, read each line, add up all the bytes sizes
print('parsing log files')
bytes_cache = dict()
for (dirpath, dirnames, filenames) in walk('cache/cflogs/'):
    for filename in tqdm(filenames):
        f = gzip.open(os.path.join(dirpath, filename), 'r')
        string = f.read().decode("utf-8")
        f.close()
        entries = string.splitlines()[2:]
        for entry in entries:
            columns = entry.split('\t')
            filename = columns[7]
            if filename[0] == '/':
                filename = filename[1:]
            bytes_sent = columns[3]
            if filename not in bytes_cache:
                bytes_cache[filename] = 0
            bytes_cache[filename] += int(bytes_sent)

print('Filtering invalid entries')
final_list = dict()
for k, v in tqdm(bytes_cache.items()):
    if '.whl' in k and is_valid(k):
        final_list[k] = v

print('Counting downloads (bytes sent / filesize)')
total_downloads = 0
for k, v in final_list.items():
    sz = get_size(k)
    downloads = v / sz
    print(k, round(downloads))
    total_downloads += downloads

print('')
print('')
print('Total PyTorch wheel downloads: ', round(total_downloads))
print('')
print('')
