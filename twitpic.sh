#!/bin/bash
VERBOSE=0
filename="`basename $0`"
BASENAME="${filename%.*}"
WGETBIN="`which wget`"
PARALLEL=0
usage()
{
cat << EOF
usage: $0 [options] username

This script downloads all twitpics for a specified account. 

OPTIONS:
	-h	Show this message
	-o	Specifies the output path
	-l	Specifies a logfile (default:./$BASENAME.log)
	-p	Parallel download of images
	-v	Be verbose
EOF
}

function logger {
	LOGLINE="`date +%Y-%m-%d_%H:%M:%S` [$$] - $@"
	echo $LOGLINE >> $LOGFILE
	[ $VERBOSE -eq 1 ] && echo $LOGLINE
}

while getopts “hvo:l:p” OPTION
do
	case $OPTION in
	h)
		usage
		exit 1
		;;
	o)
		OUTPUTPATH=$OPTARG
		;;
	v)
		VERBOSE=1
		;;
	p)
		PARALLEL=1
		;;
	l)
		LOGFILE=$OPTARG
		;;
	?)
		usage
		exit
		;;
	esac
done

shift $((OPTIND-1))

[[ -z $OUTPUTPATH ]] && OUTPUTPATH="`pwd`"
[[ -z $LOGFILE ]] && LOGFILE="$BASENAME.log"

URL="http://api.twitpic.com/2/users/show.json?username=$1"
PHOTOCOUNT=`$WGETBIN -q -O- $URL | sed 's/.*photo_only_count\":\([0-9]*\).*/\1/'`
PAGES=$(($PHOTOCOUNT/20))
logger "found $PHOTOCOUNT images"
for p in `seq 1 $PAGES`; do
	PURL="${URL}&page=$p"
	echo $PURL
	LIST="`$WGETBIN -q -O- $PURL | grep -o '\"short_id\":\"[0-9a-Z]*\"' | awk -F'":"' '{print $2}' | tr '" ' '\n'`"
	
	counter=1
	for i in $LIST; do
		logger "downloading image id:$i"
		if [[ $PARALLEL -eq 0 ]]; then
			$WGETBIN -q -O $OUTPUTPATH/$i.jpg http://twitpic.com/show/full/$i
		else
			$WGETBIN -q -O $OUTPUTPATH/$i.jpg http://twitpic.com/show/full/$i &
		fi
		counter=$(($counter + 1))
	done
done
