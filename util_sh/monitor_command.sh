#!/bin/sh
# TIMEOUT - set number of seconds to wait for command to finish
# TIMEOUT2 - set number of seconds to wait for command to finish when it ignored the first grace signal (HUP)
# WAIT - specify time needed to graceful kill to happen
# MAIL_TO - email address to send mail when command was terminated, skip if '-'
#
# Example crontab entry that ensures docker is alive: `0 * * * * TIMEOUT=1800 TIMEOUT2=300 WAIT=30 MAIL_TO=lukaszgryglicki@o2.pl /usr/bin/monitor_command.sh /usr/bin/docker system info 1>/tmp/docker_system_info.log 2>/tmp/docker_system_info.err`
ts=`date +'%s'`
if [ -z "$1" ]
then
  echo "Please specify command to run"
  exit 1
fi
if [ -z "$TIMEOUT" ]
then
  echo "Please specify graceful timeout via TIMEOUT=n_seconds"
  exit 2
fi
if [ -z "$TIMEOUT2" ]
then
  echo "Please specify force timeout via TIMEOUT2=n_seconds"
  exit 3
fi
if [ -z "$WAIT" ]
then
  echo "Please specify how long actual graceful kill can take via WAIT=n_seconds (can be 0.5 for example)"
  exit 3
fi
if [ -z "$MAIL_TO" ]
then
  echo "Please specify email address to send email when command is terminated via MAIL_TO=email_address"
  exit 4
fi

# Run command, store pid as $pid
( $* ) & pid=$!
# Spawn watcher that waits TIMEOUT seconds and then kills command gracefully via kill -HUP, store watcher pid as $wather
( sleep $TIMEOUT && kill -HUP $pid ) 2>/dev/null & watcher=$!

# Iterate TIMEOUT seconds (every single second) to check if command didn't finshed before the TIMEOUT
s=0
while true
do
  # If finished there will be no $pid from PS only the header "PID"
  p=`ps -p $pid | awk '{ print $1}' | tail -n 1`
  if [ "$p" = "PID" ]
  then
    wait $pid
    code=$?
    echo "$* ($pid) finished ($code) before timeout"
    exit $code
  fi
  # wait for the next second and finish if that second is TIMEOUT value
  sleep 1
  s=$((s+1))
  if [ "$s" -eq "$TIMEOUT" ]
  then
    break
  fi
done

# If command is still running after watcher finished, wait TIMEOUT2 and check if still running. If so kill it via KILL signal (that cannot be ignored)
wait $watcher 2>/dev/null
# give a bit of time so kill -HUP actually takes place
sleep $WAIT
force=''
p=`ps -p $pid | awk '{ print $1}' | tail -n 1`
if [ "$p" = "$pid" ]
then
  sleep $TIMEOUT2
  p=`ps -p $pid | awk '{ print $1}' | tail -n 1`
  if [ "$p" = "$pid" ]
  then
    echo "$pid didn't finish yet, killing it"
    kill -KILL $pid  2>/dev/null
    force='1'
  fi
fi

# Now final wait for the original command, possible situations incude:  finished OK, killed gracefully by HUP signal after TIMEOUT seconds
# force killed by KILL signal after TIMEOUT+WAIT+TIMEOUT2 seconds
if wait $pid 2>/dev/null
then
  code=$?
  echo "$* ($pid) finished ($code)"
else
  code=$?
  host=`hostname`
  if [ -z "$force" ]
  then
    msg="$host: $* ($pid) interrupted ($code)"
  else
    msg="$host: $* ($pid) force interrupted ($code)"
  fi
  ts2=`date +'%s'`
  took=$(($ts2-$ts))
  echo "From: monitor_command_$$@${host}" > temp.txt
  echo "To: $MAIL_TO" >> temp.txt
  echo "Subject: $msg" >> temp.txt
  echo '' >> temp.txt
  echo $msg >> temp.txt
  echo "Config: TIMEOUT=${TIMEOUT}s, TIMEOUT2=${TIMEOUT2}s, WAIT=${WAIT}s" >> temp.txt
  echo "Took: ${took}s" >> temp.txt
  hash=`echo "$*" | base64`
  hash="/tmp/${hash}"
  echo "Hash: $hash" >> temp.txt
  cat temp.txt
  if [ ! "$MAIL_TO" = "-" ]
  then
    if [ -f "$hash" ]
    then
      echo "No need to send email $hash hash file exists."
    else
      echo "Sending email to $MAIL_TO and creating $hash hash file"
      sendmail $MAIL_TO < temp.txt && echo "$*" > "$hash"
    fi
  fi
  rm -f temp.txt
fi
exit $code
