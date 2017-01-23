import configparser
import re

class Config(object):
    def __init__(self, **validations):
        self.validations = validations
        self.parser = None
    def __call__(self, paths):
        parser = configparser.ConfigParser()
        parser.read(paths)
        keys = parser.sections()
        sections = dict()
        required = set([name for name, val in self.validations.items() if 'required' in val and val['required']])
        for section in keys:
            options = {key: conf['default']() for key, conf in self.validations.items() if 'default' in conf}
            sections[section] = options
            
            present_ops = set(parser.options(section))
            required_not_present = required - present_ops
            if len(required_not_present) != 0:
                raise Exception("These keys are required: {}".format(required_not_present))

            for key, val in parser.items(section):
                if key not in self.validations:
                    raise Exception("Unknown key {}".format(key))
                try:
                    if 'validate' not in self.validations[key]:
                        self.validations[key]['validate'] = str
                    options[key] = self.validations[key]['validate'](val)
                except Exception as e:
                    raise Exception("Could not validate {}: {}".format(val, e))
        return ParsedConfig(keys, sections)
    @classmethod
    def write(self, path, dictionary):
        with open(path, 'w') as configfile:
            parser = configparser.ConfigParser()
            parser.read_dict(dictionary)
            parser.write(configfile)

class ParsedConfig(object):
    def __init__(self, keys, sections):
        self.sections, self.keys = sections, keys
    def __str__(self):
        return str(self.sections)
    def __getitem__(self, section):
        return self.sections[section]
    def items(self):
        return self.sections.items()
    def write(self, path):
        with open(path, 'w') as configfile:
            parser = configparser.ConfigParser()
            parser.read_dict(self.sections)
            parser.write(configfile)

def opt(**options):
    return options
def url(string):
    if re.match('([\w-]+://?|www[.])[^\s()<>]+(?:\([\w\d]+\)|([^[:punct:]\s]|/))', string):
        return string
    else:
        raise Exception("Not a URL")
def sem_ver(string):
    elems = tuple(int(i) for i in string.split('.'))
    if len(elems) != 3:
       raise Exception("SemVer must have 2 elements")
    return elems
