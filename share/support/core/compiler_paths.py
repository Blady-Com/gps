"""
Support file for libclang integration. In order to analyze files correctly with
libclang, we need to get the compiler's search paths.

This file implements a generic function that will spawn the compiler and get
back the search paths
"""
import GPS
import subprocess
import re

paths_cache = {}


def get_compiler_search_paths(project_name, language):
    logger = GPS.Logger("LIBCLANG.SEARCH_PATHS")

    # First find the driver.
    # Heuristic for finding the driver:
    #    A) we look for an explicitly set Compiler'Driver setting
    #    B) if this is not explicitely set, we use
    #         <target>gcc for C
    #         <target>c++ for C++

    ccs = {'c': 'gcc', 'c++': 'c++'}
    "map of languages -> compilers"

    # Put the language in lowercase
    language = language.lower()

    compiler = ''
    try:
        logger.log('Trying to get the Compiler.Driver attribute for the '
                   'project')
        compiler = GPS.Project(project_name).get_attribute_as_string(
            'driver', package='compiler', index=language
        )
    except Exception:
        logger.log(
            'No project {}, trying to determine the compiler in a project'
            'agnostic way'.format(project_name)
        )

    if not compiler:
        compiler = "-".join(filter(bool, [GPS.get_target(), ccs[language]]))

    logger.log('Compiler: {}'.format(compiler))

    # We use a tuple (compiler, language) for the cache, because it is possible
    # that the user defined the same driver for both C and C++. The cache needs
    # to be able to distinguish between the two
    ret = paths_cache.get((compiler, language), None)
    if ret:
        logger.log('Returning cached search paths: {}'.format(ret))
        return ret

    # Spawn the compiler, get the include paths
    try:
        logger.log('Spawning {} to find the search paths'.format(compiler))
        out = subprocess.check_output(
            "echo | {} -x {} -E -v -".format(compiler, language),
            shell=True, stderr=subprocess.STDOUT
        )
        m = re.findall(r'\> search starts here:(.*) ?End', out, re.DOTALL)[0]
        ret = map(str.strip, m.strip().splitlines())

    except Exception as e:
        import traceback
        logger.log('Spawning failed !')
        traceback.print_exc(e)
        ret = []

    logger.log('Returning {}'.format(ret))

    # NOTE: Since the spawning logic is *exactly* the same each time, we'll
    # cache the results *even when spawning failed*, so that we don't try to
    # spawn executables repeatedly
    paths_cache[(compiler, language)] = ret

    return ret

GPS.__get_compiler_search_paths = get_compiler_search_paths
