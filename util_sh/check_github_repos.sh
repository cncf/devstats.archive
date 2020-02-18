#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: you need to provide at least one file to check"
  exit 1
fi
fn=util_sh/repos.txt
> "${fn}"
for f in "$@"
do
  cat "$f" >> "${fn}"
done
vim --not-a-term -c 'g/^\s*\#/d' -c 'wq!' "${fn}"
nchk=0
err=0
ok=0
chk=''
errs=''
oks=''
for f in `cat "$fn"`
do
  f=${f//\"/}
  f=${f// /}
  l=${f:0:1}
  if [ "$l" = "#" ]
  then
    continue
  fi
  f2=${f//\/\//}
  if [ "$f" = "$f2" ]
  then
    f="https://${f}"
  fi
  IFS=':'
  arr=($f)
  unset IFS
  proto=${arr[0]}
  rest=${arr[1]}
  if [ ! "${proto}" = "https" ]
  then
    proto="https"
  fi
  f="${proto}:${rest}"
  if [ -z "$chk" ]
  then
    chk=$f
  else
    chk="$chk $f"
  fi
  nchk=$((nchk+1))
  wget --timeout=5 -t 1 $f -O /dev/null 1>/dev/null 2>/dev/null
  r=$?
  if [ "$r" = "0" ]
  then
    GIT_TERMINAL_PROMPT=0 git ls-remote $f 1>/dev/null 2>/dev/null
    r=$?
    if [ "$r" = "0" ]
    then
      echo "correct git $f"
      ok=$((ok+1))
      if [ -z "$oks" ]
      then
        oks=$f
      else
        oks="$oks $f"
      fi
    else
      echo "non-git $f -> $r"
      err=$((err+1))
      if [ -z "$errs" ]
      then
        errs=$f
      else
        errs="$errs $f"
      fi
    fi
  else
    echo "non-fetchable $f -> $r"
    err=$((err+1))
    if [ -z "$errs" ]
    then
      errs=$f
    else
      errs="$errs $f"
    fi
  fi
done
rm -f "$fn" wget-log*
echo "Checked ${nchk}:"
for s in $chk
do
  echo $s
done
echo "Incorrect: $err"
for s in $errs
do
  echo $s
done
echo "Correct: $ok"
for s in $oks
do
  echo $s
done
