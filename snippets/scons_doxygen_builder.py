@memberOf(SConsEnvironment)
def Doxygen(self, config, **kw):
    inputs = [d for d in ["#doc", "#include", "#python", "#src"]
              if os.path.exists(SCons.Script.Entry(d).abspath)]
    defaults = {
        "inputs": inputs,
        "recursive": True,
        "patterns": ["*.h", "*.cc", "*.py", "*.dox"],
        "outputs": ["html", "xml"],
        "excludes": [],
        "includes": [],
        "useTags": [],
        "makeTag": None,
        "projectName": None,
        "projectNumber": None,
        "excludeSwig": True
        }
    for k in defaults:
        if kw.get(k) is None:
            kw[k] = defaults[k]
    builder = DoxygenBuilder(**kw)
    return builder(self, config)
