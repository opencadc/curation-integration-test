from caom2.diff import get_differences
from caom2pipe import manage_composable as mc


def compare(ex, act):
    expected = mc.read_obs_from_file(ex)
    actual = mc.read_obs_from_file(act)
    result = get_differences(expected, actual, 'Observation')
    if result:
        import logging
        logging.error(' '.join(ii for ii in result))


if __name__ == "__main__":
    import sys
    arg1 = sys.argv[1]
    arg2 = sys.argv[2]
    compare(arg1, arg2)
