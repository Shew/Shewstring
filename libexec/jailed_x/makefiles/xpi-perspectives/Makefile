# New ports collection makefile for:    xpi-perspectives
# Date created:         September 2010
# Whom:                 Shew <shew09642@rambler.ru>

PORTNAME=       perspectives
PORTVERSION=	4.2
DISTVERSIONSUFFIX=	-sm+fx
CATEGORIES=     www

MAINTAINER=     shew09642@rambler.ru
COMMENT=        A secure way to verify encrypted websites and bypass security warnings

XPI_ID=         perspectives@cmu.edu
XPI_NUM=        7974
XPI_DIRS=	chrome chrome/content chrome/locale chrome/locale/zh-CN chrome/locale/en-US defaults defaults/preferences
XPI_FILES=	chrome/content/bad.png chrome/content/preferences_dialog.js chrome/content/common.js chrome/content/report.js chrome/content/report.xul chrome/content/notify.js chrome/content/http_notary_list.txt chrome/content/info.xul chrome/content/results_dialog.xul chrome/content/notaries.js chrome/content/preferences_dialog.xul chrome/content/whitelist_dialog.xul chrome/content/progress.gif chrome/content/statusbar.xul chrome/content/error.png chrome/content/base64.js chrome/content/.statusbar.xul.swp chrome/content/statusbar.js chrome/content/generate_svg.js chrome/content/good.png chrome/content/client_policy.js chrome/content/results_dialog.js chrome/content/xml_notary_client.js chrome/content/initialize.xul chrome/content/default.png chrome/content/whitelist_dialog.js chrome/locale/zh-CN/help.html chrome/locale/zh-CN/notaries.properties chrome/locale/zh-CN/dialogs.dtd chrome/locale/en-US/help.html chrome/locale/en-US/notaries.properties chrome/locale/en-US/dialogs.dtd chrome.manifest defaults/preferences/prefs.js firewall.html help.html install.rdf

.include "${.CURDIR}/../xpi-adblock/Makefile.xpi"
.include <bsd.port.mk>
