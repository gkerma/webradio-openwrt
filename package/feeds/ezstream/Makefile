#
# Copyright (C) 2024 CyberMind.FR
#
# This is free software, licensed under the GNU General Public License v2.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=ezstream
PKG_VERSION:=1.0.2
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://downloads.xiph.org/releases/ezstream/
PKG_HASH:=11de897f455a95ba4a308f41eb5e6ff0a2a95ef5e8f1b5b2a5a5fcd9f0b5a5e5

PKG_MAINTAINER:=Gerald Kerma <contact@cybermind.fr>
PKG_LICENSE:=GPL-2.0-only
PKG_LICENSE_FILES:=COPYING

PKG_FIXUP:=autoreconf
PKG_INSTALL:=1
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/ezstream
  SECTION:=multimedia
  CATEGORY:=Multimedia
  TITLE:=Ezstream - Icecast source client
  URL:=https://icecast.org/ezstream/
  DEPENDS:=+libxml2 +libshout +libogg +libvorbis +taglib
endef

define Package/ezstream/description
  Ezstream is a command line source client for Icecast media
  streaming servers. It reads audio data from files or standard
  input and streams it to an Icecast server.
endef

define Package/ezstream/conffiles
/etc/ezstream.xml
/etc/config/ezstream
endef

CONFIGURE_ARGS += \
	--prefix=/usr \
	--sysconfdir=/etc \
	--without-taglib

define Package/ezstream/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/ezstream $(1)/usr/bin/

	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_CONF) ./files/ezstream.xml $(1)/etc/ezstream.xml

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/ezstream.uci $(1)/etc/config/ezstream

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/ezstream.init $(1)/etc/init.d/ezstream

	$(INSTALL_DIR) $(1)/usr/lib/ezstream
	$(INSTALL_BIN) ./files/ezstream-genconfig.sh $(1)/usr/lib/ezstream/genconfig.sh
	$(INSTALL_BIN) ./files/playlist-manager.sh $(1)/usr/lib/ezstream/playlist-manager.sh

	$(INSTALL_DIR) $(1)/srv/webradio/music
	$(INSTALL_DIR) $(1)/srv/webradio/playlists
endef

$(eval $(call BuildPackage,ezstream))
