# PyTorch Release Scripts

These are a collection of scripts that are to be used for release activities.

> NOTE: All scripts should do no actual work unless the `DRY_RUN` environment variable is set
>       to `disabled`.
>       The basic idea being that there should be no potential to do anything dangerous unless
>       `DRY_RUN` is explicitly set to `disabled`.

## Requirements to actually run these scripts
* AWS access to pytorch account (META Employees: `bunnylol cloud pytorch`)
* Access to upload conda packages to the [`pytorch`](https://anaconda.org/pytorch) conda channel
* Access to the PyPI repositories (like [torch](https://pypi.org/project/torch))


## Promote

These are scripts related to promotion of release candidates to GA channels, these
can actually be used to promote pytorch, libtorch, and related domain libraries.

> NOTE: Currently the script requires some knowledge on when to comment things out / comment things in

> TODO: Make the script not rely on commenting things out / commenting this in

### Usage

```bash
./promote.sh
```

## Restoring backups

All release candidates from `pytorch/pytorch` are currently backed up
to `s3://pytorch-backup/${TAG_NAME}` and can be restored to the test channels with the
`restore-backup.sh` script.

Which backup to restore from is dictated by the `RESTORE_FROM` environment variable.

### Usage
```bash
RESTORE_FROM=v1.5.0-rc5 ./restore-backup.sh
```
