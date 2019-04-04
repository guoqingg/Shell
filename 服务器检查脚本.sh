#!/bin/bash
#获取端口列表。
PORT=`ss -nlpt | awk '{print $4}' | sed -n '2,$p' | awk -F":" '{print $2}' | uniq`

#打印格式
echo "##########################################################################################################################
服务名称			监听端口			ESTABLISHED			TIME_WAIT"

#循环端口列表打印端口对应服务名称、ESTABLISHED数和TIME_WAIT数。
for P in $PORT
do
	SERVER_NAME=`ss -nlpt | grep ":$P" | awk '{print $NF}' | awk -F"\"" '{print $2}'`
	ES_NUM=`ss -an | grep ESTAB | awk '{print $4}' | awk -F":" '{print $2}' | grep -w -c "$P"`
	TW_NUM=`ss -an | grep TIME-WAIT | awk '{print $4}' | awk -F":" '{print $2}' | grep -w -c "$P"`
#判断SERVER_NAME长度增加tab数量解决输出不对齐问题。
        SERVER_NAME_LENGTH=`echo $SERVER_NAME | wc -L`
	if [ ${SERVER_NAME_LENGTH} -gt 8 ]
	then
		echo "$SERVER_NAME			$P				$ES_NUM				$TW_NUM"
	else
		echo "$SERVER_NAME				$P				$ES_NUM				$TW_NUM"
	fi
done
echo -e "\n"
#打印非系统进程
echo "##########################################################################################################################
进程："
#输入系统进程信息文件
cat > /root/system_process.log << EOF
dbus dbus-daemon dbus --system
root auditd
root crond
root /sbin/agetty root /dev/ttyS0 root 115200 root vt100-nav
root /sbin/mingetty root /dev/tty1
root /sbin/mingetty root /dev/tty2
root /sbin/mingetty root /dev/tty3
root /sbin/mingetty root /dev/tty4
root /sbin/mingetty root /dev/tty5
root /sbin/mingetty root /dev/tty6
root /usr/local/aegis/aegis_client/aegis_10_47/AliYunDun
root /sbin/rsyslogd root -i root /var/run/syslogd.pid root -c root 5
root /sbin/udevd root -d
root /usr/local/aegis/aegis_client/aegis_10_43/AliYunDun
root /usr/local/aegis/aegis_update/AliYunDunUpdate
root /usr/sbin/aliyun-service
root /usr/sbin/atd
root /usr/sbin/sshd
rpc rpcbind
rpcuser rpc.statd
UID CMD 
EOF
#当前系统进程信息文件
ps -ef |  awk '$2>1024' | awk -F" " '{for (i=8;i<=NF;i++)printf("%s ",$1" "$i);print ""}' | awk '{if ($2!~/.*\[.*/) print $0}'| sort | uniq | sort | egrep -v -w "awk|ps|\-bash|sort|uniq"  > /root/now_system_process.log

#对比文件差异得出非系统进程。grep -vwf打印出第一个文件没有而第二个文件有的。
grep -vwf system_process.log now_system_process.log
rm -f /root/system_process.log /root/now_system_process.log
echo -e "\n"

echo "##########################################################################################################################
磁盘分区			UUID							文件系统		挂载目录"
#循环磁盘分区列表
for DISK in `fdisk -l | grep ^\/dev\/v | awk '{print $1}'`
do
	UUID=`blkid  $DISK | awk -F"\"" '{print $2}'`
	FILESYSTEM=`blkid  $DISK | awk -F"\"" '{print $4}'`
	MOUNT_DIR=`df -h | grep "$DISK" | awk '{print $NF}'`
	echo "$DISK			$UUID			$FILESYSTEM			$MOUNT_DIR"
done

#判断是否挂载NAS，输出挂载详细信息
NAS=`df -h | grep "nas.aliyuncs.com"`
if [ ! -z $NAS ]
then
	echo -e "\n"
	echo "NAS挂载情况：
NAS名称											挂载点"
	for _NAS in $NAS
	do
		NFS_MOUNT_DIR=`mount | grep "$_NAS" | awk '{print $3}'`
		echo "$_NAS						$NFS_MOUNT_DIR"
	done
fi

#fstab配置
echo -e '\n'
echo "fstab配置:"
cat /etc/fstab | sed '1,13d'
echo -e '\n'

#数据目录，ll会导致无法显示
echo "##########################################################################################################################
数据目录："
ls -ld /data/web 2>/dev/null | awk '{print $NF}'
ls -ld /data/pgsql 2>/dev/null | awk '{print $NF}'
ls -ld /data/mysql 2>/dev/null | awk '{print $NF}'

echo -e '\n'

echo "##########################################################################################################################
root用户计划任务："
crontab -l

#判断是否存在postgres用户的计划任务
PG_CRONTAB=`crontab -l -u postgres 2>/dev/null`
[ ! -z $PG_CRONTAB ] && echo -e '\n' && echo "postgres用户计划任务
$PG_CRONTAB"



