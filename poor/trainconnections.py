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

import http.client
import json
from datetime import datetime
from datetime import timedelta
import xml.etree.ElementTree as ET
import urllib.parse

import poor
from poor.i18n import _

__all__ = ("TrainConnectionManager",)

class TrainConnectionManager:
    """ Managing search for connections. """

    def __init__(self):
        """ Initialize a :class:`TrainConnectionManager` instance. """

        self._clientID = poor.key.get("DBTRAININFORMATION_CLIENT")
        self._clientSecret = poor.key.get("DBTRAININFORMATION_SECRET")
        self._querys_cache = dict()
        self._timetable_cache = dict()
        self._eva_chache = dict()

    def get_suggestions(self, query: str, latitude: str, longitude: str):
        """ Load suggestions from DB-API based on query and latitude/longitude. """

        # Search for query in cache
        if query in self._querys_cache.keys():
            return self._querys_cache.get(query)
        
        # Initialize base HTTPSConnection object
        conn = http.client.HTTPSConnection("apis.deutschebahn.com")

        # Specify the requested headers
        headers = {
            'DB-Api-Key': self._clientSecret,
            'DB-Client-Id': self._clientID,
            'Accept': "application/vnd.de.db.ris+json"
            }

        # Send the get request to API
        conn.request("GET", "".join((
            # Enter query in url-format and replace '/' in the query with '%2F' (e.g. Köln Messe/Deutz)
            "/db-api-marketplace/apis/ris-stations/v1/stop-places/by-name/{}".format(urllib.parse.quote(query).replace('/', '%2F')),
            "?latitude={}".format(latitude),
            "&longitude={}".format(longitude),
            "&groupBy=STATION&sortBy=RELEVANCE&onlyActive=true&limit=8"
        )), "", headers)

        # Get response
        res = conn.getresponse()

        # Validate response
        if res.status == 200:
            # Response: Okay; Read data from response
            data = res.read()
            json_data = json.loads(data.decode('utf-8'))
            stations = []

            # Extract station name and EVA-Number from JSON
            for stop_place in json_data['stopPlaces']:
                stations.append((stop_place['names']['DE']['nameLong'], stop_place['evaNumber']))

            # If cache already holds 10 quereys, delete the oldets one
            if len(self._querys_cache.keys()) >= 10:
                self._querys_cache.pop(list(self._querys_cache.keys())[0])
            
            # Create return array 
            dict_array = [dict(
                status = 200,
                name   = name,
                eva    = eva
            ) for (name, eva) in stations]

            # Save array in cache and return it
            self._querys_cache[query] = dict_array
            return dict_array
        
        else:
            # Response: Error; Return array with error code and reason
            return [dict(status = res.status, reason = res.reason)]
    
    def search_connections(self, start_latitude: str, start_longitude: str, destination_eva: str, destination_name: str):
        """ Search for connection between start station at coordinates and destination from EVA-Number and name. """
        
        # Get EVA-Number of start railway station by coordinates
        (status, start_eva) = self._get_eva_number_coor(latitude=start_latitude, longitude=start_longitude)
        if status != 200:
            # Response: Error; Return array with error code and reason
            return [dict(status = status, reason = start_eva)]
        
        # Get timetable of start railway station by EVA-Number
        start_trains = self._get_train_dict_arr(eva_number=start_eva, date=datetime.today().strftime('%Y%m%d')[2:], hour=int(datetime.today().strftime('%H')), key="dp")
        if len(start_trains) > 0 and start_trains[0].get('status') != None:
            # Response: Error; Return array with error code and reason
            return start_trains

        # Initialize emtpy connections array
        self.connections = []

        # Search for direct connections
        for train in start_trains:
            # Check if one of the next stops of the train is the destination
            if destination_name in train.get('dp_stops'):
                # Direct connection possible; Search for specific train-connection
                date = datetime.today()
                hour = int(datetime.today().strftime('%H'))
                result = None; loop_counter = 0

                # Search for the next 5 hours or until a result is found
                while result == None and loop_counter < 6:
                    result = self._get_connection_dictionary(train_dict=train, destination_eva=destination_eva, destination_name=destination_name, date=date.strftime('%Y%m%d')[2:], hour=hour)
                    if result != None:
                        # Connection found. Append connection to array
                        self.connections.append([result])
                    
                    else:
                        # Change search-time 
                        if hour < 22:
                            # Search for next hour
                            hour += 1
                        else:
                            # Search on next day (e.g. train departs on 23:50)
                            date = datetime.today() + timedelta(days=1)
                            hour = 0

        # Check if direct connections are already found; If False search for connection with one transfer
        if len(self.connections) == 0:
            # Get timetable of destination railway station by EVA-Number
            destination_trains = self._get_train_dict_arr(eva_number=destination_eva, date=datetime.today().strftime('%Y%m%d')[2:], hour=int(datetime.today().strftime('%H')), key="ar")
            if len(destination_trains) > 0 and destination_trains[0].get('status') != None:
                # Response: Error; Return array with error code and reason
                return destination_trains

            # Initialize emtpy dicts to store possible connections between start, transfer and destination
            possible_start_to_transfer_results = dict()
            possible_transfer_to_destination_results = dict()

            # Iterate start and destination trains
            for start_train in start_trains:
                for dest_train in destination_trains:
            
                    # Search for accordance in next stops from start and previous stops from destination
                    for start_stop in start_train.get('dp_stops').split('|'):
                        for dest_stop in dest_train.get('ar_stops').split('|'):

                            if start_stop == dest_stop:
                                # Accordance found; Search for connection between start and possible transfer
                                date = datetime.today()
                                hour = int(datetime.today().strftime('%H'))
                                result = None; loop_counter = 0

                                while result == None and loop_counter < 6:
                                    result = self._get_information_from_start_to_transfer(train_dict=start_train, transfer_name=start_stop, date=date.strftime('%Y%m%d')[2:], hour=hour)

                                    if result != None:
                                        # Connection found. Check if result is unique
                                        if possible_start_to_transfer_results.get(result.get('train_id')) == None:
                                            possible_start_to_transfer_results[result.get('train_id')] = result
                                    
                                    else:
                                        # Change search-time 
                                        if hour < 22:
                                            # Search for next hour
                                            hour += 1
                                        else:
                                            # Search on next day (e.g. train departs on 23:50)
                                            date = datetime.today() + timedelta(days=1)
                                            hour = 0

            # Search for corresponding train-connection from transfer to destination
            for i in range(3):
                
                for start_transfer_dict in possible_start_to_transfer_results.values():
                    # Get timetable of transfer railway station by name
                    # Loop is necessary because connecting train can depart in next hour-range (e.g. Ar-Time 16:57 -> Dp-Time 17:13)
                    hour = int(start_transfer_dict.get('ar_time_hh')) + i
                    transfer_destination_trains = self._get_train_dict_arr(station_name=start_transfer_dict.get('transfer'), date=datetime.today().strftime('%Y%m%d')[2:], hour=hour, key="dp")
                    if len(destination_trains) > 0 and destination_trains[0].get('status') != None:
                        # Response: Error; Return array with error code and reason
                        return destination_trains

                    for transfer_destination_train in transfer_destination_trains:
                        # Check if a next stop of the train from transfer is the destination
                        if destination_name in transfer_destination_train.get('dp_stops'):
                            # Check if transfer time is gib enough (e.g. Ar-Time 15:30 -> Dp-Time 15:31 is not enough)
                            if self._validate_transfer_time(ar_time_hh=start_transfer_dict.get('ar_time_hh'), ar_time_mm=start_transfer_dict.get('ar_time_mm'), 
                                                            dp_time_hh=transfer_destination_train.get('dp_time_hh'), dp_time_mm=transfer_destination_train.get('dp_time_mm')):
                                
                                # Accaptable connecting train found; Search for actual connection between possible transfer and destination
                                date = datetime.today()
                                hour = int(datetime.today().strftime('%H'))
                                result = None; loop_counter = 0

                                while result == None and loop_counter < 6:
                                    result = self._get_information_from_transfer_to_end(transfer_train_dict=transfer_destination_train, destination_name=destination_name, date=date.strftime('%Y%m%d')[2:], hour=hour)

                                    if result != None:
                                        # Connection found. Check if result is unique
                                        if possible_transfer_to_destination_results.get(start_transfer_dict.get('train_id')) == None:
                                            possible_transfer_to_destination_results[start_transfer_dict.get('train_id')] = result
                                    
                                    else:
                                        # Change search-time 
                                        if hour < 22:
                                            # Search for next hour
                                            hour += 1
                                        else:
                                            # Search on next day (e.g. train departs on 23:50)
                                            date = datetime.today() + timedelta(days=1)
                                            hour = 0

            # Append the corresponding connections into the array
            for key in possible_start_to_transfer_results.keys():
                if key in possible_transfer_to_destination_results.keys():
                    self.connections.append([possible_start_to_transfer_results.get(key), possible_transfer_to_destination_results.get(key)])

        # Return the array
        return self.connections

    def clear_chache(self):
        """ Clear all caches. """

        self._querys_cache.clear()
        self._timetable_cache.clear()
        self._eva_chache.clear()

    def _get_eva_number_coor(self, latitude: str, longitude: str):
        """ Returns the EVA-Number by coordinates. """

        # Search for EVA-Number in cache
        cache_key = "".join((str(latitude), str(longitude)))
        if cache_key in self._eva_chache.keys():
            # Found in cache
            return (200, self._eva_chache.get(cache_key))

        # Initialize base HTTPSConnection object
        conn = http.client.HTTPSConnection("apis.deutschebahn.com")

        # Specify the requested headers
        headers = {
            'DB-Api-Key': self._clientSecret,
            'DB-Client-Id': self._clientID,
            'Accept': "application/vnd.de.db.ris+json"
            }


        # Send the get request to API
        conn.request("GET", "".join((
            "/db-api-marketplace/apis/ris-stations/v1/stop-places/by-position",
            "?latitude={}".format(latitude),
            "&longitude={}".format(longitude),
            "&groupBy=SALES&limit=1",
        )), "", headers)

        # Get response
        res = conn.getresponse()

        # Validate response
        if res.status == 200:
            # Response: Okay; Read data from response
            json_data = json.loads(res.read().decode('utf-8'))
            eva_number = json_data['stopPlaces'][0]['evaNumber']
            
            # Save EVA-Number in cache and return it
            self._eva_chache[cache_key] = eva_number
            return (res.status, eva_number)
        else:
            # Response: Error; Return array with error code and reason
            return (res.status, res.reason)
    
    def _get_eva_number_name(self, name: str):
        """ Returns the EVA-Number by name. """

        # Search for EVA-Number in cache
        cache_key = name
        if cache_key in self._eva_chache.keys():
            return (200, self._eva_chache.get(cache_key))
    
        # Initialize base HTTPSConnection object
        conn = http.client.HTTPSConnection("apis.deutschebahn.com")

        # Specify the requested headers
        headers = {
            'DB-Api-Key': self._clientSecret,
            'DB-Client-Id': self._clientID,
            'Accept': "application/vnd.de.db.ris+json"
            }

        # Send the get request to API
        conn.request("GET", "".join((
            # Enter query in url-format and replace '/' in the query with '%2F' (e.g. Köln Messe/Deutz)
            "/db-api-marketplace/apis/ris-stations/v1/stop-places/by-name/{}".format(urllib.parse.quote(name).replace('/', '%2F'))
        )), "", headers)

        # Get response
        res = conn.getresponse()

        # Validate response
        if res.status == 200:
            # Response: Okay; Read data from response
            json_data = json.loads(res.read().decode('utf-8'))
            eva_number = json_data['stopPlaces'][0]['evaNumber']

            # Save EVA-Number in cache and return it
            self._eva_chache[cache_key] = eva_number
            return (res.status, eva_number)
        else:
            # Response: Error; Return array with error code and reason
            return (res.status, res.reason)

    def _get_timetable_str(self, eva_number: str, date: str, hour: int):
        """ Load suggestions from DB-API based on query and latitude/longitude. """

        # Search for timetable in cache
        cache_key = "".join((str(eva_number), str(date), str(hour)))
        if cache_key in self._timetable_cache.keys():
            return (200, self._timetable_cache.get(cache_key))
        
        # Initialize base HTTPSConnection object
        conn = http.client.HTTPSConnection("apis.deutschebahn.com")
        
        # Specify the requested headers
        headers = {
            'DB-Api-Key': self._clientSecret,
            'DB-Client-Id': self._clientID,
            'Accept': "application/xml"
            }

        # Send the get request to API
        conn.request("GET", "".join((
            "/db-api-marketplace/apis/timetables/v1/plan/",
            "{}/".format(eva_number),
            "{}/".format(date),
            "{:02d}".format(hour),
        )), "", headers)

        # Get response
        res = conn.getresponse()

        # Validate response
        if res.status == 200:
            # Response: Okay; Read data from response
            timetable_str = res.read().decode("utf-8")

            # Save timetable in cache and return it
            self._timetable_cache[cache_key] = timetable_str
            return (res.status, timetable_str)
        else:
            # Response: Error; Return array with error code and reason
            return (res.status, res.reason)

    def _get_train_dict_arr(self, eva_number: str = '', date: str = '', hour: int = 0, key: str = '', station_name: str = ''):
        """ Return a Array of Dicts with the corresponding train-values. """

        # Get EVA-Number if only the station name is provided
        if eva_number == '' and station_name != '':
            (status, eva_number) = self._get_eva_number_name(name=station_name)
            if status != 200:
                # Response: Error; Return array with error code and reason
                return [dict(status = status, reason = result)]

        # Get timetable by EVA-Number
        (status, result) = self._get_timetable_str(eva_number=eva_number, date=date, hour=hour)
        if status != 200:
            # Response: Error; Return array with error code and reason
            return [dict(status = status, reason = result)]

        # Initialize XML-Object from timetable string
        xml_root = ET.fromstring(result)
        trains = []

        # Get every train that departs from or arrives at given station, depending on key
        for train in xml_root.iter('s'):
            # When looking for arrive key, check if train arrives and not just start from station and vice versa
            if train.find(key) != None:
                # Read the information if possible, otherwise use default value
                train_type = train.find('tl').attrib.get('c')   if train.find('tl').attrib.get('c')   != None else ""
                name       = train.find(key).attrib.get('l')    if train.find(key).attrib.get('l')    != None else ""
                train_id   = train.attrib.get('id')             if train.attrib.get('id')             != None else ""
                time       = train.find(key).attrib.get('pt')   if train.find(key).attrib.get('pt')   != None else ""
                track      = train.find(key).attrib.get('pp')   if train.find(key).attrib.get('pp')   != None else ""
                stops      = train.find(key).attrib.get('ppth') if train.find(key).attrib.get('ppth') != None else ""
                start      = xml_root.attrib.get('station')     if xml_root.attrib.get('station')     != None else ""

                # Creates a dictionary and initialize it with some of its values
                train_dict = dict(
                    type        = train_type,
                    name        = name,
                    train_id    = train_id,
                    destination = stops.split('|')[-1] if stops != "" else "",
                    start       = start,
                )
                # Add the remaining values by the key
                train_dict["".join((key, "_time_hh"))] = time[6:8] if len(time) > 9 else ""
                train_dict["".join((key, "_time_mm"))] = time[8:]  if len(time) > 9 else ""
                train_dict["".join((key, "_track"))]   = track
                train_dict["".join((key, "_stops"))]   = stops

                # Append the dictionary to the array
                trains.append(train_dict)

        # Sort trains by time; First by minutes then by hours (inner sort then outer sort)
        trains = sorted(trains, key=lambda x: x.get("".join((key, "_time_mm"))))
        trains = sorted(trains, key=lambda x: x.get("".join((key, "_time_hh"))))
        return trains

    def _get_connection_dictionary(self, train_dict: dict, destination_eva: str, destination_name: str, date: str, hour: int):
        """ Returns a dictionary with all connection information. """

        # Get timetable by EVA-Number
        (status, destination_timetable_str) = self._get_timetable_str(eva_number=destination_eva, date=date, hour=hour)
        if status == 200:
            # Response: Okay; Initialize XML-Object from timetable string
            destination_xml_root = ET.fromstring(destination_timetable_str)

            # Iterate over every upcoming stop of the given train
            for next_stop_name in train_dict.get('dp_stops').split('|'):
                # Check if the upcoming stop is the destination
                if next_stop_name == destination_name:
                    # Iterate over every incoming train on destination
                    for train in destination_xml_root.iter('s'):
                        # Search for matching train
                        if train.attrib.get('id')[:25] == train_dict.get('train_id')[:25]:
                            # Return the dictionary with corresponding information
                            return dict(
                                type        = train_dict.get('type'),
                                name        = train_dict.get('name'),
                                train_id    = train_dict.get('train_id'),
                                destination = train_dict.get('destination'),
                                start       = train_dict.get('start'),
                                target      = destination_name,
                                dp_time_hh  = train_dict.get('dp_time_hh'),
                                dp_time_mm  = train_dict.get('dp_time_mm'),
                                dp_track    = train_dict.get('dp_track'),
                                ar_time_hh  = train.find('ar').attrib.get('pt')[6:8] if train.find('ar').attrib.get('pt') != None else "",
                                ar_time_mm  = train.find('ar').attrib.get('pt')[8:] if train.find('ar').attrib.get('pt') != None else "",
                                ar_track    = train.find('ar').attrib.get('pp') if train.find('ar').attrib.get('pp') != None else "",
                            )
        
        # Return None if connection could not be found
        return None
    
    def _get_information_from_start_to_transfer(self, train_dict: dict, transfer_name: str, date: str, hour: int):
        """ Returns the connection dictionary from start to transfer with added value. """

        # Get EVA-Number of transfer railway station by name
        (status, transfer_eva) = self._get_eva_number_name(name=transfer_name)
        if status != 200:
            # Response: Error; Return None
            return None
        
        # Get connection dictionary
        connection_dict = self._get_connection_dictionary(train_dict=train_dict, destination_eva=transfer_eva, destination_name=transfer_name, date=date, hour=hour)

        # Check if connection was found
        if connection_dict != None:
            # Adds the transfer name to the dictionary
            connection_dict['transfer'] = transfer_name

        # Returns the dictionary or None if nothing was found
        return connection_dict
    
    def _get_information_from_transfer_to_end(self, transfer_train_dict: dict, destination_name: str, date: str, hour: int):
        """ Returns the connection dictionary from transfer to destination. """

        # Get EVA-Number of destination railway station by name
        (status, destination_eva) = self._get_eva_number_name(destination_name)
        if status != 200:
            # Response: Error; Return None
            return None
        
        # Returns the dictionary or None if nothing was found
        return self._get_connection_dictionary(train_dict=transfer_train_dict, destination_eva=destination_eva, destination_name=destination_name, date=date, hour=hour)

        
    def _validate_transfer_time(self, ar_time_hh: str, ar_time_mm: str, dp_time_hh: str, dp_time_mm: str):
        """ Validates the time needed for a transfer to be possible. """

        # Same hour; At least 5 minutes difference
        if int(dp_time_mm) >= (int(ar_time_mm) + 5) and int(dp_time_hh) >= int(ar_time_hh):
            return True
        
        # Not same hour (e.g. 15:57 -> 16:01)
        if int(ar_time_mm) - 55 <= int(dp_time_mm) and int(dp_time_hh) > int(ar_time_hh):
            return True
        
        return False