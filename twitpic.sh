#!/bin/bash
SHIFT=0
VERBOSE=0
filename="`basename $0`"
BASENAME="${filename%.*}"
WGETBIN="`which wget`"
usage()
{
cat << EOF
usage: $0 [options] username

This script downloads all twitpics for a specified account. 

OPTIONS:
	-h	Show this message
	-o	Specifies the output path
	-l	Specifies a logfile (default:./$BASENAME.log)
	-v	Be verbose
EOF
}

function logger {
	LOGLINE="`date +%Y-%m-%d_%H:%M:%S` [$$] - $@"
	echo $LOGLINE >> $LOGFILE
	[ $VERBOSE -eq 1 ] && echo $LOGLINE
}

while getopts “hvo:l:” OPTION
do
	case $OPTION in
	h)
		usage
		exit 1
		;;
	o)
		OUTPUTPATH=$OPTARG
		SHIFT=$(($SHIFT + 2))
		;;
	v)
		VERBOSE=1
		SHIFT=$(($SHIFT + 1))
		;;
	l)
		LOGFILE=$OPTARG
		SHIFT=$(($SHIFT + 2))
		;;
	?)
		usage
		exit
		;;
	esac
done

shift $SHIFT

[[ -z $OUTPUTPATH ]] && OUTPUTPATH="`pwd`"
[[ -z $LOGFILE ]] && LOGFILE="$BASENAME.log"

URL="http://api.twitpic.com/2/users/show.json?username=$1"
LIST="`$WGETBIN -q -O- $URL | grep -o '\"short_id\":\"[0-9a-Z]*\"' | awk -F'":"' '{print $2}' | tr '" ' '\n'`"

logger "found `echo $LIST | wc -w` images"
counter=1
for i in $LIST; do
	logger "downloading image #$counter id:$i"
	$WGETBIN -q -O $OUTPUTPATH/$i.jpg http://twitpic.com/show/full/$i
	counter=$(($counter + 1))
done
