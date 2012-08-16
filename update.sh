#!/bin/bash

check_root () {
	if [[ ${UID} -ne 0 ]] ; then
		echo "$0 must be run as sudo user or root"
		exit
	fi
}

check_git () {
	unset APT
	unset PACKAGE
	if [ ! $(which git) ] ; then
		echo "Missing git"
		PACKAGE+="git-core "
		APT=1
	fi

	if [ "${APT}" ] ; then
		echo "Missing Dependicies"
		echo "Please install: sudo aptitude install ${PACKAGE}"
		echo "---------------------------------------------------------"
		exit
	fi
}

check_root
check_git

git pull

