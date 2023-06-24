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

"""Managing search for timetables."""

import poor
import http.client
import json
import xml.etree.ElementTree as ET
import urllib.parse

from poor.i18n import _

__all__ = ("TrainConnectionManager",)

class TrainConnectionManager:

    """Managing search for timetables."""

    def __init__(self):
        """Initialize a :class:`TimetableManager` instance."""
        self._clientID = poor.key.get("DBTRAININFORMATION_CLIENT")
        self._clientSecret = poor.key.get("DBTRAININFORMATION_SECRET")

    def get_suggestions(self, latitude: str, longitude: str, query: str):
        conn = http.client.HTTPSConnection("apis.deutschebahn.com")

        headers = {
            'DB-Api-Key': self._clientSecret,
            'DB-Client-Id': self._clientID,
            'Accept': "application/vnd.de.db.ris+json"
            }

        conn.request("GET", "".join((
            "/db-api-marketplace/apis/ris-stations/v1/stop-places/by-name/{}".format(urllib.parse.quote(query).replace('/', '%2F')),
            "?latitude={}".format(latitude),
            "&longitude={}".format(longitude),
            "&groupBy=STATION&sortBy=RELEVANCE&onlyActive=true&limit=8"
        )), "", headers)

        res = conn.getresponse()
        data = res.read()
        json_data = json.loads(data.decode('utf-8'))
        names = []

        for stop_place in json_data['stopPlaces']:
            names.append(stop_place['names']['DE']['nameLong'])

        return [dict(
            status=res.status,
            name=name
        ) for name in names]
        