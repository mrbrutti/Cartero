if [[ `uname -a` =~ kali ]]; then
  echo "Stopping beef-xss Service."
  service beef-xss stop
else
  echo "Stoping beef command"
  kill `ps aux | grep -v grep | grep beef | awk '{print $2}'`
fi
