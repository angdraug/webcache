#!/usr/bin/env ruby
#
# WebCache proxy service
#
#   Copyright (c) 2013  Dmitry Borodaenko <angdraug@debian.org>
#
#   This program is free software.
#   You can distribute/modify this program under the terms of
#   the GNU General Public License version 3 or later.
#
# vim: et sw=2 sts=2 ts=8 tw=0

require 'webcache'

server = WebCache::Server.new('localhost', 8088, 30)
server.run
