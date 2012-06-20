#!/bin/bash
VERBOSE=0
filename="`basename $0`"
BASENAME="${filename%.*}"
WGETBIN="`which wget`"
PARALLEL=0
CREATEFOLDER=0
MAXRETRIES=5
TIMEOUT=10
usage()
{
cat << EOF
usage: $0 [options] username [username2 ...]

This script downloads all twitpics for a specified account. 

OPTIONS:
	-h	Show this message
	-o	Specifies the output path
	-l	Specifies a logfile (default:./$BASENAME.log)
	-p	Parallel download of images
	-r	Number of retries of each download process (default: $MAXRETRIES)
	-t	Timeout of each download process in seconds (default: $TIMEOUT)
	-c	Create folder with user name for downloaded files
	-v	Be verbose
EOF
exit 5
}

function logger {
	LOGLINE="`date +%Y-%m-%d_%H:%M:%S` [$$] - $@"
	echo $LOGLINE >> $LOGFILE
	[ $VERBOSE -eq 1 ] && echo $LOGLINE
}

while getopts "hvo:l:pcr" OPTION
do
	case $OPTION in
	h)
		usage
		;;
	o)
		OUTPUTPATH="`pwd`/$OPTARG"
		;;
	c)
		CREATEFOLDER=1
		;;
	v)
		VERBOSE=1
		;;
	r)
		MAXRETRIES=$OPTARG
		;;
	p)
		PARALLEL=1
		;;
	l)
		LOGFILE=$OPTARG
		;;
	?)
		usage
		;;
	esac
done

shift $((OPTIND-1))

[[ -z $OUTPUTPATH ]] && OUTPUTPATH="`pwd`"
[[ -z $LOGFILE ]] && LOGFILE="$BASENAME.log"

[[ $# -lt 1 ]] && logger "no user specified." && usage

for u in $@; do
	logger "downloading photos of $u"
	[[ $CREATEFOLDER -eq 1 ]] && OUTPUTPATH="`pwd`/$u" && mkdir -p $OUTPUTPATH
	URL="http://api.twitpic.com/2/users/show.json?username=$u"
	logger "getting image count"

	for t in `seq 0 $MAXRETRIES`; do
		PHOTOCOUNT=`$WGETBIN -T$TIMEOUT -qO- $URL | sed 's/.*photo_only_count\":\([0-9]*\).*/\1/'`
		[[ -n $PHOTOCOUNT ]] && break || logger "twitpic API seems to have given random 403 Forbidden, remaining retries:$(($MAXRETRIES - $t))"
	done

	PAGES=$((PHOTOCOUNT/20))
	[[ -z $PAGES ]] && logger "no images could be found on account $u" && exit 1
	logger "found $PHOTOCOUNT images"
	for p in `seq 1 $PAGES`; do
		logger "loading images of page $p"
		PURL="${URL}&page=$p"
		for t in `seq 0 $MAXRETRIES`; do
			LIST="`$WGETBIN -T$TIMEOUT -qO- $PURL | grep -o '\"short_id\":\"[0-9a-Z]*\"' | awk -F'":"' '{print $2}' | tr '" ' '\n' | grep -v ^$`"
			[[ -n $LIST ]] && break
			[[ $t -ge $MAXRETRIES ]] && logger "Reached maximum retries" && break
			logger "twitpic API seems to have given random 403 Forbidden for page $p, remaining retries:$(($MAXRETRIES - $t))"
			
		done
		
		counter=1
		for i in $LIST; do
			logger "downloading image id:$i"
			if [[ $PARALLEL -eq 0 ]]; then
				$WGETBIN -T$TIMEOUT -qO $OUTPUTPATH/$i.jpg http://twitpic.com/show/full/$i
			else
				$WGETBIN -q -O $OUTPUTPATH/$i.jpg http://twitpic.com/show/full/$i &
			fi
			counter=$(($counter + 1))
		done
	done
done
