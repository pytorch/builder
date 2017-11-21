ls wheelhouse75/ | xargs -I {} aws s3 cp wheelhouse75/{} s3://pytorch/whl/cu75/ --acl public-read
ls wheelhouse80/   | xargs -I {} aws s3 cp wheelhouse80/{} s3://pytorch/whl/cu80/ --acl public-read
ls wheelhouse90/   | xargs -I {} aws s3 cp wheelhouse90/{} s3://pytorch/whl/cu90/ --acl public-read
