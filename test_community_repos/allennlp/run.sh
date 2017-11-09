yes | pip install pytest-xdist
# pip install thinc breaks depending on gcc version  
yes | conda install thinc

TMPDIR=$RANDOM
mkdir /tmp/$TMPDIR
git clone https://github.com/allenai/allennlp /tmp/$TMPDIR
pushd /tmp/$TMPDIR
# Allennlp pins a pylint dependency through ssh.
# pylint on pip works just as well
sed -i -e 's>git+git://github.com/PyCQA/pylint.git@2561f539d60a3563d6507e7a22e226fb10b58210>pylint>g' requirements_test.txt
INSTALL_TEST_REQUIREMENTS="true" ./scripts/install_requirements.sh
pytest -v
popd
rm -rf /tmp/$TMPDIR

