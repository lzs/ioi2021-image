#!/bin/sh

check_ip()
{
	local IP=$1

	if expr "$IP" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
		return 0
	else
		return 1
	fi
}


do_config()
{

	CONF=$1

	if ! test -f "$CONF"; then
		echo "Can't read $CONF"
		exit 1
	fi

	WORKDIR=`mktemp -d`

	tar jxf $CONF -C $WORKDIR || ( echo "Failed to unpack $CONF"; rm -rf $WORKDIR; exit 1 )

	IP=$(cat $WORKDIR/vpn/ip.conf)
	MASK=$(cat $WORKDIR/vpn/mask.conf)

	if ! check_ip "$IP" || ! check_ip "$MASK"; then
		echo Bad IP numbers
		rm -r $WORKDIR
		exit 1
	fi

	echo "$IP" > /etc/tinc/vpn/ip.conf
	echo "$MASK" > /etc/tinc/vpn/mask.conf
	rm /etc/tinc/vpn/hosts/* 2> /dev/null
	cp $WORKDIR/vpn/hosts/* /etc/tinc/vpn/hosts/
	cp $WORKDIR/vpn/rsa_key.* /etc/tinc/vpn/
	cp $WORKDIR/vpn/tinc.conf /etc/tinc/vpn
	cp $WORKDIR/vpn/ioibackup* /opt/ioi/store/ssh/

	rm -r $WORKDIR
	USERID=$(cat /etc/tinc/vpn/tinc.conf | grep Name | cut -d\  -f3)
	chfn -f "$USERID" ioi

	systemctl restart tinc@vpn

	return
}


case "$1" in
	vpnstart)
		systemctl start tinc@vpn
		;;
	vpnrestart)
		systemctl restart tinc@vpn
		;;
	vpnstatus)
		systemctl status tinc@vpn
		;;
	setvpnproto)
		if [ "$2" = "tcp" ]; then
			sed -i '/^TCPOnly/ s/= no$/= yes/' /etc/tinc/vpn/tinc.conf
			echo VPN protocol set to TCP only.
		elif [ "$2" = "auto" ]; then
			sed -i '/^TCPOnly/ s/= yes$/= no/' /etc/tinc/vpn/tinc.conf
			echo VPN procotol set to auto TCP/UDP with fallback to TCP only.
		else
			cat - <<EOM
Invalid argument to setvpnproto. Specify "yes" to use TCP only, or "auto"
to allow TCP/UDP with fallback to TCP only.
EOM
			exit 1	
		fi
		;;
	vpnconfig)
		do_config $2
		;;
	settz)
		tz=$2
		if [ -z "$2" ]; then
			cat - <<EOM
No timezone specified. Run tzselect to learn about the valid timezones
available on this system.
EOM
			exit 1
		fi
		if [ -f "/usr/share/zoneinfo/$2" ]; then
			cat - <<EOM
Your timezone will be set to $2 at your next login.
*** Please take note that all dates and times communicated by the IOI 2020 ***
*** organisers will be in Asia/Singapore timezone (GMT+08), unless it is   ***
*** otherwise specified.                                                   ***
EOM
			echo "$2" > /opt/ioi/store/timezone
		else
			cat - <<EOM
Timezone $2 is not valid. Run tzselect to learn about the valid timezones
available on this system.
EOM
			exit 1
		fi
		;;
	setautobackup)
		if [ "$2" = "on" ]; then
			touch /opt/ioi/store/autobackup
			echo Auto backup enabled
		elif [ "$2" = "off" ]; then
			if [ -f /opt/ioi/store/autobackup ]; then
				rm /opt/ioi/store/autobackup
			fi
			echo Auto backup disabled
		else
			cat - <<EOM
Invalid argument to setautobackup. Specify "on" to enable automatic backup
of home directory, or "off" to disable automatic backup. You can always run
"ioibackup" manually to backup at any time. Backups will only include
non-hidden files less than 1MB in size.
EOM
		fi
		;;
	*)
		echo Not allowed
		;;
esac

# vim: ft=sh ts=4 sw=4 noet