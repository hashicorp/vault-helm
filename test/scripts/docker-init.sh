#!/bin/bash
SCRIPT_NAME="$(basename ${BASH_SOURCE[0]})"
pushd $(dirname ${BASH_SOURCE[0]}) > /dev/null
SCRIPT_DIR=$(pwd)
popd > /dev/null

function usage {
cat <<-EOF
Usage: ${SCRIPT_NAME} [<options ...>]
Description:
   This script will install the necessary components for a Docker-based
   test.
   This script will build the consul-k8s binary on the local system.
   All the requisite tooling must be installed for this to be
   successful.
Options:
   -s | --source     DIR         Path to source to build.
                                 Defaults to "${SOURCE_DIR}"
   -o | --os         OSES        Space separated string of OS
                                 platforms to build.
   -a | --arch       ARCH        Space separated string of
                                 architectures to build.
   -h | --help                   Print this help text.
EOF
}

function main {
   declare sdir="${SOURCE_DIR}"
   declare build_os=""
   declare build_arch=""

   while test $# -gt 0
   do
      case "$1" in
         -h | --help )
            usage
            return 0
            ;;
         * )
            err_usage "ERROR: Unknown argument: '$1'"
            return 1
            ;;
      esac
   done

   build_consul_local "${sdir}" "${build_os}" "${build_arch}" || return 1
   return 0
}

main "$@"
exit $?
