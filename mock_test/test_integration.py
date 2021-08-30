# -*- coding: utf-8 -*-
# ***********************************************************************
# ******************  CANADIAN ASTRONOMY DATA CENTRE  *******************
# *************  CENTRE CANADIEN DE DONNÉES ASTRONOMIQUES  **************
#
#  (c) 2021.                            (c) 2021.
#  Government of Canada                 Gouvernement du Canada
#  National Research Council            Conseil national de recherches
#  Ottawa, Canada, K1A 0R6              Ottawa, Canada, K1A 0R6
#  All rights reserved                  Tous droits réservés
#
#  NRC disclaims any warranties,        Le CNRC dénie toute garantie
#  expressed, implied, or               énoncée, implicite ou légale,
#  statutory, of any kind with          de quelque nature que ce
#  respect to the software,             soit, concernant le logiciel,
#  including without limitation         y compris sans restriction
#  any warranty of merchantability      toute garantie de valeur
#  or fitness for a particular          marchande ou de pertinence
#  purpose. NRC shall not be            pour un usage particulier.
#  liable in any event for any          Le CNRC ne pourra en aucun cas
#  damages, whether direct or           être tenu responsable de tout
#  indirect, special or general,        dommage, direct ou indirect,
#  consequential or incidental,         particulier ou général,
#  arising from the use of the          accessoire ou fortuit, résultant
#  software.  Neither the name          de l'utilisation du logiciel. Ni
#  of the National Research             le nom du Conseil National de
#  Council of Canada nor the            Recherches du Canada ni les noms
#  names of its contributors may        de ses  participants ne peuvent
#  be used to endorse or promote        être utilisés pour approuver ou
#  products derived from this           promouvoir les produits dérivés
#  software without specific prior      de ce logiciel sans autorisation
#  written permission.                  préalable et particulière
#                                       par écrit.
#
#  This file is part of the             Ce fichier fait partie du projet
#  OpenCADC project.                    OpenCADC.
#
#  OpenCADC is free software:           OpenCADC est un logiciel libre ;
#  you can redistribute it and/or       vous pouvez le redistribuer ou le
#  modify it under the terms of         modifier suivant les termes de
#  the GNU Affero General Public        la “GNU Affero General Public
#  License as published by the          License” telle que publiée
#  Free Software Foundation,            par la Free Software Foundation
#  either version 3 of the              : soit la version 3 de cette
#  License, or (at your option)         licence, soit (à votre gré)
#  any later version.                   toute version ultérieure.
#
#  OpenCADC is distributed in the       OpenCADC est distribué
#  hope that it will be useful,         dans l’espoir qu’il vous
#  but WITHOUT ANY WARRANTY;            sera utile, mais SANS AUCUNE
#  without even the implied             GARANTIE : sans même la garantie
#  warranty of MERCHANTABILITY          implicite de COMMERCIALISABILITÉ
#  or FITNESS FOR A PARTICULAR          ni d’ADÉQUATION À UN OBJECTIF
#  PURPOSE.  See the GNU Affero         PARTICULIER. Consultez la Licence
#  General Public License for           Générale Publique GNU Affero
#  more details.                        pour plus de détails.
#
#  You should have received             Vous devriez avoir reçu une
#  a copy of the GNU Affero             copie de la Licence Générale
#  General Public License along         Publique GNU Affero avec
#  with OpenCADC.  If not, see          OpenCADC ; si ce n’est
#  <http://www.gnu.org/licenses/>.      pas le cas, consultez :
#                                       <http://www.gnu.org/licenses/>.
#
#  : 4 $
#
# ***********************************************************************
#

import caom2utils.data_util
import dateutil
import json
import logging
import os
import shutil
import sys
import traceback

from astropy.io import fits
from collections import namedtuple
from datetime import datetime, timedelta
from importlib import import_module, reload
from pathlib import Path
from unittest.mock import call, Mock, patch

from cadcutils import exceptions
from cadcdata import FileInfo
from caom2 import SimpleObservation, Algorithm, Instrument
from caom2pipe import manage_composable as mc

THIS_DIR = Path(os.path.dirname(os.path.realpath(__file__)))
TEST_DIR = THIS_DIR / 'data'
TEST_EXEC_DIR = TEST_DIR / 'execution'
TEST_DATA_DIR = TEST_DIR / 'test_files'

