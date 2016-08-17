# Static parameters
WORKSPACE=$PWD
BOX_PLAYBOOK=$WORKSPACE/mongo_setup.yml
BOX_NAME=lab21
BOX_ADDRESS=192.168.0.21  # .15 -- 16.04
BOX_USER=slavko
BOX_PWD=

# Register the new Prudentia box, provision it with the staging artifact and eventually unregisters the box
prudentia ssh <<EOF
unregister $BOX_NAME

register
$BOX_PLAYBOOK
$BOX_NAME
$BOX_ADDRESS
$BOX_USER
$BOX_PWD

verbose 4

set box_address $BOX_ADDRESS
provision $BOX_NAME

unregister $BOX_NAME
EOF
