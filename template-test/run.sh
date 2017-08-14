#!/bin/bash

# this file tests templates created by
# dotnet new <template>


set -eux

# test requires following collections to be installed prior to running this test

collectionName="rh-dotnet20"
nodejsCollection="rh-nodejs6"

# tested templates
# format: <template> <action>
# actions:
#   new - just create template ( using dotnet new <template> )
#   build - create template and run build on it ( dotnet build )
#	build-nodejs - build with nodejs dependencies
#   run - create template and run it ( dotnet run )
#   test - create template and run its tests ( dotnet test )

# todo: angular, reactredux, react
templates="console run
classlib build
mstest test
xunit test
web build
mvc build
razor build
angular build-nodejs
reactredux build-nodejs
react build-nodejs
webapi build
webconfig new
globaljson new
nugetconfig new
sln new
page new
viewstart new
viewimports new"

tmpDir=""
passed=0
failed=0

function cleanupFunc {
	if [ -n "${tmpDir:-}" ] ; then
		rm -rf "${tmpDir}"
	fi
}


function testTemplate {
	local templateName="${1}"
	local action="${2}"

	scl enable "${collectionName}" -- dotnet new "${templateName}" || return 1
	if [ "${action}" = "new" ] ; then
		true # no additional action
	elif [ "${action}" = "build" ] ; then
		scl enable "${collectionName}" -- dotnet build || return 1
	elif [ "${action}" = "build-nodejs" ] ; then
		scl enable "${nodejsCollection}" -- npm install || return 1
		scl enable "${collectionName}" "${nodejsCollection}" -- dotnet build || return 1
	elif [ "${action}" = "run" ] ; then
		scl enable "${collectionName}" -- dotnet run || return 1
	elif [ "${action}" = "test" ] ; then
		scl enable "${collectionName}" -- dotnet test || return 1
	fi
	return 0
}


function testTemplates {
	local templateName
	local action

	while read -r line ; do
		if [ -n "${line:-}" ] ; then
			templateName="${line%% *}"
			action="${line##* }"

			mkdir -p "${tmpDir}/${templateName}"
			pushd "${tmpDir}/${templateName}"

			cat <<- EOF
			###################################
				Testing ${templateName} template
			###################################
			EOF

			if testTemplate "${templateName}" "${action}" ; then
				cat <<- EOF
				###################################
				  RESULT ( ${templateName} ) : PASSED
				###################################
				EOF
				(( ++passed ))
			else
				cat <<- EOF
				###################################
				  RESULT ( ${templateName} ) : FAILED
				###################################
				EOF
				(( ++failed ))
			fi

			popd
		fi
	done < <( printf "%s\n" "$templates" )
}

trap cleanupFunc EXIT
tmpDir="$( mktemp -d )"

testTemplates

cat <<- EOF
###################################################
  OVERAL RESULT:  total: $(( passed + failed )) passed: $(( passed  )) failed: $(( failed  ))
###################################################
EOF
