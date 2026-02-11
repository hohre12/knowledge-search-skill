from setuptools import setup, find_packages

setup(
    name='knowledge-search',
    version='0.1.0',
    description='Knowledge Search - Vector-based semantic search for your documents',
    author='OpenClaw Community',
    author_email='hello@openclaw.ai',
    packages=find_packages(),
    install_requires=[
        'supabase>=2.3.4',
        'openai>=1.12.0',
        'click>=8.1.7',
        'anthropic>=0.18.0',
        'tiktoken>=0.6.0',
    ],
    entry_points={
        'console_scripts': [
            'ks=src.cli:cli',
        ],
    },
    python_requires='>=3.11',
    classifiers=[
        'Development Status :: 3 - Alpha',
        'Intended Audience :: Developers',
        'Programming Language :: Python :: 3.11',
    ],
)
