from config import Config, opt, url, sem_ver
import sys
import log


Options = Config(
    repo_url=opt(
        required=True,
        validate=url
    ),
    image_name=opt(
        required=True
    ),
    version=opt(
        required=True,
        validate=sem_ver
    )
)

CurrentVersions = Config(
    version=opt(
        required=True,
        validate=sem_ver
    )
)

def semver_str(tup):
    return '.'.join([str(t) for t in tup])

def cmd(command):
    log.error(command)

def upgrade(app, config):
    version = semver_str(config['version'])
    log.info("Upgrading", app, "to version", config['version'])
    cmd('git clone {} /tmp/{}'.format(config['repo_url'], app))
    cmd('docker build -t {app}:{ver} /tmp/{app}'.format(
        app=app, ver=version))
    # TODO stop the container
    cmd('docker run -d {app}:{ver}'.format(app=app, ver=version))
    


def get_current(path):
    log.info("Loading current values from", path)
    return {app: config['version'] for app, config in CurrentVersions(path).items()}

def main(args):
    log.init_global_log(level=log.Log.DEBUG)
    config = args[1]
    current = get_current(config)
    applications = args[2:]
    log.info("Getting config from", applications)
    ops = Options(applications)
    # for each section in every file
    # check if the version is greater than the current version
    # if it is:
    #   clone repo to tmp location
    #   build new image with tag
    #   stop the old image
    #   start the new image
    #   log the change somewhere?
    for app, config in ops.items():
        log.info('loading app:', app)
        if app not in current:
            upgrade(app, config)
        elif current[app] < config['version']:
            upgrade(app, config)



if __name__ == '__main__':
    main(sys.argv)