TestInputs = namedtuple(
    'TestInputs',
    'test_path, '
    'config_file, '
    'state_file, '
    'bookmark, '
    'cache_file, '
    'test_file, '
    'obs_xml, '
    'input_dir, '
    'test_uri, '
    'collection',
)
INPUTS = {
    'OMM_TODO_LOCAL': TestInputs(
        '/usr/src/app/omm2caom2/omm2caom2',
        Path(f'{TEST_DIR}/omm/config.yml.local'),
        None,
        None,
        None,
        Path(f'{TEST_DIR}/omm/C170324_0054_SCI.fits.gz'),
        None,
        None,
        'cadc:OMM/C170324_0054_SCI.fits.gz',
        'OMM',
    ),
    'GEM_STATE': TestInputs(
        '/usr/src/app/gem2caom2/gem2caom2',
        Path(TEST_DIR / 'gemini/config.yml.state'),
        Path(TEST_DIR / 'gemini/state.yml'),
        'gemini_timestamp',
        Path(TEST_DIR / 'gemini/cache.yml'),
        None,
        None,
        Path(TEST_DIR / 'gemini'),
        None,
        None,
    ),
    'VLASS_STATE': TestInputs(
        '/usr/src/app/vlass2caom2/vlass2caom2',
        Path(f'{TEST_DIR}/vlass/config.yml.state'),
        Path(f'{TEST_DIR}/vlass/state.yml'),
        'vlass_timestamp',
        None,
        None,
        None,
        None,
        None,
        None,
    ),
    'VLASS_TODO_LOCAL': TestInputs(
        '/usr/src/app/vlass2caom2/vlass2caom2',
        Path(f'{TEST_DIR}/vlass/config.yml.local'),
        Path(f'{TEST_DIR}/vlass/state.yml'),
        'vlass_timestamp',
        None,
        Path(
            f'{TEST_DIR}/vlass/test_files/VLASS1.1.ql.T01t01.'
            f'J000228-363000.10.2048.v2.I.iter1.image.pbcor.tt0.subim.fits'
        ),
        Path(f'{TEST_DIR}/vlass/VLASS1.1.T01t01.J000228-363000.xml'),
        None,
        None,
        None,
    ),
    'GEM_TODO_LOCAL': TestInputs(
        '/usr/src/app/gem2caom2/gem2caom2',
        Path(TEST_DIR / 'gemini/config.yml.todo_local'),
        Path(TEST_DIR / 'gemini/state.yml'),
        'gemini_timestamp',
        Path(TEST_DIR / 'gemini/cache.yml'),
        Path(TEST_DIR / 'gemini/S20191214S0301.fits'),
        None,
        Path(TEST_DIR / 'gemini'),
        None,
        None,
    ),
    'GEM_TODO': TestInputs(
        '/usr/src/app/gem2caom2/gem2caom2',
        Path(TEST_DIR / 'gemini/config.yml.todo'),
        Path(TEST_DIR / 'gemini/state.yml'),
        'gemini_timestamp',
        Path(TEST_DIR / 'gemini/cache.yml'),
        Path(TEST_DIR / 'gemini/S20191214S0301.fits'),
        None,
        Path(TEST_DIR / 'gemini'),
        None,
        None,
    ),
    'DAO_TODO_VOS': TestInputs(
        '/usr/src/app/dao2caom2/dao2caom2',
        Path(f'{TEST_DIR}/dao/config.yml.vo'),
        None,
        None,
        None,
        None,
        None,
        None,
        None,
        None,
    ),
    'NEOSSAT_STATE': TestInputs(
        '/usr/src/app/neossat2caom2/neossat2caom2',
        Path(f'{TEST_DIR}/neossat/config.yml.state'),
        Path(f'{TEST_DIR}/neossat/state.yml'),
        'neossat_timestamp',
        None,
        None,
        None,
        None,
        None,
        None,
    ),
    'NEOSSAT_TODO_LOCAL': TestInputs(
        '/usr/src/app/neossat2caom2/neossat2caom2',
        Path(f'{TEST_DIR}/neossat/config.yml.local'),
        None,
        None,
        None,
        Path(f'{TEST_DIR}/neossat/NEOS_SCI_2019213215700.fits'),
        None,
        None,
        'cadc:NEOSSAT/NEOS_SCI_2019213215700.fits',
        'NEOSSAT',
    ),
    'CFHT_TODO_LOCAL_MOVE': TestInputs(
        '/usr/src/app/cfht2caom2/cfht2caom2',
        Path(f'{TEST_DIR}/cfht/config.yml.local_move'),
        None,
        None,
        Path(f'{TEST_DIR}/cfht/cache.yml'),
        Path(f'{TEST_DIR}/cfht/2460606o.fits.gz'),
        None,
        None,
        None,
        None,
    ),
}


def _nrao_mock(start_time):
    record_time = start_time + timedelta(minutes=2)
    a = {
        record_time.timestamp(): [
            'https://archive-new.nrao.edu/vlass/quicklook/VLASS1.1/'
            'T07t13/VLASS1.1.ql.T07t13.J083838-153000.10.2048.v1.I.'
            'iter1.image.pbcor.tt0.rms.subim.fits',
        ],
    }
    b = start_time + timedelta(minutes=7)
    return a, b


def pytest_generate_tests(metafunc):
    metafunc.parametrize('test_input_name', INPUTS.keys())


