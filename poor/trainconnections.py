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
        self._querys = []

    def get_suggestions(self, latitude: str, longitude: str, query: str):
        for (que, stations) in self._querys:
            if que == query:
                return [dict(
                    status=200,
                    name=name,
                    eva=eva
                ) for (name, eva) in stations]
        
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
            "&groupBy=STATION&sortBy=RELEVANCE&onlyActive=true&limit=5"
        )), "", headers)

        res = conn.getresponse()
        data = res.read()
        json_data = json.loads(data.decode('utf-8'))
        stations = []

        for stop_place in json_data['stopPlaces']:
            stations.append((stop_place['names']['DE']['nameLong'], stop_place['evaNumber']))

        if len(self._querys) >= 8:
            self._querys.pop(0)
        
        self._querys.append((query, stations))

        return [dict(
            status=res.status,
            name=name,
            eva=eva
        ) for (name, eva) in stations]
    
    def search_connection(self, start_latitude: str, start_longitude: str, dest_eva: str):
        None