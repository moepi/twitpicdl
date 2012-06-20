#!/bin/bash
VERBOSE=0
filename="`basename $0`"
BASENAME="${filename%.*}"
WGETBIN="`which wget`"
PARALLEL=0
CREATEFOLDER=0
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
	-c	Create folder with user name for downloaded files
	-v	Be verbose
EOF
exit 5
}

function logger {
	#LOGLINE="`date +%Y-%m-%d_%H:%M:%S` [$$] - $@"
	LOGLINE="`date +%Y-%m-%d_%H:%M:%S` - $@"
	echo $LOGLINE >> $LOGFILE
	[ $VERBOSE -eq 1 ] && echo $LOGLINE
}

while getopts “hvo:l:pc” OPTION
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

	gotimagecount=0
	while [ ! $gotimagecount -eq 1 ] ; do
		PHOTOCOUNT=`$WGETBIN -qO- $URL | sed 's/.*photo_only_count\":\([0-9]*\).*/\1/'`
		[[ -n $PHOTOCOUNT ]] && gotimagecount=1 || logger "twitpic API seems to have given random 403 Forbidden, let's try again a few times"
	done

	PAGES=$((PHOTOCOUNT/20))
	logger "found $PHOTOCOUNT images"
	for p in `seq 1 $PAGES`; do
		logger "loading images of page $p"
		PURL="${URL}&page=$p"
		gotimagelist=0
		while [ ! $gotimagelist -eq 1 ] ; do
			LIST="`$WGETBIN -qO- $PURL | grep -o '\"short_id\":\"[0-9a-Z]*\"' | awk -F'":"' '{print $2}' | tr '" ' '\n' | grep -v ^$`"
			[[ $? -eq 0 ]] && gotimagelist=1 || logger "twitpic API seems to have given random 403 Forbidden for page $p, let's try again a few times"
		done
		
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
done
