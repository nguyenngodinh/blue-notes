show_usage(){
	echo "Usage: $0 program_name" 1>&2
	exit
}

get_prg(){

	PRG_NAME="$(which $1)"
	if [ -z "$PRG_NAME" ]; then
		PRG_NAME=$1
	fi
	CHK_PRG="ldd"
	DEST=$1

	mkdir $DEST

	$CHK_PRG $PRG_NAME | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v '{}' $DEST

	cp -rvf $PRG_NAME $DEST
}




#========MAIN=========
if [ $# -ne 1 ]; then
	show_usage
else
	PRG_NAME="$(which $1)"
	if [ -z "$PRG_NAME" ]; then
		PRG_NAME=$1
	fi
	if [ -f "$PRG_NAME" ]; then
		get_prg $1
	else
		show_usage
	fi
fi
