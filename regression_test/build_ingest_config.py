# -*- coding: utf-8 -*-

"""
Build a config that has task type == INGEST
resource_id sc2repo
use_local_files == False

All tests use the proxy cert.
"""
import logging
import sys
from caom2pipe import manage_composable as mc

collection = sys.argv[1]

print(f'::: modify config for ingest')
config = mc.Config()
config.get_executors()
config.netrc_file = None
config.proxy_file_name = 'cadcproxy.pem'
config.task_types = [mc.TaskType.INGEST]
config.use_local_files = False
config.log_to_file = True
config.logging_level = logging.INFO
if collection == 'vlass':
    config.data_sources = ['https://archive-new.nrao.edu/vlass/se_continuum_imaging/']
    config.data_source_extensions = ['.catalog.csv', '.fits']
config.tap_id = 'ivo://cadc.nrc.ca/global/luskan'
config.resource_id = 'ivo://cadc.nrc.ca/sc2repo'
mc.Config.write_to_file(config)

sys.exit(0)
