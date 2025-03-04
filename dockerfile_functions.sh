#!/usr/bin/env bash
# shellcheck disable=SC1083,SC2086,SC2154
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Generate the common license and copyright header
print_legal() {
	cat > "$1" <<-EOI
	# ------------------------------------------------------------------------------
	#               NOTE: THIS DOCKERFILE IS GENERATED VIA "update_multiarch.sh"
	#
	#                       PLEASE DO NOT EDIT IT DIRECTLY.
	# ------------------------------------------------------------------------------
	#
	# Licensed under the Apache License, Version 2.0 (the "License");
	# you may not use this file except in compliance with the License.
	# You may obtain a copy of the License at
	#
	#      https://www.apache.org/licenses/LICENSE-2.0
	#
	# Unless required by applicable law or agreed to in writing, software
	# distributed under the License is distributed on an "AS IS" BASIS,
	# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	# See the License for the specific language governing permissions and
	# limitations under the License.
	#

	EOI
}

# Print the supported Ubuntu OS
print_ubuntu_ver() {
	if [ ${current_arch} == "armv7l" ]; then
		os_version="18.04"
	else
		os_version="20.04"
	fi

	cat >> "$1" <<-EOI
	FROM ubuntu:${os_version}

	EOI
}

# Print the supported Debian OS
print_debian_ver() {
	os_version="buster"

	cat >> "$1" <<-EOI
	FROM debian:${os_version}

	EOI
}

# Print the supported Debian OS
print_debianslim_ver() {
	os_version="buster-slim"

	cat >> "$1" <<-EOI
	FROM debian:${os_version}

	EOI
}

print_ubi_ver() {
	os_version="8.4"

	cat >> "$1" <<-EOI
	FROM registry.access.redhat.com/ubi8/ubi:${os_version}

	EOI
}

print_ubi-minimal_ver() {
	os_version="8.4"

	cat >> "$1" <<-EOI
	FROM registry.access.redhat.com/ubi8/ubi-minimal:${os_version}

	EOI
}

print_centos_ver() {
	os_version="7"

	cat >> "$1" <<-EOI
	FROM centos:${os_version}

	EOI
}

print_clefos_ver() {
	os_version="7"

	cat >> "$1" <<-EOI
	FROM clefos:${os_version}

	EOI
}

print_leap_ver() {
	os_version="15.3"

	cat >> "$1" <<-EOI
	FROM opensuse/leap:${os_version}

	EOI
}

print_tumbleweed_ver() {
	os_version="latest"

	cat >> "$1" <<-EOI
	FROM opensuse/tumbleweed:${os_version}

	EOI
}

# Print the supported Windows OS
print_windows_ver() {
	local os=$4
	case $os in
		*ltsc2019) os_version="ltsc2019" ;;
		*1909) os_version="1909" ;;
		*ltsc2016) os_version="ltsc2016" ;;
		*1809) os_version="1809" ;;
		*ltsc2022) os_version="ltsc2022" ;;
	esac

	servertype=$(echo "$file" | cut -f4 -d"/")
	nanoserver_pat="nanoserver.*"
	if [[ "$servertype" =~ ${nanoserver_pat} ]]; then
		cat >> "$1" <<-EOI
	FROM mcr.microsoft.com/windows/nanoserver:${os_version}

EOI
	else
		cat >> "$1" <<-EOI
	FROM mcr.microsoft.com/windows/servercore:${os_version}

EOI
	fi

}

# Print the supported Alpine OS - this is for musl based images
print_alpine_ver() {
	cat >> "$1" <<-EOI
	FROM alpine:3.14

	EOI
}

# Print the locale and language
print_lang_locale() {
	local os=$2
	if [ "$os" != "windows" ]; then
		cat >> "$1" <<-EOI
	ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

	EOI
	fi
}

