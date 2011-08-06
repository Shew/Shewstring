# New ports collection makefile for:    xpi-beef-taco
# Date created:         September 2010
# Whom:                 Shew <shew09642@rambler.ru>

PORTNAME=       beef-taco
PORTVERSION=    1.3.6
DISTVERSIONSUFFIX=	-fx
CATEGORIES=     www
DISTFILES=	"beef_taco_targeted_advertising_cookie_opt_out-${PORTVERSION}${DISTVERSIONSUFFIX}.xpi"

MAINTAINER=     shew09642@rambler.ru
COMMENT=        Sets permanent opt-out cookies to stop behavioral advertising by 100+ different advertising networks

XPI_ID=         john@velvetcache.org
XPI_NUM=	180650
XPI_DIRS=	chrome chrome/defaults chrome/defaults/preferences chrome/locale chrome/locale/en-US chrome/content
XPI_FILES=	chrome/defaults/preferences/prefs.js chrome/locale/en-US/about.dtd chrome/locale/en-US/overlay.properties chrome/locale/en-US/overlay.dtd chrome/locale/en-US/options.dtd chrome/content/options.xul chrome/content/ff-overlay.xul chrome/content/cookies.js chrome/content/icon.png chrome/content/namespace.js chrome/content/cookie.16x16.png chrome/content/beef-taco.xul chrome/content/about.xul chrome/content/ff-overlay.js chrome/content/icon.16x16.png chrome/content/beef-taco.js chrome.manifest install.rdf

.include "${.CURDIR}/../xpi-adblock/Makefile.xpi"
.include <bsd.port.mk>
