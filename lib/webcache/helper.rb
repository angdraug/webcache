# WebCache Helper
#
#   Copyright (c) 2013  Dmitry Borodaenko <angdraug@debian.org>
#
#   This program is free software.
#   You can distribute/modify this program under the terms of
#   the GNU General Public License version 3 or later.
#
# vim: et sw=2 sts=2 ts=8 tw=0

require 'socket'

module WebCache

class Helper
  def Helper.socket_peer(socket)
    socket.getaddr(:numeric)[1, 2].reverse.join(':')
  end
end

end
