from config import Config, opt, url, sem_ver
import sys, os, subprocess
import log

PWD = os.path.dirname(os.path.realpath(__file__))

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
    ),
    flags=opt(
        validate=str,
        default=lambda: ''
    )
)

CurrentVersions = Config(
    version=opt(
        required=True,
        validate=sem_ver
    )
)

def semver_str(tup):
    return '.'.join(str(t) for t in tup)

def cmd(command):
    log.info('>', command)
    os.system(command)
def cmd_output(commands):
    log.info('>', *commands)
    return subprocess.Popen(commands, stdout=subprocess.PIPE).communicate()[0]

def upgrade(app, config, old_version):
    version = semver_str(config['version'])
    old_ver_str = semver_str(old_version)
    image_name = config['image_name']
    log.info("Upgrading", app, "to version", config['version'])
    cmd('git clone {} /tmp/{}'.format(config['repo_url'], image_name))
    cmd('docker build -t {image}:{ver} /tmp/{image}'.format(
        image=image_name, ver=version))
    image_id = cmd_output(['docker', 'ps', '-fq', 'name={}'.format(image_name)])
    if len(image_id) == 0:
        log.info('no container running')
    else:
        cmd('docker stop {}'.format(' '.join(image_id.split('\n'))))
    cmd('docker run -d {image}:{ver}'.format(image=image_name, ver=version))
    
def get_current(path):
    log.info("Loading current values from", path)
    return {app: config['version'] for app, config in CurrentVersions(path).items()}

def main(args):
    log.init_global_log(level=log.Log.DEBUG)
    current = get_current(args[1])
    applications = args[2:]
    log.info("Getting config from", applications)
    ops = Options(applications)
    for app, config in ops.items():
        version = (0, 0, 0)
        if app in current:
            version = current[app]
        log.info('loading app:', app, 'current version:', semver_str(version))
        if version < config['version']:
            upgrade(app, config, version)
        else:
            log.info('version not changed')
        current[app] = config['version']

    Config.write(args[1], {app: {'version': semver_str(v)} for app, v in current.items()})


if __name__ == '__main__':
    main(sys.argv)
