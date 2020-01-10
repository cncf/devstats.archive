#!/bin/sh
# TIMEOUT - set number of seconds to wait for command to finish
# TIMEOUT2 - set number of seconds to wait for command to finish when it ignored the first grace signal (HUP)
# WAIT - specify time needed to graceful kill to happen
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
p=`ps -p $pid | awk '{ print $1}' | tail -n 1`
if [ "$p" = "$pid" ]
then
  sleep $TIMEOUT2
  p=`ps -p $pid | awk '{ print $1}' | tail -n 1`
  if [ "$p" = "$pid" ]
  then
    echo "$pid didn't finish yet, killing it"
    kill -KILL $pid  2>/dev/null
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
  echo "$* ($pid) interrupted ($code)"
fi
exit $code
