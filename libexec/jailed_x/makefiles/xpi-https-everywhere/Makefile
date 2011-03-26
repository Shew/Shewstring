# New ports collection makefile for:    xpi-https-everywhere
# Date created:         September 2010
# Whom:                 Shew <shew09642@rambler.ru>
#
# $FreeBSD$
#

PORTNAME=       https-everywhere
PORTVERSION=    0.9.2
CATEGORIES=     www
MASTER_SITES=   http://www.eff.org/files/

MAINTAINER=     shew09642@rambler.ru
COMMENT=        HTTPS Everywhere encrypts your communications with a number of major websites

XPI_ID=         https-everywhere@eff.org
XPI_DIRS=	chrome chrome/content chrome/content/code chrome/content/rules chrome/locale chrome/locale/en \
		chrome/skin components
XPI_FILES=	Changelog LICENSE.txt chrome.manifest chrome/content/code/Cookie.js chrome/content/code/HTTPS.js \
		chrome/content/code/HTTPSRules.js chrome/content/code/IOUtil.js chrome/content/code/STS.js \
		chrome/content/code/Thread.js chrome/content/preferences.js chrome/content/preferences.xul \
		chrome/content/rules/00README chrome/content/rules/Amazon-off-by-default.xml chrome/content/rules/Bitly.xml \
		chrome/content/rules/CDT.xml chrome/content/rules/Cisco.xml chrome/content/rules/Dropbox.xml \
		chrome/content/rules/DuckDuckGo.xml chrome/content/rules/EFF.xml chrome/content/rules/Evernote.xml \
		chrome/content/rules/FB-extra.xml chrome/content/rules/Facebook.xml chrome/content/rules/GMX.xml \
		chrome/content/rules/Gentoo.xml chrome/content/rules/Github.xml chrome/content/rules/Google.xml \
		chrome/content/rules/GoogleAPIs.xml chrome/content/rules/GoogleServices.xml \
		chrome/content/rules/Identica.xml chrome/content/rules/Ixquick.xml chrome/content/rules/Live.xml \
		chrome/content/rules/Mail.com.xml chrome/content/rules/Meebo.xml chrome/content/rules/Microsoft.xml \
		chrome/content/rules/Mozilla.xml chrome/content/rules/NYTimes.xml chrome/content/rules/Nederland.xml \
		chrome/content/rules/Noisebridge.xml chrome/content/rules/PayPal.xml chrome/content/rules/S3.xml \
		chrome/content/rules/Scroogle.xml chrome/content/rules/Torproject.xml chrome/content/rules/Twitter.xml \
		chrome/content/rules/WashingtonPost.xml chrome/content/rules/Wikipedia.xml \
		chrome/content/rules/WordPress.xml chrome/content/rules/Zoho.xml chrome/locale/en/https-everywhere.dtd \
		chrome/skin/https-everywhere.png chrome/skin/https-everywhere.xcf components/https-everywhere.js install.rdf

.include "${.CURDIR}/../xpi-adblock/Makefile.xpi"
.include <bsd.port.mk>
