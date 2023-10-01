# Pytorch builder

The pytorch builder repository provides scripts to allow you to build your own pytorch binaries as well as utilize end-to-end integration testing. The included build files are provided for Linux and Windows specifically. The files use the python manager Conda in order to build the Pytorch packages, other dependencies, and used repositories. Wheel files are the used package format for build files and scripts are included in the folders in order to build them.

# Pytorch Installation

Pytorch must be installed in order to use the scripts. You can follow the Pytorch installation guide [here.](https://pytorch.org/get-started/locally/) It will require the installation of a package manager for Pytorch binaries, either Anaconda or pip. Once you have a manager and Pytorch installed, you can start using the scripts to create your own libraries. If you're unfamilar with Pytorch, its implementations, or building your own Pytorch binary, the documenation for Pytorch is avaiable [here](https://pytorch.org/docs/stable/index.html) and an example of building a C library can be found [here.](https://www.cs.swarthmore.edu/~newhall/unixhelp/howto_C_libraries.html)

# Building A Binary

In order to build your own binary model for Pytorch, you will need to have created your model and functions beforehand. Once you have your model complete, you can use any of the batch files to compile your files into a usable Pytorch library. The shell scripts and batch files to build your wheel files are divided into specific folders below. You can run any of scripts you need by specifically typing in the name of the file in your command line. The files will automatically compile into a usable Pytorch binary.

### NOTE: The documenation for many of the batch files inside the dedicated folders is not fully complete. Please use the batch and shell files with care.

# Folders

- **conda** : files to build conda packages of pytorch, torchvision and other dependencies and repos
- **manywheel** : scripts to build linux wheels
- **wheel** : scripts to build OSX wheels
- **windows** : scripts to build Windows wheels
- **cron** : scripts to drive all of the above scripts across multiple configurations together
- **analytics** : scripts to pull wheel download count from our AWS s3 logs

## Testing

In order to test build triggered by PyTorch repo's GitHub actions see [these instructions](https://github.com/pytorch/pytorch/blob/master/.github/scripts/README.md#testing-pytorchbuilder-changes)
