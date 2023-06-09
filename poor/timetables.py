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
from datetime import datetime
import xml.etree.ElementTree as ET

from poor.i18n import _

__all__ = ("TimetableManager",)

class TimetableManager:

    """Managing search for timetables."""

    def __init__(self):
        """Initialize a :class:`TimetableManager` instance."""
        self._clientID = poor.key.get("DBTRAININFORMATION_CLIENT")
        self._clientSecret = poor.key.get("DBTRAININFORMATION_SECRET")
        self.trains = []

    def search(self, latitude: str, longitude: str, hour: int):
        eva_number = self.__get_eva_number__(latitude, longitude)
        
        xml_root = ET.fromstring(self.__get_timetable_str(eva_number, hour))
        self.trains = []

        for train in xml_root.iter('s'):
            self.trains.append(Traininformation(
                train_type = train.find('tl').attrib['c'],
                name = train.find('ar').attrib['l'],
                dep_time = train.find('dp').attrib['pt'],
                track = train.find('dp').attrib['pp'],
                next_stops = train.find('dp').attrib['ppth'].split('|')
            ))

        self.trains = sorted(self.trains, key=lambda x: x.dep_time)

        for train in self.trains:
            print(train.type, train.name, train.dep_time_hh, train.dep_time_mm, train.track, train.next_stops)


    def get_trains(self):
        return self.trains

    def __get_eva_number__(self, latitude: str, longitude: str) -> str:
        conn = http.client.HTTPSConnection("apis.deutschebahn.com")

        headers = {
            'DB-Api-Key': self._clientSecret,
            'DB-Client-Id': self._clientID,
            'Accept': "application/vnd.de.db.ris+json"
            }

        conn.request("GET", "".join((
            "/db-api-marketplace/apis/ris-stations/v1/stop-places/by-position",
            "?latitude={}".format(latitude),
            "&longitude={}".format(longitude),
            "&groupBy=SALES&limit=1",
        )), "", headers)

        res = conn.getresponse()
        data = res.read()
        json_data = json.loads(data.decode('utf-8'))

        return json_data['stopPlaces'][0]['evaNumber']

    def __get_timetable_str(self, eva_number: str, hour: int) -> str:
        conn = http.client.HTTPSConnection("apis.deutschebahn.com")
        headers = {
            'DB-Api-Key': self._clientSecret,
            'DB-Client-Id': self._clientID,
            'Accept': "application/xml"
            }

        conn.request("GET", "".join((
            "/db-api-marketplace/apis/timetables/v1/plan/",
            "{}/".format(eva_number),
            "{}/".format(datetime.today().strftime('%Y%m%d')[2:]),
            "{}".format(hour),
        )), "", headers)

        res = conn.getresponse()
        data = res.read()

        return data.decode("utf-8")

class Traininformation:

        """Store train-informations"""

        def __init__(self, train_type: str, name: str, dep_time: str, track: str, next_stops: str):
            self.type = train_type
            self.name = name
            self.dep_time = dep_time
            self.dep_time_hh = self.dep_time[6:8]
            self.dep_time_mm = self.dep_time[8:]
            self.track = track
            self.next_stops = next_stops
