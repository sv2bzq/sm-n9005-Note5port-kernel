#!/system/bin/sh

BB=/sbin/busybox;

mount -o remount,rw /
mount -o remount,rw /system /system

#
# Stop Google Service and restart it on boot (dorimanx)
# This removes high CPU load and ram leak!
#
if [ "$($BB pidof com.google.android.gms | wc -l)" -eq "1" ]; then
	$BB kill $($BB pidof com.google.android.gms);
fi;
if [ "$($BB pidof com.google.android.gms.unstable | wc -l)" -eq "1" ]; then
	$BB kill $($BB pidof com.google.android.gms.unstable);
fi;
if [ "$($BB pidof com.google.android.gms.persistent | wc -l)" -eq "1" ]; then
	$BB kill $($BB pidof com.google.android.gms.persistent);
fi;
if [ "$($BB pidof com.google.android.gms.wearable | wc -l)" -eq "1" ]; then
	$BB kill $($BB pidof com.google.android.gms.wearable);
fi;

#
# Set correct r/w permissions for LMK parameters
#
$BB chmod 666 /sys/module/lowmemorykiller/parameters/cost;
$BB chmod 666 /sys/module/lowmemorykiller/parameters/adj;
$BB chmod 666 /sys/module/lowmemorykiller/parameters/minfree;

#
# Allow untrusted apps to read from debugfs (mitigate SELinux denials)
#
/system/xbin/supolicy --live \
	"allow untrusted_app debugfs file { open read getattr }" \
	"allow untrusted_app sysfs_lowmemorykiller file { open read getattr }" \
	"allow untrusted_app sysfs_devices_system_iosched file { open read getattr }" \
	"allow untrusted_app persist_file dir { open read getattr }" \
	"allow debuggerd gpu_device chr_file { open read getattr }" \
	"allow netd netd capability fsetid" \
	"allow netd { hostapd dnsmasq } process fork" \
	"allow { system_app shell } dalvikcache_data_file file write" \
	"allow { zygote mediaserver bootanim appdomain }  theme_data_file dir { search r_file_perms r_dir_perms }" \
	"allow { zygote mediaserver bootanim appdomain }  theme_data_file file { r_file_perms r_dir_perms }" \
	"allow system_server { rootfs resourcecache_data_file } dir { open read write getattr add_name setattr create remove_name rmdir unlink link }" \
	"allow system_server resourcecache_data_file file { open read write getattr add_name setattr create remove_name unlink link }" \
	"allow system_server dex2oat_exec file rx_file_perms" \
	"allow mediaserver mediaserver_tmpfs file execute" \
	"allow drmserver theme_data_file file r_file_perms" \
	"allow zygote system_file file write" \
	"allow atfwd property_socket sock_file write" \
	"allow untrusted_app sysfs_display file { open read write getattr add_name setattr remove_name }" \
	"allow debuggerd app_data_file dir search" \
	"allow sensors diag_device chr_file { read write open ioctl }" \
	"allow sensors sensors capability net_raw" \
	"allow init kernel security setenforce" \
	"allow netmgrd netmgrd netlink_xfrm_socket nlmsg_write" \
	"allow netmgrd netmgrd socket { read write open ioctl }"

mount -o remount,rw /
mount -o remount,rw /system /system

# kernel custom test

if [ -e /data/Kerneltest.log ]; then
rm /data/Kerneltest.log
fi

echo  Kernel script is working !!! >> /data/Kerneltest.log
echo "excecuted on $(date +"%d-%m-%Y %r" )" >> /data/Kerneltest.log

#
# Init.d
#
if [ ! -d /system/etc/init.d ]; then
	mkdir -p /system/etc/init.d/;
	chown -R root.root /system/etc/init.d;
	chmod 777 /system/etc/init.d/;
	chmod 777 /system/etc/init.d/*;
fi;

$BB run-parts /system/etc/init.d


mount -o remount,rw /
mount -o remount,rw /system /system

$BB mount -t rootfs -o remount,ro rootfs
$BB mount -o remount,ro /system /system
$BB mount -o remount,rw /data
