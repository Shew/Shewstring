# New ports collection makefile for:    xpi-https-everywhere
# Date created:         September 2010
# Whom:                 Shew <shew09642@rambler.ru>

PORTNAME=       https-everywhere
PORTVERSION=    1.0.1
CATEGORIES=     www
MASTER_SITES=   http://www.eff.org/files/

MAINTAINER=     shew09642@rambler.ru
COMMENT=        HTTPS Everywhere encrypts your communications with a number of major websites

XPI_ID=         https-everywhere@eff.org
XPI_DIRS=	chrome chrome/skin chrome/locale chrome/locale/en chrome/content chrome/content/rules chrome/content/code components
XPI_FILES=	LICENSE.txt install.rdf chrome.manifest chrome/skin/tick.png chrome/skin/tick-moot.png chrome/skin/cross.png chrome/skin/tick-red.png chrome/skin/https-everywhere.xcf chrome/skin/https-everywhere.css chrome/skin/https-everywhere.png chrome/skin/https-everywhere-half-24.png chrome/skin/https-everywhere-24.png chrome/skin/https-everywhere-16.png chrome/locale/en/https-everywhere.dtd chrome/content/about.xul chrome/content/preferences.xul chrome/content/preferences.css chrome/content/rules/00README chrome/content/rules/default.rulesets chrome/content/code/Thread.js chrome/content/code/Class.js chrome/content/code/STS.js chrome/content/code/Main.js chrome/content/code/HTTPSRules.js chrome/content/code/IOUtil.js chrome/content/code/Cookie.js chrome/content/code/HTTPS.js chrome/content/code/ApplicableList.js chrome/content/preferences.js chrome/content/toolbar_button.js chrome/content/toolbar_button.xul components/https-everywhere.js Changelog

.include "${.CURDIR}/../xpi-adblock/Makefile.xpi"
.include <bsd.port.mk>
