#
# Copyright (C) 2024 CyberMind.FR
#
# This is free software, licensed under the GNU General Public License v2.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=darkice
PKG_VERSION:=1.4
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/rafael2k/darkice/releases/download/v$(PKG_VERSION)/
PKG_HASH:=e6a8ec2b447cf5b4ffaf9b62700502b6bdacebf00b476f4e9bf9f9fe1e3dd817

PKG_MAINTAINER:=Gerald Kerma <contact@cybermind.fr>
PKG_LICENSE:=GPL-3.0-or-later
PKG_LICENSE_FILES:=COPYING

PKG_BUILD_PARALLEL:=1
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/darkice
  SECTION:=multimedia
  CATEGORY:=Multimedia
  TITLE:=Live audio streamer
  URL:=http://www.darkice.org/
  DEPENDS:=+libstdcpp +alsa-lib +libshout +libogg +libvorbis +lame-lib
endef

define Package/darkice/description
  DarkIce is a live audio streamer. It records audio from an audio interface
  (e.g. sound card), encodes it and sends it to a streaming server (Icecast).
endef

define Package/darkice/conffiles
/etc/config/darkice
endef

CONFIGURE_ARGS += \
	--without-faac \
	--without-aacplus \
	--without-twolame \
	--without-opus \
	--without-pulseaudio \
	--without-jack \
	--with-alsa \
	--with-alsa-prefix="$(STAGING_DIR)/usr" \
	--with-lame \
	--with-lame-prefix="$(STAGING_DIR)/usr" \
	--with-vorbis \
	--with-vorbis-prefix="$(STAGING_DIR)/usr" \
	--with-samplerate=no

define Package/darkice/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/darkice $(1)/usr/bin/

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/darkice.config $(1)/etc/config/darkice

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/darkice.init $(1)/etc/init.d/darkice

	$(INSTALL_DIR) $(1)/usr/lib/darkice
	$(INSTALL_BIN) ./files/darkice-genconfig.sh $(1)/usr/lib/darkice/darkice-genconfig.sh
endef

$(eval $(call BuildPackage,darkice))
