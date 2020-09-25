from collections import defaultdict
from datetime import datetime, timedelta, timezone
import gzip
import multiprocessing
import os
import re
import urllib

from tqdm import tqdm
import botocore
import boto3

S3 = boto3.resource('s3')
CLIENT = boto3.client('s3')
BUCKET = S3.Bucket('pytorch')

class CacheEntry:
    _size = None

    def __init__(self, download_uri: str):
        self.download_uri = download_uri
        self.bytes_sent = 0

    @property
    def os_type(self) -> str:
        os_type = "linux"
        if "win" in self.download_uri:
            os_type = "windows"
        elif "macosx" in self.download_uri:
            os_type = "macos"
        return os_type

    @property
    def target_arch(self) -> str:
        target_arch = "cpu"
        result = re.search(r"cu[0-9]+", self.download_uri)
        if result:
            target_arch = result[0]
        return target_arch

    @property
    def package_name(self) -> str:
        filename_contents = os.path.basename(self.download_uri).split('-')
        return filename_contents[0]

    @property
    def package_version(self) -> str:
        if "dev" in self.download_uri:
            results = re.search(
                r"[0-9]+\.[0-9]+\.[0-9]+\.dev[0-9]+",
                self.download_uri
            )
        else:
            results = re.search(
                r"[0-9]+\.[0-9]+\.[0-9]+", self.download_uri
            )
        if not results:
            raise Exception("Wtf there's no version o.O")
        return results[0]

    @property
    def size(self) -> int:
        if self._size is None:
            for key in BUCKET.objects.filter(
                    Prefix=self.download_uri.lstrip("/")
            ):
                self._size = key.size
            if self._size is None:
                raise Exception(
                    f"No object found for prefix {self.download_uri}"
                )
        return self._size

    @property
    def downloads(self):
        return self.bytes_sent // self.size

def parse_logs(log_directory: str) -> dict:
    bytes_cache = dict()
    entries = []
    for (dirpath, _, filenames) in os.walk(log_directory):
        for filename in tqdm(filenames):
            with gzip.open(os.path.join(dirpath, filename), 'r') as gf:
                string = gf.read().decode("utf-8")
                entries += string.splitlines()[2:]
            for entry in entries:
                columns = entry.split('\t')
                bytes_sent = int(columns[3])
                download_uri = urllib.parse.unquote(
                    urllib.parse.unquote(columns[7])
                )
                status = columns[8]
                if not all([
                        status.startswith("2"),
                        download_uri.endswith((".whl", ".zip"))
                ]):
                    continue
                if not bytes_cache.get(download_uri):
                    bytes_cache[download_uri] = CacheEntry(download_uri)
                bytes_cache[download_uri].bytes_sent += bytes_sent
    return bytes_cache

def output_results(bytes_cache: dict) -> None:
    os_results = defaultdict(int)
    arch_results = defaultdict(int)
    package_results = defaultdict(lambda: defaultdict(int))
    for _, val in tqdm(bytes_cache.items()):
        try:
            os_results[val.os_type] += val.downloads
            arch_results[val.target_arch] += val.downloads
            package_results[val.package_name][val.package_version] += (
                val.downloads
            )
        except Exception:
            pass
    print("=-=-= Results =-=-=")
    print("=-=-= OS =-=-=")
    total_os_num = sum(os_results.values())
    for os_type, num in os_results.items():
        print(
            f"\t* {os_type}: {num} ({(num/total_os_num)*100:.2f}%)"
        )

    print("=-=-= ARCH =-=-=")
    total_arch_num = sum(arch_results.values())
    for arch_type, num in arch_results.items():
        print(
            f"\t* {arch_type}: {num} ({(num/total_arch_num) * 100:.2f}%)"
        )

    print("=-=-= By Package =-=-=")
    for package_name, upper_val in package_results.items():
        print(f"=-=-= {package_name} =-=-=")
        total_package_num = sum(upper_val.values())
        for package_version, num in upper_val.items():
            print(
                f"\t* {package_version}: {num} ({(num/total_package_num) * 100:.2f}%)"
            )

def download_logs(log_directory: str, since: float):
    dt_now = datetime.now(timezone.utc)
    dt_end = datetime(dt_now.year, dt_now.month, dt_now.day, tzinfo=timezone.utc)
    dt_start = dt_end - timedelta(days=1, hours=1) # Add 1 hour padding to account for potentially missed logs due to timing 
    for key in tqdm(BUCKET.objects.filter(Prefix='cflogs')):
        remote_fname = key.key
        local_fname = os.path.join(log_directory, remote_fname)
        # Only download things from yesterday
        dt_modified = key.last_modified.replace(tzinfo=timezone.utc)
        if dt_start >= dt_modified or dt_end < dt_modified:
            continue
        # TODO: Do this in parallel
        if not os.path.exists(local_fname):
            dirname = os.path.dirname(local_fname)
            if not os.path.exists(dirname):
                os.makedirs(dirname)
            CLIENT.download_file("pytorch", remote_fname, local_fname)


if __name__ == "__main__":
    print("Downloading logs")
    download_logs('cache', 1)
    print("Parsing logs")
    cache = parse_logs('cache/cflogs/')
    print("Calculating results")
    output_results(cache)
