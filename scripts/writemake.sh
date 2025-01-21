#!/bin/bash
#
# @(#) writes a quick makefile for remaking the executable in the current
# @(#) directory and recompiling the plotting program
#
myphantomdir=${0/scripts\/writemake.sh/}
splashdir=~/splash
echo '#'
echo '#--Makefile to remake the executable and copy to this directory'
echo '#  Generated by '$0':' `date`
echo '#'
echo 'PHANTOMDIR='${0/scripts\/writemake.sh/};
echo 'SPLASHDIR='$splashdir
echo 'EDITOR=vi'
makeflags='RUNDIR="${PWD}"';
if [ $# -ge 1 ]; then
   echo 'ifndef SETUP';
   echo 'SETUP='$1;
   echo 'endif';
   makeflags=$makeflags' SETUP=${SETUP}';
fi
if [ $# -ge 2 ]; then
   echo 'KROMEPATH='${0/phantom\/scripts\/writemake.sh/krome};
   makeflags=$makeflags' KROME='$2' KROMEPATH=${KROMEPATH}';
fi
echo ''
echo 'again:'
echo '	set -e; cd ${PHANTOMDIR}; make '$makeflags'; cd -; cp ${PHANTOMDIR}/bin/phantom .; cp ${PHANTOMDIR}/bin/phantom_version .'
echo
echo 'all: again setup infile'
echo
echo '.PHONY: phantom phantomsetup phantom2power phantom2grid phantomanalysis phantomevcompare libphantom mflow'
echo 'phantom         : again'
echo 'phantomsetup    : setup'
echo 'phantom2power   : power'
echo 'phantom2grid    : grid'
echo 'phantomanalysis : analysis'
echo 'phantomevcompare: evcompare'
echo 'phantomsinks    : sinks'
echo 'libphantom      : phantomlib'
echo 'mflow           : mflow'
echo
echo 'clean:'
if [ $# -ge 2 ]; then
    echo '	cd ${PHANTOMDIR}; make clean KROME='$2' KROMEPATH=${KROMEPATH}'
else
    echo '	cd ${PHANTOMDIR}; make clean'
fi
echo 'setup:'
echo '	cd ${PHANTOMDIR}; make '$makeflags' setup; cd -; cp ${PHANTOMDIR}/bin/phantomsetup .'
echo 'moddump:'
echo '	cd ${PHANTOMDIR}; make '$makeflags' moddump; cd -; cp ${PHANTOMDIR}/bin/phantommoddump .'
echo 'analysis:'
echo '	cd ${PHANTOMDIR}; make '$makeflags' phantomanalysis; cd -; cp ${PHANTOMDIR}/bin/phantomanalysis .'
echo 'phantomlib:'
echo '	cd ${PHANTOMDIR}; make '$makeflags' libphantom; cd -; cp ${PHANTOMDIR}/bin/libphantom.so .'
echo 'pyanalysis:'
echo '	cd ${PHANTOMDIR}; make '$makeflags' pyanalysis; cd -; cp ${PHANTOMDIR}/bin/libphantom.so .; ${PHANTOMDIR}/scripts/pyphantom/writepyanalysis.sh '
echo 'power:'
echo '	cd ${PHANTOMDIR}; make '$makeflags' phantom2power; cd -; cp ${PHANTOMDIR}/bin/phantom2power .'
echo 'grid:'
echo '	cd ${PHANTOMDIR}; make '$makeflags' phantom2grid; cd -; cp ${PHANTOMDIR}/bin/phantom2grid .'
echo 'evcompare:'
echo '	cd ${PHANTOMDIR}; make '$makeflags' phantomevcompare; cd -; cp ${PHANTOMDIR}/bin/phantomevcompare .'
echo 'sinks:'
echo '	cd ${PHANTOMDIR}; make '$makeflags' phantomsinks; cd -; cp ${PHANTOMDIR}/bin/phantomsinks .'
echo 'mflow:'
echo '	cd ${PHANTOMDIR}; make '$makeflags' mflow; cd -; cp ${PHANTOMDIR}/bin/mflow .; cp ${PHANTOMDIR}/bin/ev2mdot .; cp ${PHANTOMDIR}/bin/lombperiod .'
echo 'make:'
echo '	cd ${PHANTOMDIR}; ${EDITOR} build/Makefile &'
echo 'qscript:'
echo '	@cd ${PHANTOMDIR}; make --quiet '$makeflags' qscript'
echo '%::'
echo '	cd ${PHANTOMDIR}; make '$makeflags' ${MAKECMDGOALS}; if [ -e ${PHANTOMDIR}/bin/$@ ]; then cd -; cp ${PHANTOMDIR}/bin/$@ .; fi'
echo '#'
echo '# the following are for rebuilding splash'
echo '#'
echo 'plot:'
echo '	cd ${SPLASH_DIR}; make sphNG'
echo 'plotc:'
echo '	cd ${SPLASH_DIR}; make clean'