# Select the ubuntu OS packages
print_ubuntu_pkg() {
	packages="tzdata curl ca-certificates fontconfig locales"
	# binutils is needed on JDK13+ for jlink to work https://github.com/docker-library/openjdk/issues/351
	if [[ $version -ge 13 ]]; then
		packages+=" binutils"
	fi
	cat >> "$1" <<EOI
RUN apt-get update \\
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ${packages} \\
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \\
    && locale-gen en_US.UTF-8 \\
    && rm -rf /var/lib/apt/lists/*
EOI
}

print_debian_pkg() {
  print_ubuntu_pkg "$1"
}

print_debianslim_pkg() {
  print_ubuntu_pkg "$1"
}

print_windows_pkg() {
	servertype=$(echo "$file" | cut -f4 -d"/")
	nanoserver_pat="nanoserver.*"
	if [[ "$servertype" =~ ${nanoserver_pat} ]]; then
    	cat >> "$1" <<'EOI'
SHELL ["cmd", "/s", "/c"]
EOI
	else
    	cat >> "$1" <<'EOI'
# $ProgressPreference: https://github.com/PowerShell/PowerShell/issues/2138#issuecomment-251261324
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
EOI
	fi
}

# Select the alpine musl OS packages.
# TODO we could inline this code as we now support only musl and not (musl and glibc)
print_alpine_pkg() {
	local osfamily=$2

	if [ "${osfamily}" == "alpine-linux" ]; then
		print_alpine_musl_pkg "$1" "$2"
	fi

}

# Select the alpine OS musl based packages.
print_alpine_musl_pkg() {
	cat >> "$1" <<'EOI'
RUN apk add --no-cache tzdata musl-locales musl-locales-lang \
    && rm -rf /var/cache/apk/*
EOI
}

# Select the ubi OS packages.
print_ubi_pkg() {
	cat >> "$1" <<'EOI'
RUN dnf install -y tzdata openssl curl ca-certificates fontconfig glibc-langpack-en gzip tar \
    && dnf update -y; dnf clean all
EOI
}

# Select the ubi OS packages.
print_ubi-minimal_pkg() {
	cat >> "$1" <<'EOI'
RUN microdnf install -y tzdata openssl curl ca-certificates fontconfig glibc-langpack-en gzip tar \
    && microdnf update -y; microdnf clean all
EOI
}

# Select the CentOS packages.
print_centos_pkg() {
	packages="tzdata openssl curl ca-certificates fontconfig gzip tar"
	# binutils is needed on JDK13+ for jlink to work https://github.com/docker-library/openjdk/issues/351
	if [[ $version -ge 13 ]]; then
		packages+=" binutils"
	fi
	cat >> "$1" <<EOI
RUN yum install -y ${packages} \\
    && yum clean all
EOI
}

# Select the ClefOS packages.
print_clefos_pkg() {
	print_centos_pkg "$1"
}

# Select the Leap packages.
print_leap_pkg() {
	cat >> "$1" <<'EOI'
RUN zypper install --no-recommends -y timezone openssl curl ca-certificates fontconfig gzip tar \
    && zypper update -y; zypper clean --all
EOI
}

# Select the Tumbleweed packages.
print_tumbleweed_pkg() {
	print_leap_pkg "$1"
}

# Print the Java version that is being installed here
print_env() {
	local osfamily=$2
	local os=$3

	# shellcheck disable=SC2154
	shasums="${package}"_"${vm}"_"${version}"_"${build}"_sums
	if [ "${osfamily}" == "windows" ]; then
		# Sometimes the windows version can differ from the Linux one
		jverinfo="${shasums}[version-windows_windows-amd]"
	elif [ "${osfamily}" == "alpine-linux" ]; then
		# Sometimes the alpine linux version can differ from the Linux one
		jverinfo="${shasums}[version-alpine-linux_x86_64]"
	else
		jverinfo="${shasums}[version]"
	fi
	# shellcheck disable=SC1083,SC2086 # TODO not sure about intention here
	eval jver=\${$jverinfo}
	jver="${jver}" # to satifsy shellcheck SC2154
	# Print additional label for UBI alone
	if [ "${os}" == "ubi-minimal" ] || [ "${os}" == "ubi" ]; then
		cat >> "$1" <<-EOI

LABEL name="Temurin OpenJDK" \\
      vendor="Eclipse Foundation" \\
      version="${jver}" \\
      release="${version}" \\
      run="docker run --rm -ti <image_name:tag> /bin/bash" \\
      summary="Eclipse Temurin Docker Image for OpenJDK with ${vm} and ${os}" \\
      description="For more information on this image please see https://github.com/adoptium/containers/blob/main/README.md"
EOI
	fi

	cat >> "$1" <<-EOI

ENV JAVA_VERSION ${jver}

EOI
}

# OS independent portion (Works for both Alpine and Ubuntu)
print_java_install_pre() {
	local pkg=$2
	local bld=$3
	local btype=$4
	local osfamily=$5
	local os=$6
	local reldir="openjdk${version}";

	if [ "${vm}" != "hotspot" ]; then
		reldir="${reldir}-${vm}";
	fi
	# First get the arches for which the builds are available as per shasums file
	local sup_arches_for_build=$(get_arches "${shasums}" | sort | uniq)
	# Next, check the arches that are supported for the underlying OS
	local sup_arches_for_os=$(parse_vm_entry "${vm}" "${version}" "${pkg}" "${os}" "Architectures:")
	# Now the actual arches are the intersection of the above two
	local merge_arches="${sup_arches_for_build} ${sup_arches_for_os}"
	local supported_arches=$(echo ${merge_arches} | tr ' ' '\n' | sort | uniq -d)
	for sarch in ${supported_arches}
	do
		if [ "${sarch}" == "aarch64" ]; then
			JAVA_URL=$(get_v3_url feature_releases "${bld}" "${vm}" "${pkg}" aarch64 "${osfamily}");
			cat >> "$1" <<-EOI
       aarch64|arm64) \\
         ESUM='$(get_shasum "${shasums}" aarch64 "${osfamily}")'; \\
         BINARY_URL='$(get_v3_binary_url "${JAVA_URL}")'; \\
         ;; \\
		EOI
		elif [ "${sarch}" == "armv7l" ]; then
			JAVA_URL=$(get_v3_url feature_releases "${bld}" "${vm}" "${pkg}" arm "${osfamily}");
			cat >> "$1" <<-EOI
       armhf|arm) \\
         ESUM='$(get_shasum "${shasums}" armv7l "${osfamily}")'; \\
         BINARY_URL='$(get_v3_binary_url "${JAVA_URL}")'; \\
		EOI
			if [ "${version}" == "8" ] && [ "${vm}" == "hotspot" ] && [ "${os}" == "ubuntu" ]; then
				cat >> "$1" <<-EOI
         # Fixes libatomic.so.1: cannot open shared object file
         apt-get update \\
         && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends libatomic1 \\
         && rm -rf /var/lib/apt/lists/* \\
		EOI
			fi
			cat >> "$1" <<-EOI
         ;; \\
		EOI
		elif [ "${sarch}" == "ppc64le" ]; then
			JAVA_URL=$(get_v3_url feature_releases "${bld}" "${vm}" "${pkg}" ppc64le "${osfamily}");
			cat >> "$1" <<-EOI
       ppc64el|powerpc:common64) \\
         ESUM='$(get_shasum "${shasums}" ppc64le "${osfamily}")'; \\
         BINARY_URL='$(get_v3_binary_url "${JAVA_URL}")'; \\
         ;; \\
		EOI
		elif [ "${sarch}" == "s390x" ]; then
			JAVA_URL=$(get_v3_url feature_releases "${bld}" "${vm}" "${pkg}" s390x "${osfamily}");
			cat >> "$1" <<-EOI
       s390x|s390:64-bit) \\
         ESUM='$(get_shasum "${shasums}" s390x "${osfamily}")'; \\
         BINARY_URL='$(get_v3_binary_url "${JAVA_URL}")'; \\
		EOI
			# Ubuntu 20.04 has a newer version of libffi (libffi7)
			# whereas hotspot has been built on libffi6 and fails if that is not avaialble
			# Workaround is to install libffi6 on ubuntu / hotspot / s390x
			if [ "${version}" == "8" ] && [ "${vm}" == "hotspot" ] && [ "${os}" == "ubuntu" ]; then
				cat >> "$1" <<'EOI'
         LIBFFI_SUM='05e456a2e8ad9f20db846ccb96c483235c3243e27025c3e8e8e358411fd48be9'; \
         LIBFFI_URL='http://launchpadlibrarian.net/354371408/libffi6_3.2.1-8_s390x.deb'; \
         curl -LfsSo /tmp/libffi6.deb ${LIBFFI_URL}; \
         echo "${LIBFFI_SUM} /tmp/libffi6.deb" | sha256sum -c -; \
         apt-get install -y --no-install-recommends /tmp/libffi6.deb; \
         rm -rf /tmp/libffi6.deb; \
EOI
			fi
			cat >> "$1" <<-EOI
         ;; \\
		EOI
		elif [ "${sarch}" == "x86_64" ]; then
			JAVA_URL=$(get_v3_url feature_releases "${bld}" "${vm}" "${pkg}" x64 "${osfamily}");
			if [ "${osfamily}" == "alpine-linux" ]; then
				print_arch="amd64|x86_64"
			else
				print_arch="amd64|i386:x86-64"
			fi
			cat >> "$1" <<-EOI
       ${print_arch}) \\
         ESUM='$(get_shasum "${shasums}" x86_64 "${osfamily}")'; \\
         BINARY_URL='$(get_v3_binary_url "${JAVA_URL}")'; \\
         ;; \\
		EOI
		fi
	done
			cat >> "$1" <<-EOI
       *) \\
         echo "Unsupported arch: \${ARCH}"; \\
         exit 1; \\
         ;; \\
    esac; \\
EOI
	if [ "${osfamily}" == "alpine-linux" ]; then
		cat >> "$1" <<'EOI'
	  wget -O /tmp/openjdk.tar.gz ${BINARY_URL}; \
	  echo "${ESUM} */tmp/openjdk.tar.gz" | sha256sum -c -; \
	  mkdir -p /opt/java/openjdk; \
	  tar --extract \
	      --file /tmp/openjdk.tar.gz \
	      --directory /opt/java/openjdk \
	      --strip-components 1 \
	      --no-same-owner \
	  ; \
EOI
	else
		cat >> "$1" <<'EOI'
    curl -LfsSo /tmp/openjdk.tar.gz ${BINARY_URL}; \
    echo "${ESUM} */tmp/openjdk.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/java/openjdk; \
    cd /opt/java/openjdk; \
    tar -xf /tmp/openjdk.tar.gz --strip-components=1; \
EOI
	fi
}

