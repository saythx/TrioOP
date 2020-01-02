#! /bin/bash
awk -F "\t" 'NR==FNR{a[$2]=$1;next}{print $0"\t"a[$1]}' <(snmpwalk -v 2c -O x -c public 192.168.254.253 1.3.6.1.4.1.14179.2.1.4.1.3 | grep Hex-STRING: | awk -F ":|=|Hex-STRING:" '{ cmd="echo "$5 "| xxd -r -p";system(cmd);print"\t"substr($3,29)}') <(awk -F "\t" 'NR==FNR{a[$1]=$2;}NR!=FNR && a[$1] {print $0"\t"a[$1]}' <(snmpwalk -v 2c -O x -c public 192.168.254.253 1.3.6.1.4.1.14179.2.1.4.1.1 | awk -F ":|=" '{print substr($3,29)"\t"$5}' | sort) <(snmpwalk -v 2c -O x -c public 192.168.254.253 1.3.6.1.4.1.14179.2.1.4.1.2 | awk -F ":|=" '{print substr($3,29)"\t"$5}' | sort)) > trionet
# import into mysql
mysqlimport -h192.168.30.17 -utrio -ptrionet -d --local trionet ./trionet
