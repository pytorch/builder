# Python Upgrade Runbook

So you wanna upgrade PyTorch to support a new Python? Follow these steps in order! They are adapted from previous CUDA upgrade processes.

### 0.Before starting upgrade process. Check the package availability

Package availability to validate before starting upgrade process :

1) Python package is available via python ftp [here](https://www.python.org/ftp/python/) - This is minimal requirement for all wheel builds

2) Python package is available via anaconda [here](https://anaconda.org/anaconda/python/files) - This is required for conda builds

## 1. Maintain Progress and Updates
Make an issue to track the progress, for example CUDA issue [#56721: Support 11.3](https://github.com/pytorch/pytorch/issues/56721). This is especially important as many PyTorch external users are interested in Pytorch upgrades.

## 2. Modify scripts to install the new Python for Docker Manywheel images.

1. Follow this [PR 1427](https://github.com/pytorch/builder/pull/1427) with followup [PR 1568](https://github.com/pytorch/builder/pull/1568) for all steps in this section
2. Validate that Build manywheel docker images is successful [here](https://github.com/pytorch/builder/blob/main/.github/workflows/build-manywheel-images.yml)

## 3. Modify scripts to install the new Python for Core nightyly Manywheel and Conda builds.

1. Builder PRs: Follow this [PR 1586](https://github.com/pytorch/builder/pull/1586) and [PR 1593](https://github.com/pytorch/builder/pull/1593)
2. Pytorch PRs: [PR 112882](https://github.com/pytorch/pytorch/pull/112882)
3. Builder PR and Pytorch PR need to be tested togeather. After landing initiate nightly build and make sure nightly build is successful via [HUD](https://hud2.pytorch.org/hud/pytorch/pytorch/nightly/1?per_page=50)

## 4. Land Test-Infra PRs and make sure nighly domains builds are successful

1. Test-Infra PRs:  [PR 4768](https://github.com/pytorch/test-infra/pull/4768), [PR 4843](https://github.com/pytorch/test-infra/pull/4843)
2. After landing it, intiate domain nightly builds and fix all follow up issues. Example vision [PR 8137](https://github.com/pytorch/vision/pull/8137)
3. At this point we should have complete set of nightly builds for pytorch, vision and audio. Please validate nightly binaries with [validate-binaries workflow](https://github.com/pytorch/builder/actions/workflows/validate-binaries.yml) to make sure smoke tests are passing for Python 3.12

## 5. Add support for new Pythron to CI

1. Pytorch PR: [PR 117853](https://github.com/pytorch/pytorch/pull/117853)
2. Please note, for any failures that can't be resolved easily, we ned to create new issue, and follow up on it similar to this [example](https://github.com/pytorch/pytorch/issues/120233)
