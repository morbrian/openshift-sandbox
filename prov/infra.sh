#!/bin/bash

export HOST_LIST="${MASTER01_HOST} ${NODE01_HOST} ${NODE02_HOST}"

sudo -i -u${OCP_USER} git clone https://github.com/openshift/openshift-ansible.git

cat <<EOF > push-ssh-id.sh
#!/bin/bash
ssh-keygen -t rsa -b 4096 -C ${OCP_USER}@${INFRA01_HOST}
for host in ${HOST_LIST}; do
    ssh-copy-id -i .ssh/id_rsa.pub \$host;
done
EOF
chmod +x push-ssh-id.sh
chown ${OCP_USER} push-ssh-id.sh
mv push-ssh-id.sh /home/${OCP_USER}



