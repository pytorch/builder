# pytorch builder

**WARNING**: Builder repository is migrated to pytorch/pytorch and pytorch/test-infra repositories. Please note: If you intend to add or modify PyTorch build or test scripts please do it directly in pytorch/pytorch repository. Consult following issue for details: https://github.com/pytorch/builder/issues/2054 

Scripts to build pytorch binaries and do end-to-end integration tests.

Folders:

- **conda** : files to build conda packages of pytorch, torchvision and other dependencies and repos
- **manywheel** : scripts to build linux wheels
- **wheel** : scripts to build OSX wheels
- **windows** : scripts to build Windows wheels
- **cron** : scripts to drive all of the above scripts across multiple configurations together
- **analytics** : scripts to pull wheel download count from our AWS s3 logs

## Testing

In order to test build triggered by PyTorch repo's GitHub actions see [these instructions](https://github.com/pytorch/pytorch/blob/master/.github/scripts/README.md#testing-pytorchbuilder-changes)
