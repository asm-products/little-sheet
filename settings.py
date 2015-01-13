import os

for k, v in os.environ.items():
    globals()[k] = v

DEBUG = True if os.getenv('DEBUG') else False
