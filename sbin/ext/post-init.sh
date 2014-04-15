#!/system/bin/sh


# Logging

 cp /data/user.log /data/user.log.bak
 rm /data/user.log
exec >>/data/user.log
exec 2>&1

echo $(date) START of post-init.sh


#Copiar modulos a /system
#sbin/busybox mount /system -o remount,rw
mount -o rw,remount /system

cp -a /lib/modules/*.ko /system/lib/modules/
chmod 755 /system/lib/modules/*.ko;

mount -o ro,remount /system

echo remontado system como lectura
# Remount rootfs rw
mount -o rw,remount rootfs 

#Desde el recovery
if  [ -f /data/.enable_logs ]; then
   insmod /lib/modules/logger.ko
   echo Enable logs
fi

#Cargar modulo frandom
insmod /lib/modules/frandom.ko

# IPv6 privacy tweak
#if  [ "` grep IPV6PRIVACY /system/etc/tweaks.conf`" ]; then
  echo "2" > /proc/sys/net/ipv6/conf/all/use_tempaddr
#fi


# Remount ext4 partitions with optimizations
#  for k in $( mount |  grep ext4 |  cut -d " " -f3)
#  do
#        sync
#         mount -o remount,commit=15 $k
#  done
  

# Miscellaneous tweaks
  echo "1500" > /proc/sys/vm/dirty_writeback_centisecs
  echo "200" > /proc/sys/vm/dirty_expire_centisecs
  echo "0" > /proc/sys/vm/swappiness
  echo "8192" > /proc/sys/vm/min_free_kbytes

# CFS scheduler tweaks
#   echo HRTICK > /sys/kernel/debug/sched_features

# SD cards (mmcblk) read ahead tweaks
  echo "256" > /sys/block/mmcblk0/bdi/read_ahead_kb
  echo "256" > /sys/block/mmcblk1/bdi/read_ahead_kb

# TCP tweaks
  echo "2" > /proc/sys/net/ipv4/tcp_syn_retries
  echo "2" > /proc/sys/net/ipv4/tcp_synack_retries
  echo "10" > /proc/sys/net/ipv4/tcp_fin_timeout

# SCHED_MC power savings level
  #echo "1" > /sys/devices/system/cpu/sched_mc_power_savings

# Turn off debugging for certain modules
  echo "0" > /sys/module/wakelock/parameters/debug_mask
  echo "0" > /sys/module/userwakelock/parameters/debug_mask
  echo "0" > /sys/module/earlysuspend/parameters/debug_mask
  echo "0" > /sys/module/alarm/parameters/debug_mask
  echo "0" > /sys/module/alarm_dev/parameters/debug_mask
  echo "0" > /sys/module/binder/parameters/debug_mask


###### Compatibilidad con CWMManager ##########


# Remount system RW
#mount -t rootfs -o remount,rw rootfs 
mount -o rw,remount rootfs   

mkdir -p /customkernel/property
	echo true >> /customkernel/property/customkernel.cf-root 
	echo true >> /customkernel/property/customkernel.base.cf-root 
	echo Apolo >> /customkernel/property/customkernel.name 
	echo "Kernel Apolo JB" >> /customkernel/property/customkernel.namedisplay 
	echo 136 >> /customkernel/property/customkernel.version.number 
	echo 5.6 >> /customkernel/property/customkernel.version.name 
	echo true >> /customkernel/property/customkernel.bootani.zip 
	echo true >> /customkernel/property/customkernel.bootani.bin 
	echo true >> /customkernel/property/customkernel.cwm 
	echo 5.0.2.7 >> /customkernel/property/customkernel.cwm.version
# mount -t rootfs -o remount,ro rootfs 


##### Install SU ######################################################################################
Extracted_payload=0
# Check for auto-root bypass config file
if [ -f /system/.noautoroot ] || [ -f /data/.noautoroot ];
then
	echo "File .noautoroot found. Auto-root will be bypassed."
else
	# Seccion para rootear, instalar CWMManager y libreria del BLN
	#if  [ -e /system/xbin/su ] &&  [ -e /system/app/Superuser.apk ]  && [ -e /system/app/CWMManager.apk ] && [ -e /system/lib/hw/lights.exynos4.so.ApoloBAK2 ];
	if [ -f /system/Apolo/Desde_4-6 ];
	then
		echo "Nada que hacer, tenemos todo listo" 
	else
		if [ -f /system/Apolo/Desde_4- ];
		then
			 mount -o rw,remount /system
				 rm -rf /system/Apolo/Desde_4-
			 mount -o ro,remount /system
		fi

		echo "Extraer payload"	
			Extracted_payload=1				
			chmod 755 /sbin/read_boot_headers
			eval $(/sbin/read_boot_headers /dev/block/mmcblk0p5)
			load_offset=$boot_offset
			load_len=$boot_len
			cd / 
			dd bs=512 if=/dev/block/mmcblk0p5 skip=$load_offset count=$load_len | tar x
		 	
		#Hacemos  root
			# mount /system -o remount,rw
			# rm /system/bin/su
			# rm /system/xbin/su
			# cp /res/misc/su /system/xbin/su
			#/sbin/xzcat /res/misc/su.xz > /system/xbin/su
			# chown 0.0 /system/xbin/su
			# chmod 6755 /system/xbin/su
			# mount /system -o remount,ro
		#Supersu
			# mount /system -o remount,rw
			# rm /system/app/Superuser.apk
			# rm /data/app/Superuser.apk
			# rm /system/app/Supersu.apk
			# rm /data/app/Supersu.apk
			# rm /system/app/*supersu*
			# rm /data/app/*supersu*
			# cp /res/misc/Superuser.apk /system/app/Superuser.apk
			#/sbin/xzcat /res/misc/Superuser.apk.xz > /data/app/Superuser.apk
			# chown 0.0 /data/app/Superuser.apk
			# chmod 644 /data/app/Superuser.apk
			# mount /system -o remount,ro 
		
		#Librerias para el BLN

			mount -o rw,remount /system
			xzcat /res/misc/lights.exynos4.so.xz > /res/misc/lights.exynos4.so
			echo "Copiando las  liblights"
			 cp -a /system/lib/hw/lights.exynos4.so /system/lib/hw/lights.exynos4.so.ApoloBAK2
			 cp -a /res/misc/lights.exynos4.so /system/lib/hw/lights.exynos4.so
			 chown 0.0 /system/lib/hw/lights.exynos4.so
			 chmod 644 /system/lib/hw/lights.exynos4.so

		#Lo hacemos solo la primera vez
			 mkdir /system/Apolo
    			 chmod 755 /system/Apolo
			 echo 1 > /system/Apolo/Desde_4-6
			 mount -o ro,remount /system
	fi
	#Borramos payload
	rm -rf /res/misc/*
fi

 mount -t rootfs -o remount,ro rootfs

# Fin de la seccion su y ficheros auxiliares ############################################################################################################################

echo $(date) PRE-INIT DONE of post-init.sh
##### Post-init phase #####
sleep 12

#Colocando tweaks de configuracion

if  [ -f /data/.disable_mdnie ]; then
   echo 1 > /sys/class/misc/mdnie_preset/mdnie_preset
   echo $(date) Disable mdnie sharpness
fi

#Obsoleto en AOSP
#if  [ -f /data/.enable_crt ]; then
#   echo $(cat /data/.enable_crt) > /sys/power/fb_pause
#   echo $(date) Value inside the .enable_crt
#else
#   echo 50 > /sys/power/fb_pause
#   echo $(date) Default Value 50
#   echo $(date) No .enable_crt, so 50 is default value to fb_pause
#fi


# init.d support

echo $(date) USER EARLY INIT START from /system/etc/init.d
if cd /system/etc/init.d >/dev/null 2>&1 ; then
    for file in * ; do
        if ! cat "$file" >/dev/null 2>&1 ; then continue ; fi
        echo "START '$file'"
        /system/bin/sh "$file"
        echo "EXIT '$file' ($?)"
    done
fi
echo $(date) USER EARLY INIT DONE from /system/etc/init.d





echo $(date) END of post-init.sh
