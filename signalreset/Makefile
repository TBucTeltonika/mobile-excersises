include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=signalreset
PKG_VERSION:=1


include $(INCLUDE_DIR)/package.mk

define Package/signalreset
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Script that checks signal strength and automatically disconnects if it falls too low.
endef

define Package/signalreset/description
	configuraiton file /etc/config/signalreset
endef


define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/signalreset/install
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_BIN) ./files/signalreset $(1)/bin/
	$(INSTALL_DIR) $(1)/etc/config
	$(CP) ./files/signalreset.conf $(1)/etc/config/signalreset
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/signalreset.init $(1)/etc/init.d/signalreset
endef

$(eval $(call BuildPackage,signalreset))