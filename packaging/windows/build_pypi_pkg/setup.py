import sys
import subprocess

import setuptools.command.install
from setuptools import find_packages, setup
import wheel.bdist_wheel

pkg_name = "torch"
pkg_ver = "{{GENERATE_TORCH_PKG_VER}}"
torch_download_url = "https://download.pytorch.org/whl/torch_stable.html"

python_min_version = (3, 6, 1)
python_min_version_str = '.'.join((str(num) for num in python_min_version))

install_requires = [
    'wheel',
    'numpy',
    'future',
    'typing_extensions',
    'dataclasses; python_version < "3.7"'
]

class install_torch(setuptools.command.install.install):
    def run(self):
        if sys.maxsize.bit_length() == 31:
            raise UserWarning("We don't support Python x86." \
                "Please install Python x64 instead.")

        raise UserWarning(
            f"Can not download torch binary from {torch_download_url}." \
            f"Please visit {torch_download_url} for more details."
        )

class bdist_wheel(wheel.bdist_wheel.bdist_wheel):
    def run(self):
        subprocess.check_call(
            [sys.executable, '-m', 'pip', 'download',
            f'{pkg_name}==={pkg_ver}', '-f', torch_download_url,
            '--platform', 'win_amd64', '--only-binary=:all:',
            '--no-deps', '-d', self.dist_dir])

setup(
    name=pkg_name,
    version=pkg_ver,
    description=("Tensors and Dynamic neural networks in "
                    "Python with strong GPU acceleration"),
    cmdclass={
        'bdist_wheel': bdist_wheel,
        'install': install_torch,
    },
    packages=find_packages(),
    url='https://pytorch.org/',
    download_url='https://github.com/pytorch/pytorch/tags',
    author='PyTorch Team',
    author_email='packages@pytorch.org',
    python_requires='>={}'.format(python_min_version_str),
    install_requires=install_requires,
    # PyPI package information.
    classifiers=[
        'Development Status :: 5 - Production/Stable',
        'Intended Audience :: Developers',
        'Intended Audience :: Education',
        'Intended Audience :: Science/Research',
        'License :: OSI Approved :: BSD License',
        'Topic :: Scientific/Engineering',
        'Topic :: Scientific/Engineering :: Mathematics',
        'Topic :: Scientific/Engineering :: Artificial Intelligence',
        'Topic :: Software Development',
        'Topic :: Software Development :: Libraries',
        'Topic :: Software Development :: Libraries :: Python Modules',
        'Programming Language :: C++',
        'Programming Language :: Python :: 3',
    ],
    license='BSD-3',
    keywords='pytorch machine learning',
)
