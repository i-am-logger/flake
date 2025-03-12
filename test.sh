for i in /sys/bus/usb/devices/*/power/control; do
  echo on > $i || true
done
for i in /sys/bus/usb/devices/*/power/autosuspend; do
  echo -1 > $i || true
done
