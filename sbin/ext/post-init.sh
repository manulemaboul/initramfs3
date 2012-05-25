#!/sbin/busybox sh
# Logging
#/sbin/busybox cp /data/user.log /data/user.log.bak
#/sbin/busybox rm /data/user.log
#exec >>/data/user.log
#exec 2>&1

mkdir /data/.siyah
chmod 777 /data/.siyah
ccxmlsum=`md5sum /res/customconfig/customconfig.xml | awk '{print $1}'`
if [ "a${ccxmlsum}" != "a`cat /data/.siyah/.ccxmlsum`" ];
then
	rm -f /data/.siyah/*.profile
	echo ${ccxmlsum} > /data/.siyah/.ccxmlsum
fi

[ ! -f /data/.siyah/default.profile ] && cp /res/customconfig/default.profile /data/.siyah
[ ! -f /data/.siyah/battery.profile ] && cp /res/customconfig/battery.profile /data/.siyah
[ ! -f /data/.siyah/performance.profile ] && cp /res/customconfig/performance.profile /data/.siyah

#For now static freq 1500->100
echo 1500 1400 1300 1200 1100 1000 900 800 700 600 500 400 300 200 100 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies

. /res/customconfig/customconfig-helper
read_defaults
read_config

//cpu undervolting
echo "${cpu_undervolting}" > /sys/devices/system/cpu/cpu0/cpufreq/vdd_levels

//change cpu step count
case "${cpustepcount}" in
	6)
    	echo 1200 1000 800 500 200 100 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies
    	;;
  	7)
    	echo 1400 1200 1000 800 500 200 100 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies
    	;;
  	8)
    	echo 1500 1400 1200 1000 800 500 200 100 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies
    	;;
  	9)
    	echo 1500 1400 1200 1000 800 500 300 200 100 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies
    	;;
  	15)
    	echo 1500 1400 1300 1200 1100 1000 900 800 700 600 500 400 300 200 100 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies
    	;;
esac;

# disable debugging on some modules
if [ "$logger" == "off" ]; then
	echo 0 > /sys/module/ump/parameters/ump_debug_level
	echo 0 > /sys/module/mali/parameters/mali_debug_level
	echo 0 > /sys/module/kernel/parameters/initcall_debug
	echo 0 > /sys//module/lowmemorykiller/parameters/debug_level
#	echo 0 > /sys/module/wakelock/parameters/debug_mask
#	echo 0 > /sys/module/userwakelock/parameters/debug_mask
	echo 0 > /sys/module/earlysuspend/parameters/debug_mask
	echo 0 > /sys/module/alarm/parameters/debug_mask
	echo 0 > /sys/module/alarm_dev/parameters/debug_mask
	echo 0 > /sys/module/binder/parameters/debug_mask
	echo 0 > /sys/module/xt_qtaguid/parameters/debug_mask
fi

#Run my modules
/sbin/busybox sh /sbin/ext/modules.sh

# for ntfs automounting
mkdir /mnt/ntfs
mount -t tmpfs tmpfs /mnt/ntfs
chmod 777 /mnt/ntfs

#/sbin/busybox sh /sbin/ext/busybox.sh

/sbin/busybox sh /sbin/ext/properties.sh

/sbin/busybox sh /sbin/ext/install.sh

# run this because user may have chosen not to install root at boot but he may need it later and install it using ExTweaks
/sbin/busybox sh /sbin/ext/su-helper.sh

/sbin/busybox mount -t rootfs -o remount,rw rootfs

##### Early-init phase tweaks #####
/sbin/busybox sh /sbin/ext/cortexbrain-tune.sh

/sbin/busybox rm /system/etc/init.d/200dori-tweaks

##### EFS Backup #####
(
# make sure that sdcard is mounted
sleep 30
/sbin/busybox sh /sbin/ext/efs-backup.sh
) &

# apply ExTweaks defaults
/res/uci.sh apply

##### init scripts #####
(
/sbin/busybox sh /sbin/ext/run-init-scripts.sh
)&

(
sleep 60
/sbin/busybox sh /sbin/ext/cortexbrain-tune.sh
)&

