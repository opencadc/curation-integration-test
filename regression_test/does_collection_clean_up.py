import sys

# identify in one location the collections that have
# cleanup_files_when_storing in their configuration
# because it changes, at the least, the 
# docker run commands

def question(coll):
    result = False
    if coll.lower() in ['dao', 'cfht']:
        print('1')
        result = True
    else:
        print('0')
    return result


if __name__ == '__main__':
    collection = sys.argv[1]
    question(collection)
