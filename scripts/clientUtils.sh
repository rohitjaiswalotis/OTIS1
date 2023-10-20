#!/usr/bin/env bash


# install package by version id

function installPackage {
	
	local versionId="$1"
	local credentials="$2"
	local options="${3:-"{}"}"
	
	local devHubAlias="$(echo $credentials | jq -r '.devHubAlias // empty')";
	
	local username="$(echo $credentials | jq -r '.username')";
	local password="$(echo $credentials | jq -r '.password')";
	local serverurl="$(echo $credentials | jq -r '.url')";
	local token="$(echo $credentials | jq -r '.token // empty')";
	local orgAlias="$(echo $credentials | jq -r '.orgAlias // empty')";
	local authFile="$(echo $credentials | jq -r '.authFile // empty')";
	
	local organization="$(echo $options | jq -r '.organization // empty')";
	local project="$(echo $options | jq -r '.project // empty')";
	local projectId="$(echo $options | jq -r '.projectId // empty')";
	
	local localizationDomain="$(echo $options | jq -r '.localizationDomain // empty')";
	
	local installKey="$(echo $options | jq -r '.installKey // empty')";
	
	local securityType="$(echo $options | jq -r '.securityType // "AdminsOnly"')";
	local waitPublish="$(echo $options | jq -r '.waitPublish // 1000')";
	local waitInstall="$(echo $options | jq -r '.waitInstall // 1000')";
	
	local versionComparison="$(echo $options | jq -r '.versionComparison // true')";
	
	local validateMode="$(echo $options | jq -r '.validateMode // false')";
	local debugMode="$(echo $options | jq -r '.debugMode // false')";
	
	local MONITOR="$(mktemp)"
	
	
	if ! [[ ${orgAlias:+1} ]]; then
		
		orgAlias="installPackageOrg_$(date +%s)"
		
		# log in to org using credentials
		local loginResponse=$(sf sfpowerkit:auth:login -a "$orgAlias" -u "${username,,}" -p "${password}" -r "${serverurl}" --json | tee $MONITOR);
		local statusCode=$(echo "$loginResponse" | jq -r '.status // 1');
		
		if [[ $statusCode -ne 0 ]]; then
			echo "Cannot log in as '$username' into dev hub org"
			return 101
		fi
		
	fi
	
	
	# query package version info
	local versionInfo=$(sf data query --use-tooling-api --target-org "$orgAlias" -q "SELECT Id, Name, MajorVersion, MinorVersion, PatchVersion, BuildNumber, SubscriberPackageId, ReleaseState, IsBeta, IsDeprecated, IsSecurityReviewed, InstallValidationStatus, Package2ContainerOptions, Dependencies FROM SubscriberPackageVersion WHERE Id='$versionId'" --json | tee $MONITOR | jq -r ".result.records[0] // empty" || true);
	local packageId=$(echo $versionInfo | jq -r ".SubscriberPackageId // empty" || true);
	local packageType=$(echo $versionInfo | jq -r ".Package2ContainerOptions // empty" || true);
	local versionName=$(echo $versionInfo | jq -r ".Name // empty" || true);

	local versionMajor=$(echo $versionInfo | jq -r ".MajorVersion // empty" || true);
	local versionMinor=$(echo $versionInfo | jq -r ".MinorVersion // empty" || true);
	local versionPatch=$(echo $versionInfo | jq -r ".PatchVersion // empty" || true);
	local versionBuild=$(echo $versionInfo | jq -r ".BuildNumber // empty" || true);
	local versionNumber="${versionMajor}.${versionMinor}.${versionPatch}.${versionBuild}"

	# query extra package info
	local packageInfo=$(sf data query --use-tooling-api --target-org  "$orgAlias" -q "SELECT Id, Name, NamespacePrefix, IsPackageValid, Description FROM SubscriberPackage WHERE Id='$packageId'" --json | tee $MONITOR | jq -r ".result.records[0] // empty" || true);
	local packageName=$(echo $packageInfo | jq -r ".Name // empty" || true);
	local packageNamespace=$(echo $packageInfo | jq -r ".NamespacePrefix // empty" || true);
	
	
	echo "Need to figure out whether install is required for ${packageNamespace:-'no namespace'} package '$packageName' ($packageId) version '$versionName' ($versionNumber, $versionId)"
	
	
	# create temporary project

	local tmpWorkspaceDir=`mktemp -d`
	pushd "$tmpWorkspaceDir"

	local tmpProjectDir="TmpProject_GetInstalledPackages"

	sf project generate --name $tmpProjectDir --template standard > /dev/null
	cd $tmpProjectDir
	
	echo "Fetching installed packages from org..."
	
	local versionNeedsToBeInstalled=0;
	
	# fetch packages installed into org
	local listInstalledPackagesResponse=$(sf package installed list --target-org "$orgAlias" --json | tee $MONITOR);
	statusCode=$(echo "$listInstalledPackagesResponse" | jq -r '.status // 2');
	
	
	if [[ ${versionComparison,,} =~ ^true$ && $statusCode -eq 0 ]]; then
		
		echo "Successfully retrieved list of installed packages from org"
		
		# match package version by 15-char case-sensitive id
		local packageVersionDetails=$(echo "$listInstalledPackagesResponse" | jq -c ".result[] | select( ( ( .SubscriberPackageVersionId | .[0:15] ) == ( \"$versionId\" | .[0:15]) ) ) ");
		
		if [[ ${packageVersionDetails:+1} ]]; then
			
			echo "'${packageName}' (${packageNamespace:-"no namespace"}) package version ${versionNumber} is already installed into org - nothing to do here!"
			versionNeedsToBeInstalled=0
			
			# format json nicely
			packageVersionDetails=$(echo "$packageVersionDetails" | jq .)
			echo "$packageVersionDetails"
			
			# validate mode
			if [[ "${validateMode,,}" =~ ^true$ ]] ; then
				echo "Validate mode is ON: '${packageName}' (${packageNamespace:-"no namespace"}) package version ${versionNumber} cannot be installed since it is already installed into org"
				return 107;
			fi
			
			return 0;
			
		fi
		
		
		# get installed version of the same package (if any)
		local installedPackage=$(echo $listInstalledPackagesResponse | jq -c ".result[] | select( ( ( .SubscriberPackageId | .[0:15] ) == ( \"$packageId\" | .[0:15]) ) ) // empty" || true);
		
		if [[ ${installedPackage:+1} ]]; then
			
			local installedVersionId=$(echo $installedPackage | jq -r ".SubscriberPackageVersionId // empty" || true);
			local installedVersionName=$(echo $installedPackage | jq -r ".SubscriberPackageVersionName // empty" || true);
			local installedVersionNumber=$(echo $installedPackage | jq -r ".SubscriberPackageVersionNumber // empty" || true);
			
			echo "Found installed version '$installedVersionName' ($installedVersionId, $installedVersionNumber)"
			
			local installedMajor=$((`echo $installedVersionNumber | cut -d"." -f1`));
			local installedMinor=$((`echo $installedVersionNumber | cut -d"." -f2`));
			local installedPatch=$((`echo $installedVersionNumber | cut -d"." -f3`));
			local installedBuild=$((`echo $installedVersionNumber | cut -d"." -f4`));
			
			# get installed version extra info
			local installedVersion=$(sf data query --use-tooling-api --target-org "$orgAlias" -q "SELECT Id, Name, MajorVersion, MinorVersion, PatchVersion, BuildNumber, SubscriberPackageId, ReleaseState, IsBeta, IsDeprecated, IsSecurityReviewed, InstallValidationStatus, Dependencies FROM SubscriberPackageVersion WHERE Id='$installedVersionId'" --json | tee $MONITOR | jq -r ".result.records[0] // empty" || true);
			local installedVersionIsBeta=$(echo $installedVersion | jq -r ".IsBeta // empty" || true);
			
			
			# compare semantic versions to decide whether dependency version is newer and should be installed
			if [[ $installedMajor -gt $versionMajor ]]; then 
				versionNeedsToBeInstalled=0;
			elif [[ $installedMajor -lt $versionMajor ]]; then 
				versionNeedsToBeInstalled=1;
			elif [[ $installedMinor -gt $versionMinor ]]; then 
				versionNeedsToBeInstalled=0;
			elif [[ $installedMinor -lt $versionMinor ]]; then 
				versionNeedsToBeInstalled=1;
			elif [[ $installedPatch -gt $versionPatch ]]; then 
				versionNeedsToBeInstalled=0;
			elif [[ $installedPatch -lt $versionPatch ]]; then 
				versionNeedsToBeInstalled=1;
			elif [[ $installedBuild -gt $versionBuild ]]; then 
				versionNeedsToBeInstalled=0;
			elif [[ $installedBuild -lt $versionBuild ]]; then 
				versionNeedsToBeInstalled=1;
			else
				versionNeedsToBeInstalled=0;
			fi
		  
			if [[ $versionNeedsToBeInstalled -eq 1 ]]; then 
				
				echo "'${packageName}' (${packageNamespace:-"no namespace"}) package version ${versionNumber} should be upgraded: older version is currently installed (${installedVersionNumber})"
				
				# prevent upgrade on top of beta package except for unlocked package
				if [[ "${installedVersionIsBeta,,}" =~ ^true$ && "${packageType,,}" != "unlocked" ]]; then 
					echo "ERROR: Currently installed '${packageName}' (${packageNamespace:-"no namespace"}) package version $installedVersionNumber is beta. Cannot upgrade to '${packageName}' (${packageNamespace:-"no namespace"}) package version $versionNumber on top of beta version!";
					return 102;
				fi
				
			else
				
				# validate mode
				if [[ "${validateMode,,}" =~ ^true$ ]] ; then
					echo "Validate mode is ON: '${packageName}' (${packageNamespace:-"no namespace"}) package version ${versionNumber} cannot be upgraded: installed version is more recent (${installedVersionNumber})"
					return 108;
				else 
					echo "'${packageName}' (${packageNamespace:-"no namespace"}) package version ${versionNumber} should NOT be upgraded: currently installed version is fine (${installedVersionNumber})"
					return 0;
				fi
				
			fi
			
		else
			
			versionNeedsToBeInstalled=1;
			echo "'${packageName}' (${packageNamespace:-"no namespace"}) package version ${versionNumber} should be installed: no package version installed at all."
			
		fi
		
		
	elif [[ ! ${versionComparison,,} =~ ^true$ ]]; then
		
		echo "Version comparison is disabled, so going to install '${packageName}' (${packageNamespace:-"no namespace"}) package version ${versionNumber} anyway!"
		
		# imitate success code to try to install anyway due to disabled version comparison
		statusCode=0;
		versionNeedsToBeInstalled=1;
		
	else
		
		echo "Cannot read list of installed packages from org to check if '${packageName}' (${packageNamespace:-"no namespace"}) package version '$versionId' is already installed!"
		
		# suppress error deliberately to try to install anyway
		statusCode=0;
		versionNeedsToBeInstalled=1;
		
	fi
	
	
	# install package version into org (if proves to be needed)
	if [[ $statusCode -eq 0 && $versionNeedsToBeInstalled -eq 1 ]]; then
		
		# validate mode
		if [[ "${validateMode,,}" =~ ^true$ ]] ; then
			
			echo "Validate mode is ON: no obstacles detected to install '${packageName}' (${packageNamespace:-"no namespace"}) package version ${versionNumber}"
			return 0;
			
		# debug mode
		elif [[ "${debugMode,,}" =~ ^true$ ]] ; then
			
			echo "Debug mode is ON: no actual installation is happening!"
			echo sf package install --target-org "$orgAlias" -p "$versionId" --installation-key="${installKey}" --security-type="${securityType}" --no-prompt --wait="${waitInstall}" --publish-wait="${waitPublish}"
			
		# real mode
		else
			
			# installing package suppressing all errors along the way (but response is printed to the terminal anyway)
			sf package install --target-org "$orgAlias" -p "$versionId" --installation-key="${installKey}" --security-type="${securityType}" --no-prompt --wait="${waitInstall}" --publish-wait="${waitPublish}" || true
			
			# print installed packages into org again after installation to visually inspect results
			sf package installed list --target-org "$orgAlias"
			
			# check if package version is among installed into org
			listInstalledPackagesResponse=$(sf package installed list --target-org "$orgAlias" --json | tee $MONITOR);
			packageVersionDetails=$(echo "$listInstalledPackagesResponse" | jq -c ".result[] | select( ( ( .SubscriberPackageVersionId | .[0:15] ) == ( \"$versionId\" | .[0:15]) ) ) ");
			
			# installed succefully
			if [[ ${packageVersionDetails:+1} ]]; then
				
				echo "'${packageName}' (${packageNamespace:-"no namespace"}) package version '$versionName' ${versionNumber} ($versionId) has been successfully installed into org."
				
				# format json nicely
				packageVersionDetails=$(echo "$packageVersionDetails" | jq .)
				echo "$packageVersionDetails"
			
			# failure
			else
				
				echo "ERROR: '${packageName}' (${packageNamespace:-"no namespace"}) package version '$versionName' ${versionNumber} ($versionId) has NOT been installed into org."
		  
				return 111;
		  
			fi
			
		fi
		
	fi
	
	
	popd
	rm -r "$tmpWorkspaceDir"
	
	return 0;
	
}