@patch('vlass2caom2.metadata.VLASSCache.is_qa_rejected')
@patch('caom2utils.data_util.get_local_file_headers')
@patch('caom2pipe.transfer_composable.HttpTransfer')
@patch('caom2pipe.client_composable.ClientCollection')
@patch('vlass2caom2.scrape.build_file_url_list')
@patch('vlass2caom2.scrape.init_web_log_content')
@patch('caom2utils.data_util.StorageClientWrapper')
def test_state(
    data_mock,
    web_log_mock,
    nrao_mock,
    caom_mock,
    transfer_mock,
    local_header_mock,
    qa_mock,
    test_input_name,
):
    if 'TODO' in test_input_name:
        return

    test_input = INPUTS.get(test_input_name)

    # make sure the working directory TEXT_EXEC_DIR has nothing in it
    for child in TEST_EXEC_DIR.iterdir():
        if child == TEST_EXEC_DIR:
            continue
        if child.is_dir():
            for child_2 in child.iterdir():
                child_2.unlink()
            child.rmdir()
        else:
            child.unlink()

    # make sure the working directory TEST_EXEC_DIR has the correct things
    # in it
    config_file_target = TEST_EXEC_DIR / 'config.yml'
    shutil.copy(test_input.config_file, config_file_target)
    state_file_target = TEST_EXEC_DIR / 'state.yml'
    shutil.copy(test_input.state_file, state_file_target)

    with open(TEST_EXEC_DIR / 'cadcproxy.pem', 'w') as f:
        f.write('test content')

    # make the state file won't take decades to execute
    test_start_time = datetime.now(tz=dateutil.tz.UTC) - timedelta(minutes=5)
    state = mc.State(state_file_target.as_posix())
    state.save_state(test_input.bookmark, test_start_time)

    # import the module for execution
    sys.path.append(test_input.test_path)
    test_module = import_module('composable')

    nrao_mock.side_effect = _nrao_mock

    def _web_log_init(ignore):
        global web_log_content
        web_log_content = {
            'VLASS1.1_T07t13.J083838-153000_P68878v1_2020_08_29T21_'
            '48_48.092': '2020-09-09 07:53',
        }
    web_log_mock.side_effect = _web_log_init

    def _transfer_get(src, dst):
        assert (
            src ==
            'https://archive-new.nrao.edu/vlass/quicklook/VLASS1.1/T07t13/'
            'VLASS1.1.ql.T07t13.J083838-153000.10.2048.v1.I.iter1.image.'
            'pbcor.tt0.rms.subim.fits'
        ), 'wrong source'
        assert (
            dst ==
            '/usr/src/app/integration_test/mock_test/data/execution/'
            'VLASS1.1.T07t13.J083838-153000/'
            'VLASS1.1.ql.T07t13.J083838-153000.10.2048.v1.I.iter1.image.'
            'pbcor.tt0.rms.subim.fits'
        ), 'wrong dst'
        with open(dst, 'w') as f2:
            f2.write('test content')
    transfer_mock.return_value.get.side_effect = _transfer_get

    caom_mock.return_value.metadata_client.read.side_effect = [
        None,
        SimpleObservation(
            'obs_id',
            'VLASS',
            Algorithm(name='exposure'),
        ),
    ]

    def _local_header(ignore):
        x = """SIMPLE  =                    T / Written by IDL:  Fri Oct  6 01:48:35 2017
BITPIX  =                  -32 / Bits per pixel
NAXIS   =                    2 / Number of dimensions
NAXIS1  =                 2048 /
NAXIS2  =                 2048 /
TYPE    = 'image'
BMAJ    = 1.09
BMIN    = 0.19
DATATYPE= 'REDUC   '           /Data type, SCIENCE/CALIB/REJECT/FOCUS/TEST
END
"""
        delim = '\nEND'
        extensions = \
            [e + delim for e in x.split(delim) if e.strip()]
        headers = [fits.Header.fromstring(e, sep='\n') for e in extensions]
        return headers
    local_header_mock.side_effect = _local_header

    def _info(uri):
        return FileInfo(
            id=uri,
            md5sum='abc',
            size=42,
        )
    data_mock.return_value.info.side_effect = _info
    qa_mock.return_value = False

    getcwd_orig = os.getcwd
    os.getcwd = Mock(return_value=TEST_EXEC_DIR)
    logging.getLogger('StorageClientWrapper').setLevel(logging.DEBUG)
    try:
        test_result = test_module._run_state()
        assert test_result is not None, f'expect a result {test_input_name}'
        assert test_result == 0, f'wrong test result {test_input_name}'

        # was state updated?
        post_state = mc.State(state_file_target.as_posix())
        assert (
            post_state.get_bookmark(test_input.bookmark) > test_start_time
        ), f'state not updated {test_input_name}'
        assert (
            caom_mock.return_value.data_client.put.called
        ), f'{test_input_name} put not called'
        caom_mock.return_value.data_client.put.assert_called_with(
            '/usr/src/app/integration_test/mock_test/data/execution/'
            'VLASS1.1.T07t13.J083838-153000',
            'nrao:VLASS/VLASS1.1.ql.T07t13.J083838-153000.10.2048.v1.I.'
            'iter1.image.pbcor.tt0.rms.subim.fits',
            None,
        ), f'{test_input_name} wrong put args'
    finally:
        os.getcwd = getcwd_orig
        del sys.modules['composable']


@patch('caom2utils.data_util.get_local_file_headers')
@patch('caom2pipe.transfer_composable.FtpTransfer')
@patch('caom2pipe.client_composable.ClientCollection')
@patch('neossat2caom2.scrape._append_todo')
@patch('caom2utils.data_util.StorageClientWrapper')
def test_neoss_state(
    data_mock,
    csa_mock,
    caom_mock,
    transfer_mock,
    local_header_mock,
    test_input_name,
):
    if 'NEOSS' not in test_input_name:
        return

    test_input = INPUTS.get(test_input_name)

    # make sure the working directory TEXT_EXEC_DIR has nothing in it
    _cleanup()

    # make sure the working directory TEST_EXEC_DIR has the correct things
    # in it
    config_file_target = TEST_EXEC_DIR / 'config.yml'
    shutil.copy(test_input.config_file, config_file_target)
    state_file_target = TEST_EXEC_DIR / 'state.yml'
    shutil.copy(test_input.state_file, state_file_target)

    with open(TEST_EXEC_DIR / 'cadcproxy.pem', 'w') as f:
        f.write('test content')

    # make the state file won't take decades to execute
    test_start_time = datetime.now(tz=dateutil.tz.UTC) - timedelta(minutes=5)
    state = mc.State(state_file_target.as_posix())
    state.save_state(test_input.bookmark, test_start_time)

    def _csa_mock(start_date, ign1, ign2, ign3, ign4, ign5):
        return {
            '/users/OpenData_DonneesOuvertes/pub/NEOSSAT/ASTRO/2019/256/'
            'NEOS_SCI_2019213215700.fits':
                [False, start_date + timedelta(minutes=5).total_seconds()],
        }

    csa_mock.side_effect = _csa_mock

    def _transfer_get(src, dst):
        assert (
                src ==
                '/users/OpenData_DonneesOuvertes/pub/NEOSSAT/ASTRO/2019/256/'
                'NEOS_SCI_2019213215700.fits'
        ), 'wrong source'
        assert (
                dst ==
                '/usr/src/app/integration_test/mock_test/data/execution/'
                '2019213215700/NEOS_SCI_2019213215700.fits'
        ), 'wrong dst'
        with open(dst, 'w') as f2:
            f2.write('test content')
    transfer_mock.return_value.get.side_effect = _transfer_get

    caom_mock.return_value.metadata_client.read.side_effect = [
        None,
        SimpleObservation(
            'obs_id',
            'NEOSSAT',
            Algorithm(name='exposure'),
        ),
    ]

    def _local_header(ignore):
        x = """SIMPLE  =                    T / Written by IDL:  Fri Oct  6 01:48:35 2017
BITPIX  =                  -32 / Bits per pixel
NAXIS   =                    2 / Number of dimensions
NAXIS1  =                   14 /
NAXIS2  =                   24 /
RA      = '22:53:27.5'
DEC     = '-30:04:37.6'
MODE    = '14 - FINE_SETTLE'
OBJECT  = '2020-P4-C'
EXPOSURE=             128.0311
DATATYPE= 'REDUC   '           /Data type, SCIENCE/CALIB/REJECT/FOCUS/TEST
END
"""
        delim = '\nEND'
        extensions = \
            [e + delim for e in x.split(delim) if e.strip()]
        headers = [fits.Header.fromstring(e, sep='\n') for e in extensions]
        return headers
    local_header_mock.side_effect = _local_header

    def _info(uri):
        return FileInfo(
            id=uri,
            md5sum='abc',
            size=42,
        )
    data_mock.return_value.info.side_effect = _info

    # import the module for execution
    sys.path.append(test_input.test_path)
    test_module = import_module('composable')

    getcwd_orig = os.getcwd
    os.getcwd = Mock(return_value=TEST_EXEC_DIR)
    try:
        test_result = test_module._run_state()
        assert test_result is not None, f'expect a result {test_input_name}'
        assert test_result == 0, f'wrong test result {test_input_name}'

        # was state updated?
        post_state = mc.State(state_file_target.as_posix())
        assert (
                post_state.get_bookmark(test_input.bookmark) > test_start_time
        ), f'state not updated {test_input_name}'
        assert (
            caom_mock.return_value.data_client.put.called
        ), f'{test_input_name} put not called'
        caom_mock.return_value.data_client.put.assert_called_with(
            '/usr/src/app/integration_test/mock_test/data/execution/'
            '2019213215700',
            'cadc:NEOSSAT/NEOS_SCI_2019213215700.fits',
            None,
        ), f'{test_input_name} wrong put args'
    except Exception as e:
        logging.error(traceback.format_exc())
        raise e
    finally:
        os.getcwd = getcwd_orig
        del sys.modules['composable']


