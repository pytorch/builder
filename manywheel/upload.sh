ls wheelhouse80/   | xargs -I {} aws s3 cp wheelhouse80/{} s3://pytorch/whl/cu80/ --acl public-read
ls wheelhouse90/   | xargs -I {} aws s3 cp wheelhouse90/{} s3://pytorch/whl/cu90/ --acl public-read
ls wheelhouse91/   | xargs -I {} aws s3 cp wheelhouse91/{} s3://pytorch/whl/cu91/ --acl public-read
ls wheelhousecpu/   | xargs -I {} aws s3 cp wheelhousecpu/{} s3://pytorch/whl/cpu/ --acl public-read
