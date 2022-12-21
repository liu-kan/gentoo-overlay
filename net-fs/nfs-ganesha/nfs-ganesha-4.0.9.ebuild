# Copyright 1999-2022 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_10 )

inherit cmake flag-o-matic python-single-r1 systemd
#inherit cmake flag-o-matic

DESCRIPTION="A NFSv3,v4,v4.1 fileserver that runs in user mode on most UNIX/Linux systems"
HOMEPAGE="https://github.com/nfs-ganesha/nfs-ganesha"
if [[ ${PV} == *beta* ]] ; then
	MY_PV="$(ver_cut 1)-dev.$(ver_cut 4)"
	SRC_URI="https://github.com/nfs-ganesha/${PN}/archive/V${MY_PV}.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}/${PN}-${MY_PV}/src"
else
	SRC_URI="https://github.com/nfs-ganesha/${PN}/archive/V${PV}.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}/${P}/src"
fi

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE="btrfs caps dbus debug gssapi gui +nfs3 nfsidmap tools vsock +doc"
FS_SUPPORT=" ceph glusterfs gpfs lustre mem null proxy-v3 proxy-v4 rgw vfs xfs"
IUSE+=" ${FS_SUPPORT// / ganesha_fs_}"

REQUIRED_USE="gui? ( tools )
	btrfs? ( ganesha_fs_vfs )"

RDEPEND="
	dev-libs/jemalloc:=
	dev-libs/userspace-rcu:=
	>=net-libs/ntirpc-4.0[gssapi]
	sys-apps/acl
	sys-apps/util-linux
	caps? ( sys-libs/libcap )
	btrfs? ( sys-fs/btrfs-progs )
	gssapi? ( virtual/krb5 )
	dbus? ( sys-apps/dbus )
	ganesha_fs_ceph? ( sys-cluster/ceph )
	ganesha_fs_glusterfs? ( sys-cluster/glusterfs )
	ganesha_fs_lustre? ( sys-cluster/lustre )
	ganesha_fs_xfs? ( sys-fs/xfsprogs )
	nfsidmap? ( net-libs/libnfsidmap )
	doc? ( app-doc/doxygen[dot] )
	net-fs/nfs-utils
"
DEPEND="${RDEPEND}
	sys-devel/bison
	sys-devel/flex
	virtual/pkgconfig
"

pkg_setup() {
	if use tools || use gui; then
		python-single-r1_pkg_setup
	fi
}


src_prepare() {
	sed \
		-e "/config_samples/s:doc\/ganesha:doc\/${PF}:g" \
		-e '/run\/ganesha/d' \
		-i CMakeLists.txt  || die
	cmake_src_prepare
}