print_java_install_post() {
	cat >> "$1" <<-EOI
    rm -rf /tmp/openjdk.tar.gz;
EOI
}

# Call the script to create the slim package for Ubuntu
# Install binutils for this phase as we need the "strip" command
# Uninstall once done
print_ubuntu_slim_package() {
	cat >> "$1" <<-EOI
    export PATH="${jhome}/bin:\$PATH"; \\
    apt-get update; apt-get install -y --no-install-recommends binutils; \\
    /usr/local/bin/slim-java.sh ${jhome}; \\
    apt-get remove -y binutils; \\
    rm -rf /var/lib/apt/lists/*; \\
EOI
}

print_debianslim_package() {
  print_ubuntu_slim_package "$1"
}

# Call the script to create the slim package for Windows
print_windowsservercore_slim_package() {
	cat >> "$1" <<-EOI
    & C:/ProgramData/Java/slim-java.ps1 (Get-ChildItem -Path 'C:\\Program Files\\AdoptOpenJDK')[0].FullName; \\
EOI
}

print_nanoserver_slim_package() {
	cat >> "$1" <<-EOI
    & C:/ProgramData/Java/slim-java.ps1 C:\\openjdk-$2; \\
EOI
}

# Call the script to create the slim package for Alpine
# Install binutils for this phase as we need the "strip" command
# Uninstall once done
print_alpine_slim_package() {
	cat >> "$1" <<-EOI
    export PATH="${jhome}/bin:\$PATH"; \\
    apk add --no-cache --virtual .build-deps bash binutils; \\
    /usr/local/bin/slim-java.sh ${jhome}; \\
    apk del --purge .build-deps; \\
    rm -rf /var/cache/apk/*; \\
EOI
}

# Call the script to create the slim package for Ubi
print_ubi_slim_package() {
	cat >> "$1" <<-EOI
    export PATH="${jhome}/bin:\$PATH"; \\
    dnf install -y binutils; \\
    /usr/local/bin/slim-java.sh ${jhome}; \\
    dnf remove -y binutils; \\
    dnf clean all; \\
EOI
}

# Call the script to create the slim package for Ubi-minimal
print_ubi-minimal_slim_package() {
	cat >> "$1" <<-EOI
    export PATH="${jhome}/bin:\$PATH"; \\
    microdnf install -y binutils; \\
    /usr/local/bin/slim-java.sh ${jhome}; \\
    microdnf remove -y binutils; \\
    microdnf clean all; \\
EOI
}

# Call the script to create the slim package for leap & tumbleweed
print_leap_slim_package() {
	cat >> "$1" <<-EOI
    export PATH="${jhome}/bin:\$PATH"; \\
    zypper install --no-recommends -y binutils; \\
    /usr/local/bin/slim-java.sh ${jhome}; \\
    zypper remove -y binutils; \\
    zypper clean --all; \\
EOI
}

# Call the script to create the slim package for Centos & clefos
print_centos_slim_package() {
	cat >> "$1" <<-EOI
    export PATH="${jhome}/bin:\$PATH"; \\
    /usr/local/bin/slim-java.sh ${jhome}; \\
EOI
}

# Print the main RUN command that installs Java on ubuntu.
print_ubuntu_java_install() {
	local pkg=$2
	local bld=$3
	local btype=$4
	local osfamily=$5
	local os=$6

	cat >> "$1" <<-EOI
RUN set -eux; \\
    ARCH="\$(dpkg --print-architecture)"; \\
    case "\${ARCH}" in \\
EOI
	print_java_install_pre "${file}" "${pkg}" "${bld}" "${btype}" "${osfamily}" "${os}"
	if [ "${btype}" == "slim" ]; then
		print_ubuntu_slim_package "$1"
	fi
	print_java_install_post "$1"
}

print_debian_java_install() {
  print_ubuntu_java_install "$1" "$2" "$3" "$4" "$5" "$6"
}

print_debianslim_java_install() {
  print_ubuntu_java_install "$1" "$2" "$3" "$4" "$5" "$6"
}

print_windows_java_install_post() {
	local servertype="$2"
	local version="$3"
	local os=$4

	case $os in
		*ltsc2022) os_version="ltsc2022" ;;
		*ltsc2019) os_version="ltsc2019" ;;
		*1909) os_version="1909" ;;
		*ltsc2016) os_version="ltsc2016" ;;
		*1809) os_version="1809" ;;
	esac

	if [ "${servertype}" == "windowsservercore" ]; then
		cat >> "$1" <<-EOI
    Write-Host 'Removing openjdk.msi ...'; \\
    Remove-Item openjdk.msi -Force
EOI
	else
		copy_version=$(echo $jver | tr -d "jdk" | tr + _)
		if [[ "$version" != "8" ]]; then
			copy_version=$(echo $copy_version | tr -d "-")
		fi
		cat >> "$1" <<-EOI
ENV JAVA_HOME C:\\\\openjdk-${version}
# "ERROR: Access to the registry path is denied."
USER ContainerAdministrator
RUN echo Updating PATH: %JAVA_HOME%\bin;%PATH% \\
    && setx /M PATH %JAVA_HOME%\bin;%PATH% \\
    && echo Complete.
USER ContainerUser

COPY --from=eclipse-temurin:${copy_version}-${pkg}-windowsservercore-${os_version} \$JAVA_HOME \$JAVA_HOME
EOI
	fi
}

# Print the main RUN command that installs Java on ubuntu.
print_windows_java_install() {
	local pkg=$2
	local bld=$3
	local btype=$4
	local os=$5

	local servertype=$(echo -n "${file}" | cut -f4 -d"/" | cut -f1 -d"-" | head -qn1)
	local serverversion=$(echo -n "${file}" | cut -f4 -d"/" | cut -f2 -d"-" | head -qn1)
	local version=$(echo -n "${file}" | cut -f1 -d "/" | head -qn1)
	if [ "${servertype}" == "windowsservercore" ]; then
		JAVA_URL=$(get_v3_url feature_releases "${bld}" "${vm}" "${pkg}" windows-amd windows);
		ESUM=$(get_shasum "${shasums}" windows-amd "${osfamily}");
		BINARY_URL=$(get_v3_installer_url "${JAVA_URL}");

		DOWNLOAD_COMMAND="curl.exe -LfsSo openjdk.msi ${BINARY_URL}"
		if [ "${serverversion}" == "ltsc2016" ]; then
			DOWNLOAD_COMMAND="[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 ; Invoke-WebRequest -Uri ${BINARY_URL} -O 'openjdk.msi'"
		fi

		cat >> "$1" <<-EOI
RUN Write-Host ('Downloading ${BINARY_URL} ...'); \\
    ${DOWNLOAD_COMMAND} ; \\
    Write-Host ('Verifying sha256 (${ESUM}) ...'); \\
    if ((Get-FileHash openjdk.msi -Algorithm sha256).Hash -ne '${ESUM}') { \\
        Write-Host 'FAILED!'; \\
        exit 1; \\
    }; \\
    \\
    New-Item -ItemType Directory -Path C:\temp | Out-Null; \\
    \\
    Write-Host 'Installing using MSI ...'; \\
    \$proc = Start-Process -FilePath "msiexec.exe" -ArgumentList '/i', 'openjdk.msi', '/L*V', 'C:\temp\OpenJDK.log', \\
    '/quiet', 'ADDLOCAL=FeatureEnvironment,FeatureJarFileRunWith,FeatureJavaHome', 'INSTALLDIR=C:\openjdk-${version}' -Wait -Passthru; \\
    \$proc.WaitForExit() ; \\
    if (\$proc.ExitCode -ne 0) { \\
        Write-Host 'FAILED installing MSI!' ; \\
        exit 1; \\
    }; \\
    \\
    Remove-Item -Path C:\temp -Recurse | Out-Null; \\
EOI
	fi

	if [ "${btype}" == "slim" ]; then
		print_"${servertype}"_slim_package "$1" "${version}"
	fi

	print_windows_java_install_post "$1" "${servertype}" "${version}" "${os}"
}

# Print the main RUN command that installs Java on alpine.
print_alpine_java_install() {
	local pkg=$2
	local bld=$3
	local btype=$4
	local osfamily=$5
	local os=$6

	cat >> "$1" <<-EOI
RUN set -eux; \\
    ARCH="\$(apk --print-arch)"; \\
    case "\${ARCH}" in \\
EOI
	print_java_install_pre "${file}" "${pkg}" "${bld}" "${btype}" "${osfamily}" "${os}"
	if [ "${btype}" == "slim" ]; then
		print_alpine_slim_package "$1"
	fi
	print_java_install_post "$1"
}

# Print the main RUN command that installs Java on ubi
print_ubi_java_install() {
	local pkg=$2
	local bld=$3
	local btype=$4
	local osfamily=$5
	local os=$6

	cat >> "$1" <<-EOI
RUN set -eux; \\
    ARCH="\$(uname -m)"; \\
    case "\${ARCH}" in \\
EOI
	print_java_install_pre "${file}" "${pkg}" "${bld}" "${btype}" "${osfamily}" "${os}"
	if [ "${btype}" == "slim" ]; then
		if [ "${os}" == "ubi" ]; then	
			print_ubi_slim_package "$1"	
		elif [ "${os}" == "ubi-minimal" ]; then
			print_ubi-minimal_slim_package "$1"
		fi
	fi
	print_java_install_post "$1"
}

# Print the main RUN command that installs Java on ubi-minimal
print_ubi-minimal_java_install() {
	print_ubi_java_install "$1" "$2" "$3" "$4" "$5" "$6"
}

# Print the main RUN command that installs Java on CentOS
print_centos_java_install() {
	local pkg=$2
	local bld=$3
	local btype=$4
	local osfamily=$5
	local os=$6

	cat >> "$1" <<-EOI
RUN set -eux; \\
    ARCH="\$(objdump="\$(command -v objdump)" && objdump --file-headers "\$objdump" | awk -F '[:,]+[[:space:]]+' '\$1 == "architecture" { print \$2 }')"; \\
    case "\${ARCH}" in \\
EOI
	print_java_install_pre "${file}" "${pkg}" "${bld}" "${btype}" "${osfamily}" "${os}"
	if [ "${btype}" == "slim" ]; then
		print_centos_slim_package "$1"
	fi
	print_java_install_post "$1"
}

# Print the main RUN command that installs Java on ClefOS
print_clefos_java_install() {
	print_centos_java_install "$1" "$2" "$3" "$4" "$5" "$6"
}

# Print the main RUN command that installs Java on Leap
print_leap_java_install() {
	local pkg=$2
	local bld=$3
	local btype=$4
	cat >> "$1" <<-EOI
RUN set -eux; \\
    ARCH="\$(uname -m)"; \\
    case "\${ARCH}" in \\
EOI
	print_java_install_pre "${file}" "${pkg}" "${bld}" "${btype}" "${osfamily}" "${os}"
	if [ "${btype}" == "slim" ]; then
		print_leap_slim_package "$1"
	fi
	print_java_install_post "$1"
}

# Print the main RUN command that installs Java on Tumbleweed
print_tumbleweed_java_install() {
	print_leap_java_install "$1" "$2" "$3" "$4" "$5" "$6"
}

# Print the JAVA_HOME and PATH.
# Currently Java is installed at a fixed path "/opt/java/openjdk"
print_java_env() {
	# e.g 11 or 8
	local version=$(echo "$file" | cut -f1 -d"/")
	local os=$4

	if [ "$os" != "windows" ]; then
		cat >> "$1" <<-EOI

ENV JAVA_HOME=${jhome} \\
    PATH="${jhome}/bin:\$PATH"
EOI
	fi
}

# Turn on JVM specific optimization flags.
# Hotspot container support = https://bugs.openjdk.java.net/browse/JDK-8189497
# OpenJ9 container support = https://www.eclipse.org/openj9/docs/xxusecontainersupport/
# OpenJ9 Idle tuning = https://www.eclipse.org/openj9/docs/xxidletuninggconidle/
print_java_options() {
	case ${vm} in
	hotspot)
		case ${version} in
		9)
			JOPTS="-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap";
			;;
		esac
		;;
	openj9)
		case ${os} in
		windows)
			JOPTS="-XX:+IgnoreUnrecognizedVMOptions -XX:+IdleTuningGcOnIdle";
			;;
		*)
			JOPTS="-XX:+IgnoreUnrecognizedVMOptions -XX:+IdleTuningGcOnIdle -Xshareclasses:name=openj9_system_scc,cacheDir=/opt/java/.scc,readonly,nonFatal";
			;;
		esac
		;;
	esac

	if [ -n "${JOPTS}" ]; then
	cat >> "$1" <<-EOI
ENV JAVA_TOOL_OPTIONS="${JOPTS}"
EOI
	fi
}

# For slim builds copy the slim script and related config files.
copy_slim_script() {
	if [ "${btype}" == "slim" ]; then
		if [ "${osfamily}" == "windows" ]; then
			cat >> "$1" <<-EOI
COPY slim-java* C:/ProgramData/Java/

EOI
		else
			cat >> "$1" <<-EOI
COPY slim-java* /usr/local/bin/

EOI
		fi
	fi
}

print_test() {
	above_8="^(9|[1-9][0-9]+)$"
	if [[ "${version}" =~ ${above_8} ]]; then
		arg="--version"
	else
		arg="-version"
	fi
	servertype=$(echo "$file" | cut -f4 -d"/")
	nanoserver_pat="nanoserver.*"
	if [[ "${osfamily}" != "windows" ]] || [[ "$servertype" =~ ${nanoserver_pat} ]]; then
		cat >> "$1" <<-EOI

RUN echo Verifying install ... \\
	EOI
		if [[ "${package}" == "jdk" ]]; then
			cat >> "$1" <<-EOI
    && echo javac ${arg} && javac ${arg} \\
	EOI
		fi
		cat >> "$1" <<-EOI
    && echo java ${arg} && java ${arg} \\
    && echo Complete.
	EOI
	else
		cat >> "$1" <<-EOI

RUN Write-Host 'Verifying install ...'; \\
	EOI
		if [[ "${package}" == "jdk" ]]; then
			cat >> "$1" <<-EOI
    Write-Host 'javac ${arg}'; javac ${arg}; \\
	EOI
		fi
		cat >> "$1" <<-EOI
    Write-Host 'java ${arg}'; java ${arg}; \\
    \\
    Write-Host 'Complete.'
	EOI
	fi
}

print_cmd() {
	# for version > 8, set CMD["jshell"] in the Dockerfile
	above_8="^(9|[1-9][0-9]+)$"
	if [[ "${version}" =~ ${above_8} && "${package}" == "jdk" ]]; then
		cat >> "$1" <<-EOI

		CMD ["jshell"]
		EOI
	fi
}

print_scc_gen() {
	local vm=$2;
	local osfamily=$3;
	local os=$4;

	if [[ "${vm}" == "openj9" && "${osfamily}" != "windows" ]]; then
        cat >> "$1" <<'EOI'

# Create OpenJ9 SharedClassCache (SCC) for bootclasses to improve the java startup.
# Downloads and runs tomcat to generate SCC for bootclasses at /opt/java/.scc/openj9_system_scc
# Does a dry-run and calculates the optimal cache size and recreates the cache with the appropriate size.
# With SCC, OpenJ9 startup is improved ~50% with an increase in image size of ~14MB
# Application classes can be create a separate cache layer with this as the base for further startup improvement

RUN set -eux; \
EOI
		if [[ "${os}" == "alpine" ]]; then
			cat >> "$1" <<'EOI'
    apk add --no-cache --virtual .scc-deps curl; \
EOI
		fi
		cat >> "$1" <<'EOI'
    unset OPENJ9_JAVA_OPTIONS; \
    SCC_SIZE="50m"; \
    DOWNLOAD_PATH_TOMCAT=/tmp/tomcat; \
    INSTALL_PATH_TOMCAT=/opt/tomcat-home; \
    TOMCAT_CHECKSUM="0db27185d9fc3174f2c670f814df3dda8a008b89d1a38a5d96cbbe119767ebfb1cf0bce956b27954aee9be19c4a7b91f2579d967932207976322033a86075f98"; \
    TOMCAT_DWNLD_URL="https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.35/bin/apache-tomcat-9.0.35.tar.gz"; \
    \
    mkdir -p "${DOWNLOAD_PATH_TOMCAT}" "${INSTALL_PATH_TOMCAT}"; \
    curl -LfsSo "${DOWNLOAD_PATH_TOMCAT}"/tomcat.tar.gz "${TOMCAT_DWNLD_URL}"; \
    echo "${TOMCAT_CHECKSUM} *${DOWNLOAD_PATH_TOMCAT}/tomcat.tar.gz" | sha512sum -c -; \
    tar -xf "${DOWNLOAD_PATH_TOMCAT}"/tomcat.tar.gz -C "${INSTALL_PATH_TOMCAT}" --strip-components=1; \
    rm -rf "${DOWNLOAD_PATH_TOMCAT}"; \
    \
    java -Xshareclasses:name=dry_run_scc,cacheDir=/opt/java/.scc,bootClassesOnly,nonFatal,createLayer -Xscmx$SCC_SIZE -version; \
    export OPENJ9_JAVA_OPTIONS="-Xshareclasses:name=dry_run_scc,cacheDir=/opt/java/.scc,bootClassesOnly,nonFatal"; \
    "${INSTALL_PATH_TOMCAT}"/bin/startup.sh; \
    sleep 5; \
    "${INSTALL_PATH_TOMCAT}"/bin/shutdown.sh -force; \
    sleep 15; \
    FULL=$( (java -Xshareclasses:name=dry_run_scc,cacheDir=/opt/java/.scc,printallStats 2>&1 || true) | awk '/^Cache is [0-9.]*% .*full/ {print substr($3, 1, length($3)-1)}'); \
    DST_CACHE=$(java -Xshareclasses:name=dry_run_scc,cacheDir=/opt/java/.scc,destroy 2>&1 || true); \
    SCC_SIZE=$(echo $SCC_SIZE | sed 's/.$//'); \
    SCC_SIZE=$(awk "BEGIN {print int($SCC_SIZE * $FULL / 100.0)}"); \
    [ "${SCC_SIZE}" -eq 0 ] && SCC_SIZE=1; \
    SCC_SIZE="${SCC_SIZE}m"; \
    java -Xshareclasses:name=openj9_system_scc,cacheDir=/opt/java/.scc,bootClassesOnly,nonFatal,createLayer -Xscmx$SCC_SIZE -version; \
    unset OPENJ9_JAVA_OPTIONS; \
    \
    export OPENJ9_JAVA_OPTIONS="-Xshareclasses:name=openj9_system_scc,cacheDir=/opt/java/.scc,bootClassesOnly,nonFatal"; \
    "${INSTALL_PATH_TOMCAT}"/bin/startup.sh; \
    sleep 5; \
    "${INSTALL_PATH_TOMCAT}"/bin/shutdown.sh -force; \
    sleep 5; \
    FULL=$( (java -Xshareclasses:name=openj9_system_scc,cacheDir=/opt/java/.scc,printallStats 2>&1 || true) | awk '/^Cache is [0-9.]*% .*full/ {print substr($3, 1, length($3)-1)}'); \
    echo "SCC layer is $FULL% full."; \
    rm -rf "${INSTALL_PATH_TOMCAT}"; \
    if [ -d "/opt/java/.scc" ]; then \
          chmod -R 0777 /opt/java/.scc; \
    fi; \
    \
EOI
		if [[ "${os}" == "alpine" ]]; then
			cat >> "$1" <<'EOI'
    apk del --purge .scc-deps; \
    rm -rf /var/cache/apk/*; \
EOI
    	fi
		cat >> "$1" <<'EOI'
    echo "SCC generation phase completed";

EOI
	fi
}

# Generate the dockerfile for a given build, build_type and OS
generate_dockerfile() {
	local file=$1
	local pkg=$2
	local bld=$3
	local btype=$4
	local osfamily=$5
	local os=$6

	jhome="/opt/java/openjdk"

	mkdir -p "$(dirname "${file}")" 2>/dev/null
	echo
	echo -n "Writing ${file} ... "
	print_legal "${file}";
	if [ "${osfamily}" == "windows" ]; then
		print_"${osfamily}"_ver "${file}" "${bld}" "${btype}" "${os}";
		print_lang_locale "${file}" "${osfamily}";
		print_"${osfamily}"_pkg "${file}" "${osfamily}";
		print_env "${file}" "${osfamily}" "${os}";
		copy_slim_script "${file}";
		print_"${osfamily}"_java_install "${file}" "${pkg}" "${bld}" "${btype}" "${osfamily}" "${os}";
		print_java_env "${file}" "${bld}" "${btype}" "${osfamily}";
		print_java_options "${file}" "${bld}" "${btype}";
		print_test "${file}";
		print_cmd "${file}";
	else
		print_"${os}"_ver "${file}" "${bld}" "${btype}" "${os}";
		print_lang_locale "${file}" "${osfamily}";
		print_"${os}"_pkg "${file}" "${osfamily}";
		print_env "${file}" "${osfamily}" "${os}";
		copy_slim_script "${file}";
		print_"${os}"_java_install "${file}" "${pkg}" "${bld}" "${btype}" "${osfamily}" "${os}";
		print_java_env "${file}" "${bld}" "${btype}" "${osfamily}";
		print_java_options "${file}" "${bld}" "${btype}";
		print_scc_gen "${file}" "${vm}" "${osfamily}" "${os}";
		print_test "${file}";
		print_cmd "${file}";
	fi
	echo "done"
	echo
}
