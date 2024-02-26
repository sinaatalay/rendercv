import os

from babel.support import Translations

class T(object):
    instance = None
    translations = None
    language = None

    def __new__(cls):
        if cls.instance is None:
            cls.instance = super(T, cls).__new__(cls)
        return cls.instance

    # custom initialize function to set up singleton class
    def initialize(self, language: str):
        self.translations = Translations.load(os.path.join(os.path.dirname(__file__), "locale"), [language])
        self.language = language

    def gettext(self, string: str):
        return self.translations.gettext(string)


# define a shorthand that Babel can parse when using `extract'
_ = T().gettext