@patch('vlass2caom2.metadata.VLASSCache.is_qa_rejected')
@patch('vlass2caom2.scrape.build_qa_rejected_todo')
@patch('vlass2caom2.scrape.init_web_log_content')
@patch('caom2pipe.client_composable.ClientCollection')
@patch('cadcutils.net.ws.WsCapabilities.get_access_url')
@patch('vlass2caom2.scrape.build_file_url_list')
def test_todo_local(
    nrao_mock,
    access_mock,
    caom_mock,
    web_log_mock,
    build_qa_mock,
    qa_mock,
    test_input_name,
):
    if 'LOCAL' not in test_input_name:
        return

    access_mock.return_value = 'https://localhost'
    test_input = INPUTS.get(test_input_name)
    _cleanup()

    # make sure the working directory TEST_EXEC_DIR has the correct things
    # in it
    config_file_target = TEST_EXEC_DIR / 'config.yml'
    shutil.copy(test_input.config_file, config_file_target)
    # need this for the context
    state_file_target = TEST_EXEC_DIR / 'state.yml'
    shutil.copy(test_input.state_file, state_file_target)

    with open(TEST_EXEC_DIR / 'cadcproxy.pem', 'w') as f:
        f.write('test content')

    TEST_DATA_DIR.mkdir(exist_ok=True)
    test_file_fqn = TEST_DATA_DIR / test_input.test_file.name
    shutil.copy(test_input.test_file, test_file_fqn)

    getcwd_orig = os.getcwd
    os.getcwd = Mock(return_value=TEST_EXEC_DIR)

    # import the module for execution
    sys.path.append(test_input.test_path)
    sys.path.append(f'{test_input.test_path}/tests')
    test_module = import_module('composable')

    interim_observation = mc.read_obs_from_file(test_input.obs_xml.as_posix())
    caom_mock.return_value.metadata_client.read.side_effect = [
        None,
        interim_observation,
    ]

    def _web_log_init(ignore):
        global web_log_content
        web_log_content = {
            'VLASS1.1_T01t01.J000228-363000_P68878v1_2020_08_29T21_'
            '48_48.092': '2020-09-09 07:53',
        }
    web_log_mock.side_effect = _web_log_init

    nrao_mock.side_effect = _nrao_mock
    build_qa_mock.return_value = ([], None)
    qa_mock.return_value = False
    try:
        test_result = test_module._run()
        assert test_result is not None, f'expect a result {test_input_name}'
        assert test_result == 0, f'wrong test result {test_input_name}'
        assert (
            caom_mock.return_value.data_client.put.called
        ), f'{test_input_name} put not called'
        assert (
            caom_mock.return_value.data_client.put.call_count == 3
        ), 'wrong call count'
        put_calls = [
            call(
                '/usr/src/app/integration_test/mock_test/data/test_files',
                f'nrao:VLASS/{test_input.test_file.name}',
                None,
            ),
            call(
                '/usr/src/app/integration_test/mock_test/data/execution/'
                'VLASS1.1.T01t01.J000228-363000',
                'cadc:VLASS/VLASS1.1.ql.T01t01.J000228-363000.10.2048.v2.I.'
                'iter1.image.pbcor.tt0.subim_prev.jpg',
                None
            ),
            call(
                '/usr/src/app/integration_test/mock_test/data/execution/'
                'VLASS1.1.T01t01.J000228-363000',
                'cadc:VLASS/VLASS1.1.ql.T01t01.J000228-363000.10.2048.v2.I.'
                'iter1.image.pbcor.tt0.subim_prev_256.jpg',
                None
            ),
        ]
        caom_mock.return_value.data_client.put.assert_has_calls(
            put_calls
        ), f'{test_input_name} wrong put args'
    finally:
        os.getcwd = getcwd_orig
        del sys.modules['composable']


