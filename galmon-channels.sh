#!/bin/bash

# Parse galmon ubxtool debug output to show which L-band channels are being received.
# I just did this after adding a multi band antenna to a ZED-F9P chipset.
# It produces the following results:

# GPS:
# 		   L0	   L1	   L2	   L4	   L5
# 	G1	G1@0	----	----	G1@4	----
# 	G2	G2@0	----	----	----	----
# 	G3	G3@0	----	----	G3@4	----
# ...
# Galileo:
# 		   L0	   L1	   L2	   L4	   L5
# 	E1	----	E1@1	----	----	E1@5
# 	E2	----	E2@1	----	----	E2@5
# 	E3	----	E3@1	----	----	E3@5
# ...
# 
# etc.

tmp=/tmp/_$$

trap "rm ${tmp}; exit 0" 0 1 2 15

LOG=${1-/run/ubxtool/stderr.log}
sed -n -e '/currently receiving: /s/.*currently receiving: //p' < ${LOG} | tr ' ' '\012' | egrep @ | sort -u > ${tmp}
list_of_channels=`uniq < ${tmp} | sed -e 's/.*@//' | sort -nu`
list_of_satellites=`uniq < ${tmp} | sed -e 's/@.*//' | sort -t, -n | uniq`
while read gnss_name gnss_letter gnss_number
do
	echo ${gnss_name}:

		echo -ne '\t'
		echo -ne '\t'
		for freq in ${list_of_channels}
		do
			echo -ne "   L${freq}"'\t'
		done
		echo ''

	for sat in ${list_of_satellites}
	do
		case ${sat} in
		${gnss_number},*)
			;;
		*)
			continue
			;;
		esac
		echo -ne '\t'
		sat_pretty=`echo ${sat} | sed -e "s/^[0-9],/${gnss_letter}/" -e '/^[A-Z][0-9]$/s/^./&0/'`
		echo -ne ${sat_pretty}'\t'
		for freq in ${list_of_channels}
		do
			if grep "${sat}@${freq}" ${tmp} > /dev/null
			then
				echo -ne "${sat_pretty}@${freq}"'\t'
			else
				echo -ne '-----\t'
			fi
		done
		echo ''
	done
	echo ''
done << !!
GPS	G	0
SBAS	S	1
Galileo	E	2
BeiDou	B	3
IMES	I	4
QZSS	Q	5
GLONASS	R	6
NavIC	N	7
!!

exit 0
