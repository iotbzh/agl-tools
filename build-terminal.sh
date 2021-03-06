#!/bin/bash

rcfile=$0
[[ "$rcfile" = "${rcfile#/}" ]] && rcfile=$PWD/$rcfile
export rcfile=${rcfile%.sh}.rc

source env.sh

function usage {
SCRIPTNAME=$(basename $0)
cat << EOT
Usage:	$SCRIPTNAME <target-name> [<build-dir>]

	target-name:	"qemu", "porter" or "silk"
	build-dir:	(optional) "build" by default.
EOT
}

#----------------------------------------
# Catch command line arguments
if [[ ! ( $# -eq 1 || $# -eq 2 ) ]]; then
	usage
	exit 1
fi

TARGET=$1
shift

if [ -z $1 ]; then
	OUTDIR="build"
else
	OUTDIR="$1"
fi

#----------------------------------------
# Target specific stuff
case $TARGET in
	qemu)
		export TEMPLATECONF=$PWD/meta-agl-demo/conf
		;;
	porter)
		copy_mum_zip porter
		export TEMPLATECONF=$PWD/meta-renesas/meta-rcar-gen2/conf
		;;
	silk)
		copy_mum_zip silk
		# FIXME: export TEMPLATECONF=$PWD/meta-renesas/meta-rcar-gen2/conf
		export TEMPLATECONF=$PWD/meta-renesas/meta-rcar-gen2/conf
		echo "*** WARNING ***"
		echo " silk local.conf.template is not available... using porter's one instead."
		echo " generate ones from porter's local.conf.template"
		;;
	*)
		echo "Invalid target."
		usage
		exit 2
		;;
esac

#----------------------------------------
# Import open-embedded environment
source poky/oe-init-build-env $OUTDIR

[[ $TARGET == silk ]] && {
	mv conf/local.conf conf/local.conf.tmp
	sed 's/porter/silk/' conf/local.conf.tmp > conf/local.conf
	rm conf/local.conf.tmp
	echo
	echo "*** Please check conf/local.conf for silk proper config generation. ***"
}

# overload OE variable DL_DIR from environment
[ -d "$DL_DIR" ] &&
	export BB_ENV_EXTRAWHITE="$BB_ENV_EXTRAWHITE DL_DIR"

# overload OE variable SSTATE_DIR from environment
[ -d "$SSTATE_DIR" ] &&
	export BB_ENV_EXTRAWHITE="$BB_ENV_EXTRAWHITE SSTATE_DIR"

## echo "Copy/paste following to launch build:"
## echo "    bitbake agl-demo-platform"
echo 
echo "Starting a sub-shell" # (if not, environment will be lost)
echo 
exec /bin/bash --rcfile $rcfile


