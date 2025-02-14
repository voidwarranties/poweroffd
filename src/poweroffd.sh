echo "MQTT Poweroff listener started"

# wait for incoming messages
while :
do
  msg=$(mosquitto_sub -h $MQTT_HOST -p $MQTT_PORT -u $MQTT_USERNAME -P $MQTT_PASSWORD -C 1 -t "$MQTT_TOPIC")
  if [ "$msg" == "poweroff" ]
  then
    echo "Starting poweroff script"
    SC_poweroff.sh
  fi
done
