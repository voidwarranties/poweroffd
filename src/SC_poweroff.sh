echo "Script started."

# get a list of users logged into a graphical session
whoResults=$(who | grep '(:[0-9])')

# transform the result string into an array
IFS='\n' readarray whoArray <<< "$whoResults"

# stop the program if no one is logged in
# if no one is logged in this code returns an array containing empty element 
if [ ${#whoArray[@]} == 1 ] ; then
  if [ "$(echo -ne ${whoArray} | wc -m)" -eq 0 ]; then
    # check for tty1
    whoResults=$(who | grep 'tty1')
    whoResults="$whoResults (:0)"
    IFS='\n' readarray whoArray <<< "$whoResults"
    if [ "$(echo -ne ${whoArray} | wc -m)" -eq 0 ]; then
      # still nothing:
      echo "No logged in user found"
      exit 0
    fi
  fi
fi

# start the countdown windows on every display with logged in user
pids=()
for i in "${whoArray[@]}" ; do
  set -- $i
  echo "Logged in user \"$1\" on display \"${!#:1:2}\" found"
  SUBSTRING=$(echo ${!#:1:2})
  echo $SUBSTRING
  sudo -H -u $1 SC_poweroff_popup.sh $1 ${!#:1:2} &
  pids+=($!)
done

# wait for countdownwindows to be closed
exitcode=0
for i in "${pids[@]}" ; do
  wait $i
  ((exitcode|=($?)))
done

if [ $exitcode = 1 ] ; then
  echo "Poweroff cancelled by local user"
  exit 1
else
  systemctl poweroff -i
  exit 0
fi
