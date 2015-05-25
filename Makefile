#
# Copyright (C) 2015 Shellfire Gattung u. Behr GbR <info@shellfire.de>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#
include $(TOPDIR)/rules.mk
LUCI_TITLE:=LuCI Shellfire Box Application
LUCI_DEPENDS:=
include ../../luci.mk
# call BuildPackage - OpenWrt buildroot signature