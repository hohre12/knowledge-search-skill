#!/usr/bin/env python3
"""
Knowledge Search - Vector-based semantic search for your knowledge base
"""

from setuptools import setup, find_packages
from pathlib import Path

# Read requirements
requirements = []
requirements_path = Path(__file__).parent / "requirements.txt"
if requirements_path.exists():
    with open(requirements_path) as f:
        requirements = [line.strip() for line in f if line.strip() and not line.startswith('#')]

# Read README
readme_path = Path(__file__).parent / "README.md"
long_description = ""
if readme_path.exists():
    with open(readme_path, encoding='utf-8') as f:
        long_description = f.read()

setup(
    name='knowledge-search-skill',
    version='1.0.0',
    description='Vector-based semantic search for your knowledge base (Obsidian, Apple Notes, etc.)',
    long_description=long_description,
    long_description_content_type='text/markdown',
    author='Jaewon Bae',
    author_email='hohre12@users.noreply.github.com',
    url='https://github.com/hohre12/knowledge-search-skill',
    packages=find_packages(),
    package_data={
        '': ['*.md', '*.json.example', '*.sql'],
    },
    include_package_data=True,
    install_requires=requirements,
    python_requires='>=3.10',
    entry_points={
        'console_scripts': [
            'ks=src.cli:cli',
        ],
    },
    classifiers=[
        'Development Status :: 4 - Beta',
        'Intended Audience :: Developers',
        'Topic :: Software Development :: Libraries :: Python Modules',
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.10',
        'Programming Language :: Python :: 3.11',
        'Programming Language :: Python :: 3.12',
    ],
    keywords='vector-search rag knowledge-base semantic-search embeddings',
)
