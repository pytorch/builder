ls wheelhouse75/ | xargs -I {} aws s3 cp wheelhouse75/{} s3://pytorch/whl/cu75/ --acl public-read
ls wheelhouse/   | xargs -I {} aws s3 cp wheelhouse/{} s3://pytorch/whl/cu80/ --acl public-read
