while true
do
  date
  # GHA2DB_ST=1 GHA2DB_DEBUG=1 GHA2DB_QOUT=1 ./sync.sh
  ./sync.sh
  date
  sleep $1
done
