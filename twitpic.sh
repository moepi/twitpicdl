#!/bin/bash
SHIFT=1
VERBOSE=0
usage()
{
cat << EOF
usage: $0 [options] username

This script downloads all twitpics for a specified account. 

OPTIONS:
	-h	Show this message
EOF
}

function logger {
	LOGLINE="`date +%Y-%m-%d_%H:%M:%S` [$$] - $@"
	#echo $LOGLINE >> $LOGFILE
	[ $VERBOSE -eq 1 ] && echo $LOGLINE
}

while getopts “hvo:” OPTION
do
	case $OPTION in
	h)
		usage
		exit 1
		;;
	o)
		OUTPUTPATH=$OPTARG
		SHIFT=$(($SHIFT + 1))
		;;
	v)
		VERBOSE=1
		SHIFT=$(($SHIFT + 1))
		;;
	?)
		usage
		exit
		;;
	esac
done

shift $SHIFT

[[ -z $OUTPUTPATH ]] && OUTPUTPATH="`pwd`"

URL="http://api.twitpic.com/2/users/show.json?username=$1"
LIST="`wget -q -O- $URL | grep -o '\"short_id\":\"[0-9a-Z]*\"' | awk -F'":"' '{print $2}' | tr '" ' '\n'`"
filename="`basename $0`"
LOGFILE="${filename%.*}.log"

logger "found `echo $LIST | wc -w` images"
counter=1
for i in $LIST; do
	logger "downloading image #$counter id:$i"
	wget -q -O $OUTPUTPATH/$i.jpg http://twitpic.com/show/full/$i
	counter=$(($counter + 1))
done
