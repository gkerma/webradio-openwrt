#
# Copyright (C) 2024 CyberMind.FR
#
# This is free software, licensed under the GNU General Public License v2.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=icecast
PKG_VERSION:=2.4.4
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://downloads.xiph.org/releases/icecast/
PKG_HASH:=49b5979f9f614140b6a38046154f3f0e0f8e526c3a9b5c1d42193d0f2d8e8a0c

PKG_MAINTAINER:=Gerald Kerma <contact@cybermind.fr>
PKG_LICENSE:=GPL-2.0-only
PKG_LICENSE_FILES:=COPYING

PKG_FIXUP:=autoreconf
PKG_INSTALL:=1
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/icecast
  SECTION:=multimedia
  CATEGORY:=Multimedia
  TITLE:=Icecast streaming media server
  URL:=https://icecast.org/
  DEPENDS:=+libxml2 +libxslt +libogg +libvorbis +libcurl +libopenssl +libpthread
endef

define Package/icecast/description
  Icecast is a streaming media server which currently supports
  Ogg Vorbis and MP3 audio streams. It can be used to create an
  Internet radio station or a privately running jukebox.
endef

define Package/icecast/conffiles
/etc/icecast.xml
/etc/config/icecast
endef

CONFIGURE_ARGS += \
	--prefix=/usr \
	--sysconfdir=/etc \
	--localstatedir=/var \
	--with-curl \
	--with-openssl \
	--without-speex \
	--without-theora

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_INSTALL_DIR)/usr/include/icecast $(1)/usr/include/
endef

define Package/icecast/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/icecast $(1)/usr/bin/

	$(INSTALL_DIR) $(1)/usr/share/icecast/web
	$(CP) $(PKG_INSTALL_DIR)/usr/share/icecast/web/* $(1)/usr/share/icecast/web/

	$(INSTALL_DIR) $(1)/usr/share/icecast/admin
	$(CP) $(PKG_INSTALL_DIR)/usr/share/icecast/admin/* $(1)/usr/share/icecast/admin/

	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_CONF) ./files/icecast.xml $(1)/etc/icecast.xml

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/icecast.uci $(1)/etc/config/icecast

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/icecast.init $(1)/etc/init.d/icecast

	$(INSTALL_DIR) $(1)/usr/lib/icecast
	$(INSTALL_BIN) ./files/icecast-genconfig.sh $(1)/usr/lib/icecast/genconfig.sh

	$(INSTALL_DIR) $(1)/var/log/icecast
	$(INSTALL_DIR) $(1)/var/run/icecast
endef

define Package/icecast/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	# Create icecast user if not exists
	grep -q '^icecast:' /etc/passwd || {
		echo "icecast:x:515:515:Icecast:/var/run/icecast:/bin/false" >> /etc/passwd
		echo "icecast:x:515:" >> /etc/group
	}
	chown -R icecast:icecast /var/log/icecast /var/run/icecast
}
exit 0
endef

$(eval $(call BuildPackage,icecast))
