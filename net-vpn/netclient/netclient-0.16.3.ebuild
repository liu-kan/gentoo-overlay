# Copyright 1999-2022 Kan Liu
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit linux-info systemd go-module #git-r3

DESCRIPTION="Netmaker makes networks with WireGuard. Netmaker automates fast, secure, and distributed virtual networks. netclient is the client of Netmaker"
HOMEPAGE="https://netmaker.io"
EGIT_REPO_URI="https://gitlab.com/liu-kan/netmaker.git"
#EGIT_REPO_URI="https://github.com/gravitl/netmaker.git"
git_commit_sha1=74986ff478c23f6110cab04fe61aedbc8a1decb3
IUSE="+gomoddeps"
SRC_URI="https://gitlab.com/liu-kan/netmaker/-/archive/v${PV}/${PN}-v${PV}.tar.bz2
	gomoddeps?   ( https://gitee.com/liukxyz/gentoo-overlay/releases/download/v20221221/${P}-deps.tar.xz )"

LICENSE="SSPL-1"
S=${WORKDIR}/netmaker-v${PV}-${git_commit_sha1}
SLOT="0"
KEYWORDS="amd64"

REQUIRED_USE="
"
RDEPEND="
	net-vpn/wireguard-tools
"
DEPEND="
	${RDEPEND}
"
BDEPEND="dev-lang/go"
pkg_pretend() {
	linux-info_pkg_setup
	if kernel_is lt 5 6; then
		die "Tests only passed with kernel version ge 5.6"
	fi
	if ! linux_config_exists ; then
		die "! linux_config_exists"
	fi
	if ! linux_chkconfig_present WIREGUARD ; then
		die "! linux_chkconfig_present WIREGUARD"
	fi
}
src_prepare() {
	#git checkout v${PV}
	default
}
src_compile() {
	export CGO_ENABLED=0
	export GOOS=linux
	export GOARCH=amd64
	export GO111MODULE=on
	export GOMODCACHE=${WORKDIR}/go-mod
	cd ${S}/netclient
	ego build -ldflags="-X 'main.version=v${PV}'" -o build/netclient main.go
}

src_install() {
	dosbin ${S}/netclient/build/netclient
	sed -i 's/ExecStart=\/sbin\/netclient/ExecStart=\/usr\/sbin\/netclient/g' ${S}/netclient/build/netclient.service
	systemd_dounit ${S}/netclient/build/netclient.service
}

