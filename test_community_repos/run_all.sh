set -e

for file in */ ; do
    echo "Testing $file";
    for script in $file/run.sh ; do
        $script
    done
    echo "Test passed $file";
done

echo "ALL TESTS PASSED"
