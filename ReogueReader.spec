# -*- mode: python ; coding: utf-8 -*-

import os

# Define the path to AutoItX3_x64.dll
dll_path = os.path.abspath('AutoItX3_x64.dll')  # Ensure AutoItX3_x64.dll is in the same folder as the .spec file

a = Analysis(
    ['RogueReader.py'],
    pathex=[],
	binaries=[(dll_path, 'autoit/lib')],  # Bundle the DLL into the autoit/lib subdirectory inside the dist folder
    datas=[],
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='RogueReader',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon='RogueReader.ico',  # Path to your icon file
)
