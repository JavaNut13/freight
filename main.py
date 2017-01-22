from config import Config, opt, url, sem_ver
import sys


Options = Config(
    repo_url=opt(
        required=True,
        validate=url
    ),
    container_name=opt(
        required=True
    ),
    version=opt(
        required=True,
        validate=sem_ver
    )
)

def main(args):
    print(args)
    ops = Options(args[1])
    print(ops)
    ops['sample']['repo_url']


if __name__ == '__main__':
    main(sys.argv)
