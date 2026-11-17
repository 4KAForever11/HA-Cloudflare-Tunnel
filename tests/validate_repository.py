"""无需 Docker 守护进程即可校验加载项与发布元数据。"""

import re
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
for path in ROOT.rglob('*.yaml'):
    yaml.safe_load(path.read_text(encoding='utf-8'))
addon = yaml.safe_load((ROOT / 'cloudflare_tunnel/config.yaml').read_text())
build = yaml.safe_load((ROOT / 'cloudflare_tunnel/build.yaml').read_text())
assert set(addon['arch']) == set(build['build_from']) == {'amd64', 'aarch64'}
assert addon['schema']['tunnel_token'] == 'password'
assert addon['options']['tunnel_token'] == ''
assert set(addon['options']) == set(addon['schema'])
assert not any(addon.get(key) for key in ('host_network', 'privileged', 'docker_api', 'hassio_api', 'ports'))
assert 'restart' not in addon
assert 'image' not in addon
for key, value in build['args'].items():
    if key.startswith('CLOUDFLARED_SHA256_'):
        assert re.fullmatch(r'[0-9a-f]{64}', value), key
for name in ('README.md', 'README.en.md'):
    contents = (ROOT / name).read_text(encoding='utf-8')
    assert 'OWNER' not in contents
    for target in re.findall(r'\]\(([^)#]+)', contents):
        if '://' not in target:
            assert (ROOT / target).exists(), target
for name in ('en.yaml', 'zh-Hans.yaml'):
    labels = yaml.safe_load((ROOT / 'cloudflare_tunnel/translations' / name).read_text(encoding='utf-8'))
    assert set(labels['configuration']) == set(addon['schema'])
print('PASS: YAML, architecture, image, translations and documentation links')