src_configure() {
	if use debug ; then
		CMAKE_BUILD_TYPE=Debug
	else
		CMAKE_BUILD_TYPE=Release
	fi

	local mycmakeargs=(
		-DALLOCATOR=jemalloc
		-DUSE_SYSTEM_NTIRPC=ON
		-DTIRPC_EPOLL=ON
		-USE_ACL_MAPPING=ON
		-DUSE_BTRFSUTIL=$(usex btrfs)
		-DUSE_GSS=$(usex gssapi)
		-DUSE_DBUS=$(usex dbus)
		-DUSE_NFSIDMAP=$(usex nfsidmap)
		-DENABLE_VFS_DEBUG_ACL=$(usex debug)
		-DENABLE_RFC_ACL=$(usex debug)
		-DUSE_EFENCE=$(usex debug)
		-DDEBUG_SAL=$(usex debug)
		-DENABLE_LOCKTRACE=$(usex debug)
		-DUSE_NFS3=$(usex nfs3)
		-DUSE_NFSACL3=$(usex nfs3)
		-DUSE_NLM=$(usex nfs3)
		-DUSE_VSOCK=$(usex vsock)
		-DUSE_ADMIN_TOOLS=$(usex tools)
		-DUSE_GUI_ADMIN_TOOLS=$(usex gui)

		-DUSE_FSAL_CEPH=$(usex ganesha_fs_ceph)
		-DUSE_RADOS_RECOV=$(usex ganesha_fs_ceph)
		-DRADOS_URLS=$(usex ganesha_fs_ceph)
		-DCEPHFS_POSIX_ACL=$(usex ganesha_fs_ceph)

		-DUSE_FSAL_GLUSTER=$(usex ganesha_fs_glusterfs)
		-DUSE_FSAL_GPFS=$(usex ganesha_fs_gpfs)
		-DUSE_FSAL_LUSTRE=$(usex ganesha_fs_lustre)
		-DUSE_FSAL_MEM=$(usex ganesha_fs_mem)
		-DUSE_FSAL_NULL=$(usex ganesha_fs_null)
		-DUSE_FSAL_PROXY_V3=$(usex ganesha_fs_proxy-v3)
		-DUSE_FSAL_PROXY_V4=$(usex ganesha_fs_proxy-v4)
		-DUSE_FSAL_RGW=$(usex ganesha_fs_rgw)
		-DUSE_FSAL_VFS=$(usex ganesha_fs_vfs)
		-DUSE_FSAL_XFS=$(usex ganesha_fs_xfs)

		-DUSE_FSAL_LIZARDFS=OFF
		-DUSE_FSAL_KVSFS=OFF
	)

	if use gui || use tools; then
		mycmakeargs+=(
			-DPython_INCLUDE_DIR="$(python_get_includedir)"
			-DPython_LIBRARY="$(python_get_library_path)"
			-DPython_EXECUTABLE="${PYTHON}"
		)
	fi

	cmake_src_configure
}
#testing
#/var/tmp/portage/net-fs/nfs-ganesha-2.4.3/work/nfs-ganesha-2.4.3/src/CMakeLists.txt:option(USE_TOOL_MULTILOCK "build multilock tool" OFF)
#/var/tmp/portage/net-fs/nfs-ganesha-2.4.3/work/nfs-ganesha-2.4.3/src/CMakeLists.txt:option(USE_CB_SIMULATOR "enable callback simulator thread" OFF)
#/var/tmp/portage/net-fs/nfs-ganesha-2.4.3/work/nfs-ganesha-2.4.3/src/CMakeLists.txt:option(ENABLE_ERROR_INJECTION "enable error injection" OFF)
#/var/tmp/portage/net-fs/nfs-ganesha-2.4.3/work/nfs-ganesha-2.4.3/src/CMakeLists.txt:# These are -D_FOO options, why ???  should be flags??
#/var/tmp/portage/net-fs/nfs-ganesha-2.4.3/work/nfs-ganesha-2.4.3/src/CMakeLists.txt:option(_NO_TCP_REGISTER "disable registration of tcp services on portmapper" OFF)
#/var/tmp/portage/net-fs/nfs-ganesha-2.4.3/work/nfs-ganesha-2.4.3/src/CMakeLists.txt:option(_NO_PORTMAPPER "disable registration on portmapper" OFF)
#/var/tmp/portage/net-fs/nfs-ganesha-2.4.3/work/nfs-ganesha-2.4.3/src/CMakeLists.txt:option(_NO_XATTRD "disable ghost xattr directory and files support" ON)
#/var/tmp/portage/net-fs/nfs-ganesha-2.4.3/work/nfs-ganesha-2.4.3/src/CMakeLists.txt:option(_VALGRIND_MEMCHECK "Initialize buffers passed to GPFS ioctl that valgrind doesn't understand" OFF)
#/var/tmp/portage/net-fs/nfs-ganesha-2.4.3/work/nfs-ganesha-2.4.3/src/CMakeLists.txt:option(USE_CUNIT "Use Cunit test framework" OFF)
#/var/tmp/portage/net-fs/nfs-ganesha-2.4.3/work/nfs-ganesha-2.4.3/src/CMakeLists.txt:option(BLKIN_PREFIX "Blkin installation prefix" "/opt/blkin")
#/var/tmp/portage/net-fs/nfs-ganesha-2.4.3/work/nfs-ganesha-2.4.3/src/CMakeLists.txt:option(USE_GTEST "Use Google Test test framework" OFF)
#/var/tmp/portage/net-fs/nfs-ganesha-2.4.3/work/nfs-ganesha-2.4.3/src/CMakeLists.txt:option(GTEST_PREFIX "Google Test installation prefix"

src_install() {
	cmake_src_install
	if systemd_is_booted; then
		systemd_newunit "${WORKDIR}"/${P}/src/scripts/systemd/nfs-ganesha-lock.service.el8 nfs-ganesha-lock.service
		systemd_newunit "${WORKDIR}"/${P}/src/scripts/systemd/nfs-ganesha.service.el7 nfs-ganesha.service
	fi
	newinitd "${FILESDIR}"/${PN}.init ${PN}
	newconfd "${FILESDIR}"/${PN}.confd ${PN}

	if use dbus; then
		insinto /etc/dbus-1/system.d
		doins scripts/ganeshactl/org.ganesha.nfsd.conf
	fi
}