@patch('caom2utils.fits2caom2.data_util.StorageClientWrapper')
@patch('dao2caom2.transfer.VoFitsCleanupTransfer')
@patch('cadcutils.net.ws.WsCapabilities.get_access_url')
@patch('caom2pipe.client_composable.ClientCollection')
@patch('vos.Client')
def test_todo_vos(
    vo_mock,
    caom_mock,
    access_mock,
    transfer_mock,
    fits2caom2_mock,
    test_input_name,
):
    if 'VOS' not in test_input_name:
        return
    test_input = INPUTS.get(test_input_name)
    _cleanup()
    access_mock.return_value = 'https://localhost'

    # make sure the working directory TEST_EXEC_DIR has the correct things
    # in it
    config_file_target = TEST_EXEC_DIR / 'config.yml'
    shutil.copy(test_input.config_file, config_file_target)
    with open(TEST_EXEC_DIR / 'cadcproxy.pem', 'w') as f:
        f.write('test content')

    # import the module for execution
    sys.path.append(test_input.test_path)
    test_module = import_module('composable')
    reload(test_module)
    logging.error(dir(test_module))

    def _vo_listdir(entry):
        assert entry == 'vos:goliaths/test', 'wrong parameter'
        return ['a2021_08_17_19_30_01.fits.gz']
    vo_mock.return_value.listdir.side_effect = _vo_listdir
    vo_mock.return_value.isdir.return_value = False

    def _vo_get_node(uri, limit=None, force=False):
        assert (
            uri == 'vos:goliaths/test/a2021_08_17_19_30_01.fits.gz'
        ), f'wrong get node uri {uri}'
        test_start_time = (
            datetime.now(tz=dateutil.tz.UTC) - timedelta(minutes=5)
        )
        node = type('', (), {})()
        node.props = {
            'length': 42,
            'MD5': '1234',
            'lastmod': test_start_time.isoformat(),
        }
        return node
    vo_mock.return_value.get_node.side_effect = _vo_get_node

    caom_mock.return_value.data_client.info.side_effect = [
        None,
        FileInfo(id='ad:DAO/a2021_08_17_19_30_01.fits.gz'),
    ]
    caom_mock.return_value.metadata_client.read.side_effect = [
        None,
        SimpleObservation(
            'obs_id',
            'DAO',
            Algorithm(name='exposure'),
        ),
    ]

    def _transfer_get(src, dst):
        logging.error(src)
        logging.error(dst)
        assert (
                src == 'vos:goliaths/test/a2021_08_17_19_30_01.fits.gz'
        ), 'wrong source'
        assert (
                dst ==
                '/usr/src/app/integration_test/mock_test/data/execution/'
                'a2021_08_17_19_30_01/a2021_08_17_19_30_01.fits.gz'
        ), 'wrong dst'
        with open(dst, 'w') as f2:
            f2.write('test content')
    transfer_mock.return_value.get.side_effect = _transfer_get

    def _get_head(ignore):
        x = """SIMPLE  =                    T / Written by IDL:  Fri Oct  6 01:48:35 2017
BITPIX  =                  -32 / Bits per pixel
NAXIS   =                    2 / Number of dimensions
NAXIS1  =                 2048 /
NAXIS2  =                 2048 /
EXPTIME =                 1.23
NCOMBINE=                    1
DATATYPE= 'REDUC   '           /Data type, SCIENCE/CALIB/REJECT/FOCUS/TEST
END
"""
        delim = '\nEND'
        extensions = \
            [e + delim for e in x.split(delim) if e.strip()]
        headers = [fits.Header.fromstring(e, sep='\n') for e in extensions]
        return headers
    fits2caom2_mock.return_value.get_head.side_effect = _get_head

    def _info(uri):
        return FileInfo(
            id=uri,
            md5sum='abc',
            size=42,
        )
    fits2caom2_mock.return_value.info.side_effect = _info

    getcwd_orig = os.getcwd
    os.getcwd = Mock(return_value=TEST_EXEC_DIR)

    try:
        test_result = test_module._run_vo()
        assert test_result is not None, f'expect a result {test_input_name}'
        assert test_result == 0, f'wrong test result {test_input_name}'
        assert (
            caom_mock.return_value.data_client.put.called
        ), f'{test_input_name} put not called'
        caom_mock.return_value.data_client.put.assert_called_with(
            '/usr/src/app/integration_test/mock_test/data/execution/'
            'a2021_08_17_19_30_01',
            'ad:DAO/a2021_08_17_19_30_01.fits.gz',
            'raw',
        ), f'{test_input_name} wrong put args'
    finally:
        os.getcwd = getcwd_orig
        del sys.modules['composable']


@patch('caom2utils.fits2caom2.data_util.StorageClientWrapper')
@patch('cadcutils.net.ws.WsCapabilities.get_access_url')
@patch('caom2pipe.client_composable.ClientCollection')
def test_todo_local_move(
    caom_mock,
    access_mock,
    fits2caom2_mock,
    test_input_name,
):
    if 'MOVE' not in test_input_name:
        return
    test_input = INPUTS.get(test_input_name)
    _cleanup()

    new_dir = TEST_DATA_DIR / 'new'
    fail_dir = TEST_DATA_DIR / 'failure'
    success_dir = TEST_DATA_DIR / 'success'
    for entry in [new_dir, fail_dir, success_dir]:
        for listing in entry.iterdir():
            listing.unlink()

    shutil.copy(test_input.test_file, new_dir / '2460606o.fits.gz')
    access_mock.return_value = 'https://localhost'

    # make sure the working directory TEST_EXEC_DIR has the correct things
    # in it
    config_file_target = TEST_EXEC_DIR / 'config.yml'
    shutil.copy(test_input.config_file, config_file_target)
    cache_file_target = TEST_EXEC_DIR / 'cache.yml'
    shutil.copy(test_input.cache_file, cache_file_target)
    with open(TEST_EXEC_DIR / 'cadcproxy.pem', 'w') as f:
        f.write('test content')

    getcwd_orig = os.getcwd
    os.getcwd = Mock(return_value=TEST_EXEC_DIR)

    # import the module for execution
    sys.path.append(test_input.test_path)
    test_module = import_module('composable')

    caom_mock.return_value.data_client.info.side_effect = [
        None,
        FileInfo(
            id='ad:CFHT/2460606o.fits.gz',
            md5sum='3d29f0edd984065a044d1376a11c6f08',
        ),
    ]
    caom_mock.return_value.metadata_client.read.side_effect = [
        None,
        SimpleObservation(
            'obs_id',
            'CFHT',
            Algorithm(name='exposure'),
            instrument=Instrument(name='ESPaDOnS'),
        ),
    ]

    def _info(uri):
        assert uri == 'ad:CFHT/2460606o.fits.gz', 'wrong info uri'
        return FileInfo(
            id=uri,
            md5sum='abc',
            size=42,
        )
    fits2caom2_mock.return_value.info.side_effect = _info

    try:
        test_result = test_module._run_by_builder()
        assert test_result is not None, f'expect a result {test_input_name}'
        assert test_result == 0, f'wrong test result {test_input_name}'
        assert (
            caom_mock.return_value.data_client.put.called
        ), f'{test_input_name} put not called'
        caom_mock.return_value.data_client.put.assert_called_with(
            '/usr/src/app/integration_test/mock_test/data/test_files/new',
            'ad:CFHT/2460606o.fits.gz',
            'raw',
        ), f'{test_input_name} wrong put args'

        count = 0
        for entry in new_dir.iterdir():
            count += 1
        assert count == 0, 'wrong new dir content'
        for entry in success_dir.iterdir():
            count += 1
        assert count == 1, 'wrong success dir content'
        count = 0
        for entry in fail_dir.iterdir():
            logging.error(f'fail entry {entry}')
            count += 1
        assert count == 0, f'wrong fail dir content {count}'
    finally:
        os.getcwd = getcwd_orig
        del sys.modules['composable']


