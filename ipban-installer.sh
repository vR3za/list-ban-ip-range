#!/bin/bash

#######get params#########
while [[ $# > 0 ]];do
    key="$1"
    case $key in
	install)
		install_ipban
		;;
	update)
		update_ipban
		;;
	remove)
		uninstall_ipban
		;;
        *)
         # unknown option
        ;;
    esac
    shift
done

uninstall_ipban(){
	rm "${HOME}/ipban-update.sh"
	crontab -l | grep -v "ipban-update.sh" | crontab -
	systemctl stop netfilter-persistent.service && systemctl disable netfilter-persistent.service
	iptables -F && iptables -X && iptables -Z && ip6tables -F && ip6tables -X && ip6tables -Z 
	iptables-save > /etc/iptables/rules.v4 && ip6tables-save > /etc/iptables/rules.v6
	systemctl restart iptables.service ip6tables.service
	clear && success "Uninstalled IPBAN!"
	exit 0
}

update_ipban(){
	wget -P ${HOME} -N --no-check-certificate "https://raw.githubusercontent.com/AliDbg/IPBAN/main/ipban-update.sh"
	chmod +x "${HOME}/ipban-update.sh" && bash "${HOME}/ipban-update.sh"
	clear && success "Updated IPBAN!"
	exit 0
}

install_ipban(){
	apt update && apt -y upgrade

	apt -y install curl unzip perl xtables-addons-common xtables-addons-dkms libtext-csv-xs-perl libmoosex-types-netaddr-ip-perl iptables-persistent 

	mkdir /usr/share/xt_geoip/ && chmod +x /usr/share/xt_geoip/

	wget -P ${HOME} -N --no-check-certificate "https://raw.githubusercontent.com/AliDbg/IPBAN/main/ipban-update.sh"

	crontab -l | grep -v "ipban-update.sh" | crontab -
	(crontab -l 2>/dev/null; echo "0 3 */2 * * ${HOME}/ipban-update.sh") | crontab -
	chmod +x "${HOME}/ipban-update.sh" && bash "${HOME}/ipban-update.sh"

	iptables -F && iptables -X && iptables -Z && ip6tables -F && ip6tables -X && ip6tables -Z 

	iptables -A OUTPUT -m geoip -p tcp  -m multiport --dports 0:9999 --dst-cc CN,IR,CU,VN,ZW,BY -j DROP
	ip6tables -A OUTPUT -m geoip -p tcp -m multiport --dports 0:9999 --dst-cc CN,IR,CU,VN,ZW,BY -j DROP
	iptables -A OUTPUT -m geoip -p udp  -m multiport --dports 0:9999 --dst-cc CN,IR,CU,VN,ZW,BY -j DROP
	ip6tables -A OUTPUT -m geoip -p udp -m multiport --dports 0:9999 --dst-cc CN,IR,CU,VN,ZW,BY -j DROP

	iptables-save > /etc/iptables/rules.v4 && ip6tables-save > /etc/iptables/rules.v6

	systemctl enable netfilter-persistent.service && systemctl restart iptables.service ip6tables.service
	clear && success "Installed IPBAN!"
	exit 0
}
