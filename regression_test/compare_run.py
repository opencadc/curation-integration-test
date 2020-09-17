# -*- coding: utf-8 -*-

import io
import logging
import sys
from astropy.table import Table
from cadcutils import net, exceptions
from cadctap import CadcTapClient
from caom2repo import CAOM2RepoClient
from caom2pipe import manage_composable as mc

collection = sys.argv[1].upper()
if collection == 'GEM':
    collection = 'GEMINI'
proxy_fqn = '/usr/src/app/cadcproxy.pem'
subject = net.Subject(certificate=proxy_fqn)
caom_client = CAOM2RepoClient(subject, resource_id='ivo://cadc.nrc.ca/sc2repo')

print()
print()
print()

todo_list = []
with open('/usr/src/app/logs/success_log.txt', 'r') as f:
    for line in f:
        temp = line.split()
        obs_id = temp[2]
        print(f'Working with {obs_id}')

        expected_fqn = f'/usr/src/app/expected.{obs_id}.xml'
        actual_fqn = f'/usr/src/app/{obs_id}.fits.xml'
        round_trip_fqn = f'/usr/src/app/round_trip.{obs_id}.xml'
        print(f'::: read obs from file {actual_fqn}')
        actual_obs = mc.read_obs_from_file(actual_fqn)
        # write to sc2repo
        # read from sc2repo, to get the plane-level metadata if calculated by
        # service
        try:
            caom_client.delete(collection, obs_id)
        except exceptions.NotFoundException as e:
            pass
        print(f'::: create observation {collection} {obs_id}')
        caom_client.create(actual_obs)
        print(f'::: read observation from sc2repo')
        obs_from_service = caom_client.read(collection, obs_id)
        mc.write_obs_to_file(obs_from_service, round_trip_fqn)
        msg = mc.compare_observations(round_trip_fqn, expected_fqn)
        print(msg)
        for plane in obs_from_service.planes.values():
            for artifact in plane.artifacts.values():
                if '.fits' in artifact.uri:
                    f_name = mc.CaomName(uri=artifact.uri).file_name
                    todo_list.append(f_name)

print('::: update the config for ingest')

config = mc.Config()
config.get_executors()
config.use_local_files = False
config.task_types = [mc.TaskType.INGEST]
config.resource_id = 'ivo://cadc.nrc.ca/sc2repo'
config.logging_level = logging.INFO
mc.Config.write_to_file(config)

with open(config.work_fqn, 'w') as f:
    for entry in todo_list:
        f.write(f'{entry}\n')


sys.exit(0)
