
include:
  - python.27.virtualenv
  - nginx

pypi-mirror:
  user.present:
    - home: /opt/bandersnatch

/opt/bandersnatch:
  file.directory:
    - user: pypi-mirror
    - group: pypi-mirror
    - mode: 750
    - makedirs: True
    - recurse:
      - user
      - group
    - require:
      - user: pypi-mirror
  virtualenv.managed:
    - venv_bin: virtualenv-2.7
    - python: python2.7
    - system_site_packages: False
    - user: pypi-mirror
    - require:
      - file: /opt/bandersnatch
      - user: pypi-mirror
      - pip: virtualenv-2.7

bandersnatch:
  pip.installed:
    - name: bandersnatch == 1.0.5
    - bin_env: /opt/bandersnatch
    - require:
      - virtualenv: /opt/bandersnatch

{% for mirror, config in salt['pillar.get']('bandersnatch').iteritems() %}

/usr/share/www/mirror/{{ mirror }}/index.html:
  file.managed:
    - makedirs: True
    - source: salt://pypi-mirror/config/index.html.jinja
    - template: jinja
    - context:
      source_url: {{ config.get('mirror', {}).get('master', 'https://pypi.python.org') }}

/data/{{ mirror }}-mirror:
  file.directory:
    - user: pypi-mirror
    - group: pypi-mirror
    - mode: 755
    - makedirs: True
    - require:
      - user: pypi-mirror

/var/log/nginx/{{ mirror }}-mirror:
  file.directory:
    - user: root
    - group: root
    - makedirs: True

/etc/nginx/conf.d/{{ mirror }}-mirror.conf:
  file.managed:
    - source: salt://pypi-mirror/config/bandersnatch.nginx.conf
    - template: jinja
    - context:
      mirror: {{ mirror }}
      server_names: {{ " ".join(config.get('server_names')) }}
    - user: root
    - group: root
    - mode: 640
    - makedirs: True
    - require:
      - file: /var/log/nginx/{{ mirror }}-mirror

/etc/logrotate.d/{{ mirror }}-mirror:
  file.managed:
    - source: salt://pypi-mirror/config/bandersnatch.logrotate.conf
    - template: jinja
    - context:
      mirror: {{ mirror }}
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

/etc/bandersnatch:
  file.directory

/etc/bandersnatch/{{ mirror }}-mirror.conf:
  file.managed:
    - source: salt://pypi-mirror/config/bandersnatch.conf.jinja
    - template: jinja
    - context:
      directory: {{ config.get('mirror', {}).get('directory', '/data/pypi') }}
      master: {{ config.get('mirror', {}).get('master', 'https://pypi.python.org') }}
      timeout: {{ config.get('mirror', {}).get('timeout', '10') }}
      workers: {{ config.get('mirror', {}).get('workers', '3') }}
      stop_on_error: {{ config.get('mirror', {}).get('stop-on-error', 'false') }}
      delete_packages: {{ config.get('mirror', {}).get('delete-packages', 'true') }}
      access_log_pattern: {{ config.get('statistics', {}).get('access-log-pattern', '/var/log/nginx/pypi-mirror/access*.log') }}
    - require:
      - file: /etc/bandersnatch

{% if 'develop' in grains['roles'] %}
{% if not salt['file.directory_exists']('/data/' + mirror + '-mirror/web') %}
bandersnatch_short_sync:
  cmd.run:
    - name: '( /opt/bandersnatch/bin/bandersnatch -c /etc/bandersnatch/{{ mirror }}-mirror.conf mirror ) & sleep 30; kill $!'
    - cwd: /opt/bandersnatch
    - user: pypi-mirror
    - require:
      - file: /etc/bandersnatch/{{ mirror }}-mirror.conf
      - virtualenv: /opt/bandersnatch
{% endif %}
{% endif %}

/etc/cron.d/{{ mirror }}-mirror:
  file.managed:
    - source: salt://pypi-mirror/config/crontab.jinja
    - template: jinja
    - context:
      mirror: {{ mirror }}
    - require:
      - file: /etc/bandersnatch/{{ mirror }}-mirror.conf
      - virtualenv: /opt/bandersnatch

{% endfor %}