# install package dependencies for version id

function installPackageDependencies {
	
	local versionId="$1"
	local credentials="$2"
	local options="${3:-"{}"}"
	
	local devHubAlias="$(echo $credentials | jq -r '.devHubAlias // empty')";
	
	local username="$(echo $credentials | jq -r '.username')";
	local password="$(echo $credentials | jq -r '.password')";
	local serverurl="$(echo $credentials | jq -r '.url')";
	local token="$(echo $credentials | jq -r '.token // empty')";
	local orgAlias="$(echo $credentials | jq -r '.orgAlias // empty')";
	local authFile="$(echo $credentials | jq -r '.authFile // empty')";
	
	local organization="$(echo $options | jq -r '.organization // empty')";
	local project="$(echo $options | jq -r '.project // empty')";
	local projectId="$(echo $options | jq -r '.projectId // empty')";
	
	local localizationDomain="$(echo $options | jq -r '.localizationDomain // empty')";
	
	local securityType="$(echo $options | jq -r '.securityType // "AdminsOnly"')";
	local waitPublish="$(echo $options | jq -r '.waitPublish // 1000')";
	local waitInstall="$(echo $options | jq -r '.waitInstall // 1000')";
	
	local versionComparison="$(echo $options | jq -r '.versionComparison // true')";
	
	local majorDiff="$(echo $options | jq -r '.majorDiff // true')";
	local minorDiff="$(echo $options | jq -r '.minorDiff // true')";
	local patchDiff="$(echo $options | jq -r '.patchDiff // false')";
	local betaDiff="$(echo $options | jq -r '.betaDiff // false')";
	
	local validateMode="$(echo $options | jq -r '.validateMode // false')";
	local debugMode="$(echo $options | jq -r '.debugMode // false')";
	
	local MONITOR="$(mktemp)"
	
	
	# check if package version can be installed into target org at all
	local optionsWithValidateMode=$(echo "$options" | jq '. + { validateMode: true }')
	installPackage $versionId "$credentials" "$optionsWithValidateMode"; local validateStatusCode=$?
	
	if [[ $validateStatusCode -ne 0 ]]; then
		
		if [[ $validateStatusCode -eq 107 ]]; then
			echo "Same package version as $versionId is already installed: no further actions re dependencies installation to be taken."
			exit 0;
		elif [[ $validateStatusCode -eq 108 ]]; then
			echo "More recent package version than $versionId is already installed: no further actions re dependencies installation to be taken."
			exit 0;
		else
			echo "Package version $versionId validation has failed: no further actions re dependencies installation to be taken."
			return 114;
		fi
		
	else
		
		echo "Package version $versionId validation has succeeded: continue further with installing dependencies..."
		
	fi
	
	
	if ! [[ ${orgAlias:+1} ]]; then
		
		orgAlias="installPackageDepsOrg_$(date +%s)"
		
		# log in to org using credentials
		local loginResponse=$(sfdx sfpowerkit:auth:login -a "$orgAlias" -u "${username,,}" -p "${password}" -r "${serverurl}" --json | tee $MONITOR);
		local statusCode=$(echo "$loginResponse" | jq -r '.status // 1');
		
		if [[ $statusCode -ne 0 ]]; then
			echo "Cannot log in as '$username' into dev hub org"
			return 101;
		fi
		
	fi
	
	
	# query dependencies for package version
	local packageVersion=$(sf data query --use-tooling-api --target-org "$orgAlias" -q "SELECT Id, Name, MajorVersion, MinorVersion, PatchVersion, BuildNumber, SubscriberPackageId, ReleaseState, IsBeta, IsDeprecated, IsSecurityReviewed, InstallValidationStatus, Package2ContainerOptions, Dependencies FROM SubscriberPackageVersion WHERE Id='$versionId'" --json | tee $MONITOR | jq -r ".result.records[0] // empty" || true);
	local packageId=$(echo $packageVersion | jq -r ".SubscriberPackageId // empty" || true);
	local packageType=$(echo $versionInfo | jq -r ".Package2ContainerOptions // empty" || true);
	local versionName=$(echo $packageVersion | jq -r ".Name // empty" || true);
	local listDependenciesIds=$(echo $packageVersion | jq -r "(.Dependencies.ids[].subscriberPackageVersionId)? // empty" || true);
	
	# query extra package info
	local packageInfo=$(sf data query --use-tooling-api --target-org "$orgAlias" -q "SELECT Id, Name, NamespacePrefix, IsPackageValid, Description FROM SubscriberPackage WHERE Id='$packageId'" --json | tee $MONITOR | jq -r ".result.records[0] // empty" || true);
	local packageName=$(echo $packageInfo | jq -r ".Name // empty" || true);
	local packageNamespace=$(echo $packageInfo | jq -r ".NamespacePrefix // empty" || true);
	
	
	echo "Need to figure out and install dependencies for ${packageNamespace:-'no namespace'} package '$packageName' ($packageId) version '$versionName' ($versionId)"
	
	
	# early exit - no dependencies detected
	if ! [[ ${listDependenciesIds:+1} ]]; then
	  echo "No dependencies detected!"
	  return 0;
	fi
	
	
	# create temporary project

	local tmpWorkspaceDir=`mktemp -d`
	pushd "$tmpWorkspaceDir"

	local tmpProjectDir="TmpProject_GetInstalledPackages"

	sfdx force:project:create -n $tmpProjectDir --template standard > /dev/null
	cd $tmpProjectDir
	
	echo "Fetching installed packages from org..."
	
	# fetch installed packages from org
	local listInstalledPackagesResponse=$(sf package installed list --target-org "$orgAlias" --json | tee $MONITOR || true);
	
	
	# iterate over dependencies
	for dependencyVersionId in $(echo "$listDependenciesIds"); do
		
		# get dependency version info
		local dependencyVersion=$(sf data query --use-tooling-api --target-org "$orgAlias" -q "SELECT Id, Name, MajorVersion, MinorVersion, PatchVersion, BuildNumber, SubscriberPackageId, ReleaseState, IsBeta, IsDeprecated, IsSecurityReviewed, InstallValidationStatus, Package2ContainerOptions, Dependencies FROM SubscriberPackageVersion WHERE Id='$dependencyVersionId'" --json | tee $MONITOR | jq -r ".result.records[0] // empty" || true);
		local dependencyPackageId=$(echo $dependencyVersion | jq -r ".SubscriberPackageId // empty" || true);
		local dependencyPackageType=$(echo $dependencyVersion | jq -r ".Package2ContainerOptions // empty" || true);
		local dependencyVersionName=$(echo $dependencyVersion | jq -r ".Name // empty" || true);
		local dependencyMajor=$(echo $dependencyVersion | jq -r ".MajorVersion // empty" || true);
		local dependencyMinor=$(echo $dependencyVersion | jq -r ".MinorVersion // empty" || true);
		local dependencyPatch=$(echo $dependencyVersion | jq -r ".PatchVersion // empty" || true);
		local dependencyBuild=$(echo $dependencyVersion | jq -r ".BuildNumber // empty" || true);
		local dependencyVersionNumber="${dependencyMajor}.${dependencyMinor}.${dependencyPatch}.${dependencyBuild}"
		
		# get dependency package info
		local dependencyPackage=$(sf data query --use-tooling-api --target-org "$orgAlias" -q "SELECT Id, Name, NamespacePrefix, IsPackageValid, Description FROM SubscriberPackage WHERE Id='$dependencyPackageId'" --json | tee $MONITOR | jq -r ".result.records[0] // empty" || true);
		local dependencyPackageName=$(echo $dependencyPackage | jq -r ".Name // empty" || true);
		local dependencyPackageNamespace=$(echo $dependencyPackage | jq -r ".NamespacePrefix // empty" || true);
		
		echo "Analyzing dependency: ${dependencyPackageNamespace:-'no namespace'} package '$dependencyPackageName' ($dependencyPackageId) version '$dependencyVersionName' ($dependencyVersionNumber, $dependencyVersionId)"
		
		
		local dependencyNeedsToBeInstalled=1
		
		# get installed version of the same package (if any)
		local installedPackage=$(echo $listInstalledPackagesResponse | jq -c ".result[] | select( ( ( .SubscriberPackageId | .[0:15] ) == ( \"$dependencyPackageId\" | .[0:15]) ) ) // empty" || true);
		
		if [[ ${versionComparison,,} =~ ^true$ && ${installedPackage:+1} ]]; then
			
			local installedVersionId=$(echo $installedPackage | jq -r ".SubscriberPackageVersionId // empty" || true);
			local installedVersionName=$(echo $installedPackage | jq -r ".SubscriberPackageVersionName // empty" || true);
			local installedVersionNumber=$(echo $installedPackage | jq -r ".SubscriberPackageVersionNumber // empty" || true);
			
			echo "Found installed version '$installedVersionName' ($installedVersionId, $installedVersionNumber)"
			
			local installedMajor=$((`echo $installedVersionNumber | cut -d"." -f1`));
			local installedMinor=$((`echo $installedVersionNumber | cut -d"." -f2`));
			local installedPatch=$((`echo $installedVersionNumber | cut -d"." -f3`));
			local installedBuild=$((`echo $installedVersionNumber | cut -d"." -f4`));
			
			# get installed version extra info
			local installedVersion=$(sf data query --use-tooling-api --target-org "$orgAlias" -q "SELECT Id, Name, MajorVersion, MinorVersion, PatchVersion, BuildNumber, SubscriberPackageId, ReleaseState, IsBeta, IsDeprecated, IsSecurityReviewed, InstallValidationStatus, Dependencies FROM SubscriberPackageVersion WHERE Id='$installedVersionId'" --json | tee $MONITOR | jq -r ".result.records[0] // empty" || true);
			local installedVersionIsBeta=$(echo $installedVersion | jq -r ".IsBeta // empty" || true);
			
			
			# compare semantic versions to decide whether dependency version is newer and should be installed
			if [[ $installedMajor -gt $dependencyMajor && "${majorDiff,,}" =~ ^true$ ]]; then 
				dependencyNeedsToBeInstalled=0;
			elif [[ $installedMajor -lt $dependencyMajor && "${majorDiff,,}" =~ ^true$ ]]; then 
				dependencyNeedsToBeInstalled=1;
			elif [[ $installedMinor -gt $dependencyMinor && "${minorDiff,,}" =~ ^true$ ]]; then 
				dependencyNeedsToBeInstalled=0;
			elif [[ $installedMinor -lt $dependencyMinor && "${minorDiff,,}" =~ ^true$ ]]; then 
				dependencyNeedsToBeInstalled=1;
			elif [[ $installedPatch -gt $dependencyPatch && "${patchDiff,,}" =~ ^true$ ]]; then 
				dependencyNeedsToBeInstalled=0;
			elif [[ $installedPatch -lt $dependencyPatch && "${patchDiff,,}" =~ ^true$ ]]; then 
				dependencyNeedsToBeInstalled=1;
			elif [[ $installedBuild -gt $dependencyBuild && "${betaDiff,,}" =~ ^true$ ]]; then 
				dependencyNeedsToBeInstalled=0;
			elif [[ $installedBuild -lt $dependencyBuild && "${betaDiff,,}" =~ ^true$ ]]; then 
				dependencyNeedsToBeInstalled=1;
			else
				dependencyNeedsToBeInstalled=0;
			fi
		  
			if [[ $dependencyNeedsToBeInstalled -eq 1 ]]; then 
				
				echo "Dependency '${dependencyPackageName}' (${dependencyPackageNamespace:-"no namespace"}) ${dependencyVersionNumber} should be upgraded: older version is currently installed (${installedVersionNumber})"
				
				if [[ "${installedVersionIsBeta,,}" =~ ^true$ && "${dependencyPackageType,,}" != "unlocked" ]]; then 
					echo "ERROR: Currently installed '${dependencyPackageName}' (${dependencyPackageNamespace:-"no namespace"}) package version $installedVersionNumber is beta. Cannot upgrade to '${dependencyPackageName}' (${dependencyPackageNamespace:-"no namespace"}) $dependencyVersionNumber on top of beta version!";
					return 102;
				fi
				
			else
				
				echo "Dependency '${dependencyPackageName}' (${dependencyPackageNamespace:-"no namespace"}) ${dependencyVersionNumber} should NOT be upgraded: currently installed version is fine (${installedVersionNumber})"
				
			fi
			
		elif [[ ! ${versionComparison,,} =~ ^true$ ]]; then
			
			dependencyNeedsToBeInstalled=1;
			echo "Version comparison is disabled, so going to install dependency '${dependencyPackageName}' (${dependencyPackageNamespace:-"no namespace"}) ${dependencyVersionNumber} anyway!"
			
		else
			
			dependencyNeedsToBeInstalled=1;
			echo "Dependency '${dependencyPackageName}' (${dependencyPackageNamespace:-"no namespace"}) ${dependencyVersionNumber} should be installed: no package version installed at all."
			
		fi
		
		
		if [[ $dependencyNeedsToBeInstalled -eq 1 ]]; then 
			
			if [[ "${debugMode,,}" =~ ^true$ ]] ; then
				
				echo "Debug mode is ON: no actual installation is happening!"
				echo installPackage $dependencyVersionId "$credentials" "$options"
				
			else
				
				# check if special installation of dependency package is required via pipeline
				local specialInstallPipeline="$(echo $PACKAGENAMETOINSTALLPIPELINE | jq -r ".\"$dependencyPackageName\" // empty")"
				
				if [[ ${specialInstallPipeline:+1} ]]; then
					
					echo "Package '$dependencyPackageName' should be installed only via special pipeline '$specialInstallPipeline'."
					
					# grab tag name from dev hub for package version to pass as parameter to installation pipeline
					local dependencyVersionTag=$(sf data query --use-tooling-api --target-org "$devHubAlias" -q "SELECT Id, SubscriberPackageVersionId, Tag FROM Package2Version WHERE SubscriberPackageVersionId='$dependencyVersionId'" --json | tee $MONITOR | jq -r ".result.records[0].Tag // empty" || true);
					
					if [[ ! ${dependencyVersionTag:+1} ]]; then
						echo "Pipeline '$specialInstallPipeline': status=$AZ_INSTALL_PIPELINE_STATUS result=$AZ_INSTALL_PIPELINE_RESULT"
						echo "ERROR: Cannot get related tag for package '$dependencyPackageName' version with id ${dependencyVersionId}!"
						exit -1
					fi
					
					# differentiate between tag/branch and commit SHA to trigger install pipeline at
					if [[ "${dependencyVersionTag}" == *"-"* ]]; then 
						AZ_INSTALL_PIPELINE_CHECKOUT="--branch=\"refs/tags/${dependencyVersionTag}\""
					else
						AZ_INSTALL_PIPELINE_CHECKOUT="--commit-id=\"${dependencyVersionTag}\""
					fi
					
					
					# split pipeline name to separate folder
					specialInstallPipelineFolder="$(echo $specialInstallPipeline | cut -d "/" -f1)";
					specialInstallPipelineName="$(echo $specialInstallPipeline | cut -d "/" -f2)";
					
					if [[ "${specialInstallPipelineName,,}" == "${specialInstallPipelineFolder,,}" ]]; then
						AZ_INSTALL_PIPELINE_FOLDER_PATH=""
					else
						AZ_INSTALL_PIPELINE_FOLDER_PATH="--folder-path=\"$specialInstallPipelineFolder\""
					fi
					
					# trigger package version install pipeline
					AZ_INSTALL_PIPELINE_TRIGGER_RESPONSE=$(eval "az pipelines run --organization \"$organization\" --project \"$project\" $AZ_INSTALL_PIPELINE_CHECKOUT --name=\"$specialInstallPipelineName\" $AZ_INSTALL_PIPELINE_FOLDER_PATH --parameters \"versionId=$dependencyVersionId\" \"localizationDomain=$localizationDomain\" \"targetOrgUrl=${serverurl}\" \"targetOrgUsername=${username}\" \"targetOrgPassword=${password}\" \"targetOrgAuthFileName=${authFile}\" \"targetOrgToken=${token}\" \"autoInstallDependencies=true\""); AZ_INSTALL_PIPELINE_TRIGGER_CODE=$?;
					echo $AZ_INSTALL_PIPELINE_TRIGGER_RESPONSE
					
					# grab pipeline run id from response
					AZ_INSTALL_PIPELINE_RUN_ID=$(echo $AZ_INSTALL_PIPELINE_TRIGGER_RESPONSE | jq -r ".id");
					echo "Install Pipeline Run Id: $AZ_INSTALL_PIPELINE_RUN_ID"
					
					if [[ ! ${AZ_INSTALL_PIPELINE_RUN_ID:+1} || $AZ_INSTALL_PIPELINE_TRIGGER_CODE -ne 0 ]]; then
						echo "ERROR: Cannot trigger pipeline '$specialInstallPipeline' to install package '$dependencyPackageName'."
						exit -1
					fi
					
					# generate web link to triggered install pipeline from pieces
					echo "Install Pipeline Web Url: ${organization}${projectId}/_build/results?buildId=$AZ_INSTALL_PIPELINE_RUN_ID"
					
					
					# wait for pipeline to finish: either succeed or fail
					while true; do 
						
						# show pipeline run details by id
						AZ_INSTALL_PIPELINE_RUN_DETAILS_RESPONSE=$(az pipelines runs show --organization "$organization" --project "$project" --id="$AZ_INSTALL_PIPELINE_RUN_ID");
						
						AZ_INSTALL_PIPELINE_STATUS=$(echo $AZ_INSTALL_PIPELINE_RUN_DETAILS_RESPONSE | jq -r ".status // empty");
						AZ_INSTALL_PIPELINE_RESULT=$(echo $AZ_INSTALL_PIPELINE_RUN_DETAILS_RESPONSE | jq -r ".result // empty");
						
						echo "Pipeline '$specialInstallPipeline': status=$AZ_INSTALL_PIPELINE_STATUS result=$AZ_INSTALL_PIPELINE_RESULT"
						
						if [[ "${AZ_INSTALL_PIPELINE_STATUS,,}" == "completed" ]] ; then
							echo "Pipeline '$specialInstallPipeline' to install package '$dependencyPackageName' has finished."
							break;
						else
							sleep 60
						fi
						
					done;
					
					
					if [[ "${AZ_INSTALL_PIPELINE_RESULT,,}" != "succeeded" ]] ; then
						echo $AZ_INSTALL_PIPELINE_RUN_DETAILS_RESPONSE
						echo "Pipeline '$specialInstallPipeline': status=$AZ_INSTALL_PIPELINE_STATUS result=$AZ_INSTALL_PIPELINE_RESULT"
						echo "ERROR: Pipeline '$specialInstallPipeline' to install package '$dependencyPackageName' has failed."
						exit -1
					fi
					
				else
					
					echo "No special install pipeline is required for package '$dependencyPackageName'."
					
					installPackageWithDependencies $dependencyVersionId "$credentials" "$options"
					
					local dependencyInstallStatusCode=$?
					
					if [[ $dependencyInstallStatusCode -eq 0 ]]; then
						echo "Successfully installed dependency: ${dependencyPackageNamespace:-'no namespace'} package '$dependencyPackageName' ($dependencyPackageId) version '$dependencyVersionName' ($dependencyVersionId)"
					else
						echo "Error installing dependency (code=$dependencyInstallStatusCode): ${dependencyPackageNamespace:-'no namespace'} package '$dependencyPackageName' ($dependencyPackageId) version '$dependencyVersionName' ($dependencyVersionId)"
						return $dependencyInstallStatusCode;
					fi
					
				fi
				
			fi
			
		fi
		
	done
	
	
	popd
	rm -r "$tmpWorkspaceDir"
	
	
	return 0;
	
}



# install package with dependencies
function installPackageWithDependencies {
	
	# installing dependencies first (if any)
	installPackageDependencies "$@"
	
	local dependenciesInstallStatusCode=$?
	
	if [[ $dependenciesInstallStatusCode -ne 0 ]]; then
		echo "Error installing dependencies (code=$dependenciesInstallStatusCode)."
		return $dependenciesInstallStatusCode;
	fi
	
	
	# afterwards installing package itself
	installPackage "$@"
	
	local packageInstallStatusCode=$?
	
	if [[ $packageInstallStatusCode -ne 0 ]]; then
		echo "Error installing dependencies (code=$packageInstallStatusCode)."
		return $packageInstallStatusCode;
	fi
	
	
	return 0;
	
}