@patch('caom2utils.fits2caom2.get_external_headers')
@patch('cadctap.CadcTapClient')
@patch('caom2pipe.manage_composable.query_endpoint')
@patch('caom2pipe.manage_composable.http_get')
@patch('caom2pipe.astro_composable.get_vo_table_session')
@patch('caom2pipe.manage_composable.query_endpoint_session')
@patch('caom2utils.data_util.get_local_file_headers')
@patch('caom2pipe.client_composable.ClientCollection')
@patch('caom2utils.data_util.StorageClientWrapper')
def test_gem_state(
    data_mock,
    caom_mock,
    local_header_mock,
    json_mock,
    filter_mock,
    http_get_mock,
    endpoint_mock,
    tap_mock,
    external_header_mock,
    test_input_name,
):
    if 'GEM_STATE' not in test_input_name:
        return
    test_input = INPUTS.get(test_input_name)
    _cleanup()

    getcwd_orig = os.getcwd
    os.getcwd = Mock(return_value=TEST_EXEC_DIR)

    test_start_time, state_file_target = _setup(test_input)

    def _json_mock(url, ignore_session):
        response = Mock()
        response.close = Mock()
        fqn = test_input.input_dir / 'input.json'
        with open(fqn) as f:
            response.text = f.read()

        def x():
            return json.loads(response.text)
        response.json = x
        return response
    json_mock.side_effect = _json_mock

    def _endpoint_mock(ignore):
        assert (
            ignore.startswith(
                'https://archive.gemini.edu/jsonsummary/canonical/NotFail/'
                'notengineering/entrytimedaterange'
            )
        ), 'wrong url for incremental querying'
        return _json_mock(ignore, None)
    endpoint_mock.side_effect = _endpoint_mock

    def _filter_mock():
        from astropy.table import parse_single_table
        fqn = test_input.input_dir / 'filter.xml'
        content = parse_single_table(fqn)
        return content, None
    filter_mock.side_effect = _filter_mock

    caom_mock.return_value.metadata_client.read.side_effect = [
        None,
        SimpleObservation(
            'obs_id',
            'GEMINI',
            Algorithm(name='exposure'),
        ),
    ]

    def _tap_query(
        ignore_query,
        output_file,
        data_only=True,
        response_format='csv',
    ):
        output_file.write(
            'observationID,instrument_name\n'
            'GS-CAL20191214-1-029,F2\n',
        )
    # caom_mock.return_value.query_client.query.side_effect = _tap_query
    tap_mock.return_value.query.side_effect = _tap_query

    def _local_header(ignore):
        x = """SIMPLE  =                    T / Written by IDL:  Fri Oct  6 01:48:35 2017
BITPIX  =                  -32 / Bits per pixel
NAXIS   =                    2 / Number of dimensions
NAXIS1  =                   14 /
NAXIS2  =                   24 /
INSTRUME= 'F2'
DATALAB = 'GS-CAL20191214-1-029
END
"""
        delim = '\nEND'
        extensions = \
            [e + delim for e in x.split(delim) if e.strip()]
        headers = [fits.Header.fromstring(e, sep='\n') for e in extensions]
        return headers
    local_header_mock.side_effect = _local_header
    external_header_mock.side_effect = _local_header

    def _info(uri):
        return FileInfo(
            id=uri,
            md5sum='abc',
            size=42,
        )
    data_mock.return_value.info.side_effect = _info

    # import the module for execution
    sys.path.append(test_input.test_path)
    test_module = import_module('composable')

    try:
        test_result = test_module._run_state()
        assert test_result is not None, f'expect a result {test_input_name}'
        assert test_result == 0, f'wrong test result {test_input_name}'

        # was state updated?
        post_state = mc.State(state_file_target.as_posix())
        assert (
                post_state.get_bookmark(test_input.bookmark) > test_start_time
        ), f'state not updated {test_input_name}'
        assert (
            caom_mock.return_value.data_client.put.called
        ), f'{test_input_name} put not called'
        caom_mock.return_value.data_client.put.assert_called_with(
            '/usr/src/app/integration_test/mock_test/data/execution/'
            'GS-CAL20191214-1-029',
            'gemini:GEMINI/S20191214S0301.fits',
        ), f'{test_input_name} wrong put args'
        assert http_get_mock.called, 'expect http get call'
        http_get_mock.assert_called_with(
            'https://archive.gemini.edu/file/S20191214S0301.fits',
            '/usr/src/app/integration_test/mock_test/data/execution/'
            'GS-CAL20191214-1-029/S20191214S0301.fits',
        ), 'wrong http get args'
    except Exception as e:
        logging.error(traceback.format_exc())
        raise e
    finally:
        os.getcwd = getcwd_orig
        del sys.modules['composable']


