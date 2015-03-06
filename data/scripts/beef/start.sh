if [[ `uname -a` =~ kali ]]; then
  echo "Starting beef-xss service"
  /usr/sbin/service beef-xss start
else
  echo "Starting beef command"
  "$@" > /dev/null &
fi
