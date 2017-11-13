import zipfile
import re
import sys

def unzip(path):
    """
    Unzips /path/to/some.zip to ./some
    Doesn't work with - or _ in 'some'
    """
    match = re.search("(\w+)\.zip", path)
    if match is None:
        print("Could not parse path")
        return

    dest = match.group(1) 
    with zipfile.ZipFile(path, "r") as z:
        z.extractall(dest)

if __name__ == '__main__':
    unzip(sys.argv[1])

