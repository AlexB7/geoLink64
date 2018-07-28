@echo off
cls

rem =========================
rem Assemble geoLink
rem =========================

ca65 -g -t geos-cbm geoLinkRes.s
if errorlevel 1 goto end

ca65 -g -t geos-cbm geoLinkVal.s
if errorlevel 1 goto end

ca65 -g -t geos-cbm geoLinkSetup.s
if errorlevel 1 goto end

ca65 -g -t geos-cbm geoLinkPing.s
if errorlevel 1 goto end

ca65 -g -t geos-cbm geoLinkLogin.s
if errorlevel 1 goto end

ca65 -g -t geos-cbm geoLinkIRC.s
if errorlevel 1 goto end

ca65 -g -t geos-cbm geoLinkFontStub.s
if errorlevel 1 goto end

ca65 -g -t geos-cbm geoLinkIP65Stub.s
if errorlevel 1 goto end

grc65 -t geos-cbm geoLinkG.grc
if errorlevel 1 goto end
ca65 -t geos-cbm geoLinkG.s
if errorlevel 1 goto end

rem =========================
rem Link geoLink
rem =========================
ld65 -t geos-cbm -Ln geoLink.lbl -o geoLink.cvt -m geoLink.map geoLinkG.o geoLinkRes.o geoLinkVal.o geoLinkSetup.o geoLinkPing.o geoLinkLogin.o geoLinkIRC.o geoLinkFontStub.o geoLinkIP65Stub.o geos-cbm.lib ip65_tcp.lib ip65.lib
if errorlevel 1 goto end
rem ip65.lib

rem =========================
rem Assemble Embedder
rem =========================
ca65 -g -t geos-cbm geoLinkEmbed.s
if errorlevel 1 goto end
grc65 -t geos-cbm geoLinkEmbedG.grc
if errorlevel 1 goto end
ca65 -t geos-cbm geoLinkEmbedG.s
if errorlevel 1 goto end

rem =========================
rem Link Embedder
rem =========================
ld65 -t geos-cbm -Ln geoLinkEmbed.lbl -o geoLinkEmbed.cvt -m geoLinkEmbed.map geoLinkEmbedG.o geoLinkEmbed.o geos-cbm.lib
if errorlevel 1 goto end

:end
