#!/bin/bash
# Example:
# ONLY=`cat devel/all_prod_projects.txt` SKIP=all ./util_sh/all_cncf_re.sh
function dbg() {
  if [ ! -z "${DBG}" ]
  then
    echo "${1}"
  fi
}
declare -A only=()
if [ ! -z "${ONLY}" ]
then
  for o in ${ONLY}
  do
    only[${o}]="1"
  done
fi
declare -A skip=()
if [ ! -z "${SKIP}" ]
then
  for s in ${SKIP}
  do
    skip[${s}]="1"
  done
fi
declare -A res=()
projs=''
if [ -z "${FN}" ]
then
  FN='./util_data/project_re.txt'
fi
for row in `cat "${FN}" | sort`
do
  ary=(${row//,/ })
  dbg "Project ${ary[0]} --> ${ary[1]}"
  proj="${ary[0]}"
  if [ ! -z "${ONLY}" ] && [ -z "${only[${proj}]}" ]
  then
    dbg "Skipping $proj, not listed in ${ONLY}"
    continue
  fi
  if [ ! -z "${SKIP}" ] && [ ! -z "${skip[${proj}]}" ]
  then
    dbg "Skipping $proj - listed in ${SKIP}"
    continue
  fi
  rt='(?i)^'
  tl='$'
  re=''
  processed=''
  for i in "${!ary[@]}"
  do
    if [ "${i}" = "0" ]
    then
      continue
    fi
    if [ "${i}" = "2" ]
    then
      rt="${rt}("
      tl=")$"
    fi
    dbg "$proj[$i] = ${ary[${i}]}"
    item=${ary[${i}]}
    if ( [ "${i}" = "1" ] && [[ "${item}" =~ ^regexp:.* ]] )
    then
      re="${item:7}"
      processed='1'
      break
    fi
    if [[ $item == *"/"* ]]
    then
      item=${item//\//\\\/}
    else
      item="${item}\\/.*"
    fi
    if [ -z "${re}" ]
    then
      re="${item}"
    else
      re="${re}|${item}"
    fi
  done
  if [ -z "${processed}" ]
  then
    re="${rt}${re}${tl}"
  fi
  dbg "${proj} --> '${re}'"
  if [ -z "${projs}" ]
  then
    projs="${proj}"
  else
    projs="${projs} ${proj}"
  fi
  res[$proj]=$re
done
final=''
for proj in ${projs}
do
  echo "$proj,regexp:${res[${proj}]}"
  re="${res[${proj}]}"
  if [ "${re:5:1}" = "(" ]
  then
    if [ -z "${final}" ]
    then
      final="${re:6:-2}"
    else
      final="${final}|${re:6:-2}"
    fi
  else
    if [ -z "${final}" ]
    then
      final="${re:5:-1}"
    else
      final="${final}|${re:5:-1}"
    fi
  fi
done
final="regexp:(?i)^(${final})$"
echo "all,${final}"
if [ ! -z "${ONLY}" ]
then
  for o in ${ONLY}
  do
    if ( [ -z "${res[${o}]}" ] && [ -z "${skip[${o}]}" ] )
    then
      echo "Requested ${o} but such project is not found"
    fi
  done
fi
