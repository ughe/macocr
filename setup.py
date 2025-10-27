from setuptools import setup, Extension
from setuptools.command.build_ext import build_ext
import subprocess
import os

class SwiftBuild(build_ext):
    def run(self):
        subprocess.check_call(['swift', 'build', '-c', 'release'])
        os.makedirs('macocr_py/bin', exist_ok=True)
        subprocess.check_call([
            'cp', '.build/release/macocr', 'macocr_py/bin/'
        ])

setup(
    name='macocr',
    version='0.1.0',
    packages=['macocr_py'],
    package_data={'macocr_py': ['bin/macocr']},
    cmdclass={'build_ext': SwiftBuild},
    ext_modules=[Extension('macocr_py', sources=[])],
    url='https://github.com/ughe/macocr',
    description='macOS OCR using Vision framework',
)
