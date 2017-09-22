# Dosenbach and Greene Lab Docker Image
FROM ubuntu:xenial
MAINTAINER Andrew Van <vanandrew@wustl.edu>

# Update and install sudo (needed on xenial)
RUN apt-get update
RUN apt-get install -y sudo

# Install tcsh,curl,make,gfortran for compiling 4dfp
RUN apt-get install -y tcsh
RUN apt-get install -y curl
RUN apt-get install -y make
RUN apt-get install -y gfortran

### Install 4dfp tools ###
WORKDIR /opt/4dfp
RUN curl -O ftp://imaging.wustl.edu/pub/raichlab/4dfp_tools/4dfp_release.txt
RUN mkdir NILSRC
RUN mkdir RELEASE
RUN mkdir REFDIR

ENV NILSRC /opt/4dfp/NILSRC
ENV REFDIR /opt/4dfp/REFDIR
ENV RELEASE /opt/4dfp/RELEASE
ENV PATH ${PATH}:${RELEASE}

# start with the source code
WORKDIR ${NILSRC}
RUN curl -O ftp://imaging.wustl.edu/pub/raichlab/4dfp_tools/nil-tools.tar
RUN tar xvf nil-tools.tar

# fix the few odd things having to do with compiling a new ubuntu system
RUN sed -i 's|(${OSTYPE}, linux)|(linux-gnu, linux-gnu)|g' */*.mak
RUN sed -i 's|chgrp program ${PROG}|#chgrp program ${PROG} # removed for ubuntu compilation|g' */*.mak
RUN sed -i 's|OBJECTS.*=.*nifti_4dfp.o 4dfp-format.o nifti-format.o split.o transform.o common-format.o parse_common.o|OBJECTS = nifti_4dfp.o -lm 4dfp-format.o -lm nifti-format.o -lm split.o -lm transform.o -lm common-format.o -lm parse_common.o -lm |g' nifti_4dfp/nifti_4dfp.mak
RUN sed -i 's|${TRX}/endianio.o ${TRX}/Getifh.o ${TRX}/rec.o ${IMGLIN}/t4_io.o|${TRX}/endianio.o -lm ${TRX}/Getifh.o -lm ${TRX}/rec.o -lm ${IMGLIN}/t4_io.o -lm|g' aff_conv/aff_conv.mak
RUN sed -i 's|${NII}/split.o ${NII}/transform.o ${NII}/4dfp-format.o ${NII}/nifti-format.o|${NII}/split.o -lm ${NII}/transform.o -lm ${NII}/4dfp-format.o -lm ${NII}/nifti-format.o -lm |g' aff_conv/aff_conv.mak

# inject JMK's edits to dcm_to_4dfp
RUN sed -i '442i# get newest dcm_to_4dfp.c' make_nil-tools.csh
RUN sed -i '443icurl -L -O https://wustl.box.com/shared/static/ubof8682r88nbkxb7b4b1fsvfy4q1vr3.c' make_nil-tools.csh
RUN sed -i '444imv ubof8682r88nbkxb7b4b1fsvfy4q1vr3.c dcm_to_4dfp.c' make_nil-tools.csh
RUN sed -i "s/wget ftp/curl -O ftp/" make_nil-tools.csh
RUN sed -i "s/wget --help/curl --help/" make_nil-tools.csh
RUN sed -i "s/wget/curl/g" make_nil-tools.csh

# begin the 4dfp tool code build ("make")
RUN chmod u+x make_nil-tools.csh
RUN ./make_nil-tools.csh

# grab the additional 4dfp supporting scripts
WORKDIR ${RELEASE}
RUN curl -O ftp://imaging.wustl.edu/pub/raichlab/4dfp_tools/4dfp_scripts.tar
RUN tar xvf 4dfp_scripts.tar

# grab the additional 4dfp supporting reference images and other files
WORKDIR ${REFDIR}
#RUN curl -O ftp://imaging.wustl.edu/pub/raichlab/4dfp_tools/refdir.tar
#RUN tar xvf refdir.tar

# clean-up
RUN apt-get remove -y make gfortran
RUN apt-get autoremove -y
RUN apt-get upgrade -y
RUN apt-get install -y libgfortran3
WORKDIR /
