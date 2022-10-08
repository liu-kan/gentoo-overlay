# Copyright 1999-2022 Kan Liu
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit git-r3 linux-info systemd linux-mod

DESCRIPTION="Lustre filesystem with ZFS"
HOMEPAGE="https://www.lustre.org/"
EGIT_REPO_URI="https://gitlab.com/liu-kan/lustre-release.git"

LICENSE="GPL-2"

SLOT="0"
KEYWORDS="amd64"
IUSE="+gss +modules +server o2ib +readline +client"

REQUIRED_USE="
		client? ( modules )
		server? ( modules )
"
RDEPEND="
		server? ( sys-fs/zfs )
		server? ( >=sys-fs/zfs-kmod-2.1.5-r1 )
		gss? ( sys-apps/keyutils )
		gss? ( virtual/krb5 )
		dev-libs/libnl
		virtual/awk
		dev-libs/libyaml
		readline? ( sys-libs/readline:0 )
		>=sys-devel/binutils-2.38
"
DEPEND="
	${RDEPEND}
	>=sys-kernel/linux-headers-5.15-r3
"
BDEPEND="app-portage/portage-utils"
pkg_pretend() {
	linux-info_pkg_setup
	if kernel_is lt 5 15 59; then
		die "Tests only passed with kernel version ge 5.15.59"
	fi
}
src_prepare() {
	local latestTag
	git checkout ${PV}
	default
	sh autogen.sh
}
src_configure() {
	set_arch_to_kernel
	local theconf
	theconf+=" --with-linux=${KV_DIR}"
	if use server; then
		theconf+=" --with-zfs=/usr/src/zfs-$(qlist -IvC -F "%{PV}" zfs-kmod)"
	fi
	econf \
		${theconf} \
		$(use_enable client) \
		$(use_enable server server) \
		$(use_enable modules modules) \
		--disable-ldiskfs --disable-tests \
		$(usex o2ib '--with-o2ib=' '--with-o2ib=' 'yes' 'no') \
		$(usex gss '--enable-gss' '--disable-gss-keyring' '' '') \
		$(usex client '' '--disable-client' '' '')
}

src_compile() {
	emake
}

src_install() {
	default_src_install
	systemd_dounit "${S}"/lustre/scripts/systemd/lnet.service
}



pkg_postinst() {
	linux-mod_pkg_postinst
	einfo "  configure lent at /etc/lnet.conf before you use it. "
	einfo ""
}

pkg_postrm() {
	linux-mod_pkg_postrm
}
