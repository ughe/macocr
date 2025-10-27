from setuptools import setup
from setuptools.command.build_py import build_py
import subprocess
import shutil
import os

class BuildSwift(build_py):
    def run(self):
        # Build Swift binary from source
        subprocess.check_call(['swift', 'build', '-c', 'release'])

        # Copy binary to package
        bin_dir = os.path.join(self.build_lib, 'macocr_py', 'bin')
        os.makedirs(bin_dir, exist_ok=True)
        shutil.copy('.build/release/macocr', bin_dir)

        # Continue normal build
        super().run()

setup(
    name='macocr',
    version='0.1.0',
    packages=['macocr_py'],
    cmdclass={'build_py': BuildSwift},
    url='https://github.com/ughe/macocr',
    description='macOS OCR using Vision framework',
)