@patch('cadctap.CadcTapClient')
@patch('caom2utils.fits2caom2.data_util.StorageClientWrapper')
@patch('cadcutils.net.ws.WsCapabilities.get_access_url')
@patch('caom2pipe.client_composable.ClientCollection')
def test_gem_todo_local(
    caom_mock,
    access_mock,
    fits2caom2_mock,
    tap_mock,
    test_input_name,
):
    if 'GEM_TODO_LOCAL' not in test_input_name:
        return
    test_input = INPUTS.get(test_input_name)
    _cleanup()

    shutil.copy(
        test_input.test_file, TEST_DATA_DIR / 'S20191214S0301.fits'
    )
    access_mock.return_value = 'https://localhost'
    _setup(test_input)

    getcwd_orig = os.getcwd
    os.getcwd = Mock(return_value=TEST_EXEC_DIR)

    # import the module for execution
    sys.path.append(test_input.test_path)
    test_module = import_module('composable')

    caom_mock.return_value.data_client.info.side_effect = [
        None,
        FileInfo(
            id='gemini:GEMINI/S20191214S0301.fits',
            md5sum='3d29f0edd984065a044d1376a11c6f08',
        ),
    ]
    caom_mock.return_value.metadata_client.read.side_effect = [
        None,
        SimpleObservation(
            'obs_id',
            'GEMINI',
            Algorithm(name='exposure'),
        ),
    ]

    def _info(uri):
        assert (
                uri == 'gemini:GEMINI/S20191214S0301.fits'
        ), 'wrong info uri'
        return FileInfo(
            id=uri,
            md5sum='abc',
            size=42,
        )
    fits2caom2_mock.return_value.info.side_effect = _info

    def _tap_query(
        ignore_query,
        output_file,
        data_only=True,
        response_format='csv',
    ):
        output_file.write(
            'observationID,instrument_name\n'
            'GS-CAL20191214-1-029,F2\n',
        )
    # caom_mock.return_value.query_client.query.side_effect = _tap_query
    tap_mock.return_value.query.side_effect = _tap_query

    try:
        test_result = test_module._run()
        assert test_result is not None, f'expect a result {test_input_name}'
        assert test_result == 0, f'wrong test result {test_input_name}'
        # Gemini local should not be checking archive.gemini.edu for a
        # newer version of the file
        assert not caom_mock.return_value.data_client.put.called, 'no put'
    finally:
        os.getcwd = getcwd_orig
        del sys.modules['composable']


@patch('caom2utils.fits2caom2.get_external_headers')
@patch('cadctap.CadcTapClient')
@patch('caom2pipe.manage_composable.http_get')
@patch('caom2pipe.astro_composable.get_vo_table_session')
@patch('caom2pipe.manage_composable.query_endpoint_session')
@patch('caom2pipe.client_composable.ClientCollection')
@patch('caom2utils.data_util.StorageClientWrapper')
def test_gem_todo(
    data_mock,
    caom_mock,
    json_mock,
    filter_mock,
    http_get_mock,
    tap_mock,
    external_header_mock,
    test_input_name,
):
    if 'GEM_TODO' != test_input_name:
        return
    test_input = INPUTS.get(test_input_name)
    _cleanup()

    getcwd_orig = os.getcwd
    os.getcwd = Mock(return_value=TEST_EXEC_DIR)

    _setup(test_input)

    todo_fqn = TEST_EXEC_DIR / 'todo.txt'
    with open(todo_fqn, 'w') as f1:
        f1.write('S20191214S0301.fits\n')

    def _json_mock(url, ignore_session):
        response = Mock()
        response.close = Mock()
        fqn = test_input.input_dir / 'input.json'
        with open(fqn) as f:
            response.text = f.read()

        def x():
            return json.loads(response.text)
        response.json = x
        return response
    json_mock.side_effect = _json_mock

    def _filter_mock():
        from astropy.table import parse_single_table
        fqn = test_input.input_dir / 'filter.xml'
        content = parse_single_table(fqn)
        return content, None
    filter_mock.side_effect = _filter_mock

    caom_mock.return_value.metadata_client.read.side_effect = [
        None,
        SimpleObservation(
            'obs_id',
            'GEMINI',
            Algorithm(name='exposure'),
        ),
    ]

    def _tap_query(
        ignore_query,
        output_file,
        data_only=True,
        response_format='csv',
    ):
        output_file.write(
            'observationID,instrument_name\n'
            'GS-CAL20191214-1-029,F2\n',
        )
    # caom_mock.return_value.query_client.query.side_effect = _tap_query
    tap_mock.return_value.query.side_effect = _tap_query

    def _get_mock(ignore, uri):
        if uri == 'gemini:GEMINI/S20191214S0301.jpg':
            raise exceptions.UnexpectedException('')
    caom_mock.return_value.data_client.get.side_effect = _get_mock

    def _http_get_mock(ignore_url, fqn):
        if (
            ignore_url !=
            'https://archive.gemini.edu/file/S20191214S0301.fits' and
            ignore_url !=
            'https://archive.gemini.edu/preview/S20191214S0301.fits'
        ):
            assert False, f'bad http get mock url {ignore_url}'
        for ext in ['fits', 'jpg']:
            test_src_fqn = test_input.input_dir / f'S20191214S0301.{ext}'
            shutil.copy(test_src_fqn, fqn)
    http_get_mock.side_effect = _http_get_mock

    def _external_header(ignore_url):
        assert (
            ignore_url ==
            'https://archive.gemini.edu/fullheader/S20191214S0301.fits'
        ), 'wrong file header url'
        fqn = test_input.input_dir / 'S20191214S0301.fits'
        return caom2utils.data_util.get_local_file_headers(fqn.as_posix())
    external_header_mock.side_effect = _external_header

    def _info(uri):
        return FileInfo(
            id=uri,
            md5sum='abc',
            size=42,
        )
    data_mock.return_value.info.side_effect = _info

    # import the module for execution
    sys.path.append(test_input.test_path)
    test_module = import_module('composable')

    try:
        test_result = test_module._run()
        assert test_result is not None, f'expect a result {test_input_name}'
        assert test_result == 0, f'wrong test result {test_input_name}'
        assert (
            caom_mock.return_value.data_client.put.called
        ), f'{test_input_name} put not called'
        assert (
            caom_mock.return_value.data_client.put.call_count == 3
        ), 'wrong put call count'
        put_calls = [
            call(
                '/usr/src/app/integration_test/mock_test/data/execution/'
                'GS-CAL20191214-1-029',
                'gemini:GEMINI/S20191214S0301.jpg',
            ),
            call(
                '/usr/src/app/integration_test/mock_test/data/execution/'
                'GS-CAL20191214-1-029',
                'cadc:GEMINI/S20191214S0301_th.jpg',
            ),
            call(
                '/usr/src/app/integration_test/mock_test/data/execution/'
                'GS-CAL20191214-1-029',
                'gemini:GEMINI/S20191214S0301.fits',
            ),
        ]
        caom_mock.return_value.data_client.put.assert_has_calls(
            put_calls
        ), f'{test_input_name} wrong put args'

        assert http_get_mock.called, 'expect http get call'
        assert http_get_mock.call_count == 2, 'wrong http get call count'
        http_get_calls = [
            call(
                'https://archive.gemini.edu/preview/S20191214S0301.fits',
                '/usr/src/app/integration_test/mock_test/data/execution/'
                'GS-CAL20191214-1-029/S20191214S0301.jpg',
            ),
            call(
                'https://archive.gemini.edu/file/S20191214S0301.fits',
                '/usr/src/app/integration_test/mock_test/data/execution/'
                'GS-CAL20191214-1-029/S20191214S0301.fits',
            ),
        ]
        http_get_mock.assert_has_calls(http_get_calls), 'wrong http get args'
    except Exception as e:
        logging.error(traceback.format_exc())
        raise e
    finally:
        os.getcwd = getcwd_orig
        del sys.modules['composable']


