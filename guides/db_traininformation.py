# -*- coding: utf-8 -*-

# Copyright (C) 2023 lhaenschke
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

"""
Get Train-Informations in Germany

https://developers.deutschebahn.com
"""

import poor
import http.client

CLIENT_ID = poor.key.get("DBTRAININFORMATION_CLIENT")
CLIENT_SECRET = poor.key.get("DBTRAININFORMATION_SECRET")


def loadTrainInformation(longitude, latitude):
    conn = http.client.HTTPSConnection("apis.deutschebahn.com")

    payload = ""

    headers = {
        'DB-Api-Key': CLIENT_SECRET,
        'DB-Client-Id': CLIENT_ID,
        'Accept': "application/vnd.de.db.ris+json"
        }

    conn.request("GET", "".join((
        "/db-api-marketplace/apis/ris-stations/v1/stop-places/by-position",
        "?latitude={}".format(latitude),
        "&longitude={}".format(longitude),
        "&groupBy=SALES&limit=1",
    )), payload, headers)

    res = conn.getresponse()
    data = res.read()
