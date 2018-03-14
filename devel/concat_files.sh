#!/bin/bash
rm -f ~/all.go ~/all.sh ~/all.sql ~/all.yaml ~/all.md ~/all.json
for f in `find . -type f -iname "*.go"`; do echo "// File: $f" >> ~/all.go; cat $f >> ~/all.go; done
for f in `find . -type f -iname "*.sh"`; do echo "# File: $f" >> ~/all.sh; cat $f >> ~/all.sh; done
for f in `find . -type f -iname "*.sql"`; do echo "-- File: $f" >> ~/all.sql; cat $f >> ~/all.sql; done
for f in `find . -type f -iname "*.yaml"`; do echo "# File: $f" >> ~/all.yaml; cat $f >> ~/all.yaml; done
for f in `find . -type f -iname "*.json"`; do echo "/* File: $f*/" >> ~/all.json; cat $f >> ~/all.json; done
for f in `find . -type f -iname "*.html"`; do echo "<!-- File: $f -->" >> ~/all.html; cat $f >> ~/all.html; done
for f in `find . -type f -iname "*.md"`
do
  if [ ! "$f" = "./docs/ALL.md" ]
  then
    rel=`echo $f | cut -c 3-`
    echo "# File: [$f](https://github.com/cncf/devstats/blob/master/$rel)" >> ~/all.md
    cat $f >> ~/all.md
  fi
done
cp ~/all.md ./docs/ALL.md
