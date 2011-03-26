# New ports collection makefile for:    xpi-perspectives
# Date created:         September 2010
# Whom:                 Shew <shew09642@rambler.ru>
#
# $FreeBSD$
#

PORTNAME=       perspectives
PORTVERSION=	4.0
DISTVERSIONSUFFIX=	-fx+sm
CATEGORIES=     www

MAINTAINER=     shew09642@rambler.ru
COMMENT=        A secure way to verify encrypted websites and bypass security warnings

XPI_ID=         perspectives@cmu.edu
XPI_NUM=        7974
XPI_DIRS=	chrome chrome/content chrome/locale chrome/locale/en-US chrome/locale/zh-CN defaults defaults/preferences
XPI_FILES=	chrome/content/bad.png chrome/content/base64.js chrome/content/client_policy.js \
		chrome/content/common.js chrome/content/default.png chrome/content/error.png \
		chrome/content/generate_svg.js chrome/content/good.png chrome/content/info.xul \
		chrome/content/initialize.xul chrome/content/notaries.js chrome/content/preferences_dialog.js \
		chrome/content/preferences_dialog.xul chrome/content/progress.gif chrome/content/report.js \
		chrome/content/report.xul chrome/content/results_dialog.js chrome/content/results_dialog.xul \
		chrome/content/statusbar.js chrome/content/statusbar.xul chrome/content/whitelist_dialog.js \
		chrome/content/whitelist_dialog.xul chrome/content/xml_notary_client.js chrome/locale/en-US/dialogs.dtd \
		chrome/locale/en-US/help.html chrome/locale/en-US/notaries.properties chrome/locale/zh-CN/dialogs.dtd \
		chrome/locale/zh-CN/help.html chrome/locale/zh-CN/notaries.properties chrome.manifest \
		defaults/preferences/prefs.js firewall.html help.html http_notary_list.txt install.rdf

.include "${.CURDIR}/../xpi-adblock/Makefile.xpi"
.include <bsd.port.mk>
