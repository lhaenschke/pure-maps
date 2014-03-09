# -*- coding: utf-8 -*-

# Copyright (C) 2014 Osmo Salomaa
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

"""An application to display maps and stuff."""

__version__ = "0.0"

# XXX: Try to avoid segfaults?
import threading
threading.stack_size(10*1024*1024)

from poor.paths import *
from poor import util

from poor.config import *
conf = ConfigurationStore()

from poor.tilecollection import *
from poor.tilesource import *
from poor.application import *

def main():
    """Initialize application."""
    import pyotherside
    conf.read()
    pyotherside.atexit(conf.write)
    global app
    app = Application()
    # XXX: Try to crash less often.
    import time
    time.sleep(1)