@patch('caom2utils.fits2caom2.data_util.StorageClientWrapper')
@patch('cadcutils.net.ws.WsCapabilities.get_access_url')
@patch('caom2pipe.client_composable.ClientCollection')
def test_todo_local_common(
    caom_mock,
    access_mock,
    fits2caom2_mock,
    test_input_name,
):
    if test_input_name not in ['OMM_TODO_LOCAL', 'NEOSSAT_TODO_LOCAL']:
        return
    test_input = INPUTS.get(test_input_name)
    _cleanup()
    _setup(test_input, local=True)

    access_mock.return_value = 'https://localhost'

    getcwd_orig = os.getcwd
    os.getcwd = Mock(return_value=TEST_EXEC_DIR)

    # import the module for execution
    sys.path.append(test_input.test_path)
    test_module = import_module('composable')

    caom_mock.return_value.data_client.info.side_effect = [
        None,
        FileInfo(
            id=test_input.test_uri,
            md5sum='3d29f0edd984065a044d1376a11c6f08',
        ),
    ]
    caom_mock.return_value.metadata_client.read.side_effect = [
        None,
        SimpleObservation(
            'obs_id', test_input.collection, Algorithm(name='exposure'),
        ),
    ]

    def _info(uri):
        assert (
                uri == test_input.test_uri
        ), 'wrong info uri'
        return FileInfo(
            id=uri,
            md5sum='abc',
            size=42,
        )
    fits2caom2_mock.return_value.info.side_effect = _info

    try:
        test_result = test_module._run()
        assert test_result is not None, f'expect a result {test_input_name}'
        assert test_result == 0, f'wrong test result {test_input_name}'
        assert (
            caom_mock.return_value.data_client.put.called
        ), f'{test_input_name} put not called'
        caom_mock.return_value.data_client.put.assert_called_with(
            '/usr/src/app/integration_test/mock_test/data/test_files',
            test_input.test_uri,
            None,
        ), f'{test_input_name} wrong put args'
    finally:
        os.getcwd = getcwd_orig


def _cleanup():
    # make sure the working directory TEXT_EXEC_DIR has nothing in it
    for d in [TEST_EXEC_DIR, TEST_DATA_DIR]:
        for child in d.iterdir():
            if child == TEST_EXEC_DIR or child == TEST_DATA_DIR:
                continue
            if child.is_dir():
                for child_2 in child.iterdir():
                    child_2.unlink()
                child.rmdir()
            else:
                child.unlink()


def _setup(test_input, local=False):
    # make sure the working directory TEST_EXEC_DIR has the correct things
    # in it
    if test_input.config_file is not None:
        config_file_target = TEST_EXEC_DIR / 'config.yml'
        shutil.copy(test_input.config_file, config_file_target)

    test_start_time = None
    state_file_target = None
    if test_input.state_file is not None:
        state_file_target = TEST_EXEC_DIR / 'state.yml'
        shutil.copy(test_input.state_file, state_file_target)
        # make the state file won't take decades to execute
        test_start_time = datetime.now(
            tz=dateutil.tz.UTC,
        ) - timedelta(minutes=5)
        state = mc.State(state_file_target.as_posix())
        state.save_state(test_input.bookmark, test_start_time)

    if test_input.cache_file is not None:
        cache_file_target = TEST_EXEC_DIR / 'cache.yml'
        shutil.copy(test_input.cache_file, cache_file_target)

    with open(TEST_EXEC_DIR / 'cadcproxy.pem', 'w') as f:
        f.write('test content')

    if test_input.test_file is not None and local:
        shutil.copy(
            test_input.test_file, TEST_DATA_DIR / test_input.test_file.name
        )

    return test_start_time, state_file_target
