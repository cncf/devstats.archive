#!/bin/sh
# Example FROM=`cat input` TO=`cat output` FILES=`find abc/ -type f -not -iname 'something.txt'` ./devel/mass_replace.sh"
if [ -z "${FROM}" ]
then
  echo "You need to set FROM, example FROM=abc TO=xyz FILES='f1 f2' $0"
  exit 1
fi
if [ -z "${TO}" ]
then
  echo "You need to set TO, example FROM=abc TO=xyz FILES='f1 f2' $0"
  exit 2
fi
if [ -z "${FILES}" ]
then
  echo "You need to set FILES, example FROM=abc TO=xyz FILES='f1 f2' $0"
  exit 3
fi
for f in ${FILES}
do
  ./replacer $f || exit 4
done
echo 'OK'
