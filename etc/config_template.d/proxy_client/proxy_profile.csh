#!/bin/csh
setent https_proxy __PROXY_SERVER__:__PROXY_PORT__
setent http_proxy __PROXY_SERVER__:__PROXY_PORT__
setent ftp_proxy __PROXY_SERVER__:__PROXY_PORT__
