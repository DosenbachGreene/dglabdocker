#!/bin/bash

# Setup xauth file location; Remove if exists 
echo "Setting up X11 forwarding for User: ${USER}"
XTEMP=/tmp/.docker.xauth.${USER}
if [ -e ${XTEMP} ] ; then
	rm -f ${XTEMP}
fi

# Create new xauth file
touch ${XTEMP}

# modify xauth file
xauth nlist $(hostname)/unix:${DISPLAY:1:1} | sed -e 's/^..../ffff/' | xauth -f ${XTEMP} nmerge -

# Run docker
echo "Running Image..."
docker run -it --rm \
	-e DISPLAY=${DISPLAY} \
	-e QT_X11_NO_MITSHM=1 \
	-v ${XTEMP}:${XTEMP} \
	-e XAUTHORITY=${XTEMP} \
	-v /tmp/.X11-unix:/tmp/.X11-unix \
	--net=host \
	vanandrew/dglabimg
