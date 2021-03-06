
pypi-deploy-pypi:
  name: pypi
  user: pypi
  group: pypi
  user_uid: 7000
  group_gid: 7000

  fastly_syslog_name: counterpypicdn
  path: /opt/pypi
  data_mount: /data/pypi
  data_device:
    type: glusterfs
    uri: 172.16.57.6:/pypi

  server_names:
    - pypi.python.org
    - pypi.a.ssl.fastly.net
  tls_port: 9000
  docs_port: 9010
  url: https://pypi.python.org

  statuspage_id: 2p66nmmycsj3
