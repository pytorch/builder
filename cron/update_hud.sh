#!/bin/bash

# Creates an updated table of all jobs for this machine of format
# | status | build_name | link_binary | link_logs | size_mb | duration |
# Then appends the table to the log list for the day


set -ex
echo "update_hud.sh at $(pwd) starting at $(date) on $(uname -a) with pid $$"
SOURCE_DIR=$(cd $(dirname $0) && pwd)
source "${SOURCE_DIR}/nightly_defaults.sh"

# Collect jobs
# This is not atomic, but that's not important here
failed_jobs=($(cd $FAILED_LOG_DIR && find . -maxdepth 1 -name '*.log'))
succeeded_jobs=($(cd $SUCCEEDED_LOG_DIR && find . -maxdepth 1 -name '*.log'))

this_machine="$(uname -n)"


##############################################################################
# Build up the summary table
# We write all the results to summary.html and later append it to the summary
# in the gh-pages branch
summary_html="${today}/summary.html"
cat > "$summary_html" << EOL
<h3>$NIGHTLIES_DATE $this_machine</h3>
<table>
EOL

# For all jobs for this machine, 
for fulllog in "${failed_jobs[@]}"; do
    log="$(basename $fulllog)"
    cat >> "$summary_html" << EOL
<tr>
  <td>FAILED</td>
  <td><a href=https://download.pytorch.org/$LOGS_S3_DIR/$log>$log</a></td>
</tr>
EOL
done

for fulllog in "${succeeded_jobs[@]}"; do
    log="$(basename $fulllog)"
    cat >> "$summary_html" << EOL
<tr>
  <td>success</td>
  <td><a href=https://download.pytorch.org/$LOGS_S3_DIR/$log>$log</a></td>
</tr>
EOL
done

# End the table
echo "</table>" >> "$summary_html"


##############################################################################
# Add the table to the gh-pages branch
pushd "$NIGHTLIES_FOLDER/builder-gh-pages"

# Discard all local changes, try to avoid a merge conflict for any reason
git reset --hard
git clean -xffd
git checkout gh-pages
git reset origin/gh-pages --hard
git clean -xffd
git pull origin gh-pages

# Append the summary table created here to the top of the webpage
(cat $summary_html; cat index.html) > tmp_index.html
mv tmp_index.html index.html

git add index.html
git commit -m "Updating with logs for $this_machine for $NIGHTLIES_DATE"
git push origin gh-pages

popd
