# pytorch builder

Scripts to build pytorch binaries and do end-to-end integration tests.

Folders:

- **conda** : files to build conda packages of pytorch, torchvision and other dependencies and repos
- **manywheel** : scripts to build linux wheels
- **wheel** : scripts to build OSX wheels
- **windows** : scripts to build Windows wheels
- **cron** : scripts to drive all of the above scripts across multiple configurations together
- **analytics** : scripts to pull wheel download count from our AWS s3 logs
- **test_community_repos** : scripts that test built binaries with various downstream repos that are high-priority and use pytorch
- **test_imports_docker** : some smoke tests to import torch in combination with other package imports, to check binary stability / compatibility
