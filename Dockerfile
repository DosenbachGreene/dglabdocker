# Dosenbach and Greene Lab Docker Image
FROM debian:stretch
MAINTAINER Andrew Van <vanandrew@wustl.edu>

### Install 4dfp tools ###
WORKDIR /opt
ENV NILSRC=/opt/4dfp_tools/NILSRC RELEASE=/opt/4dfp_tools/RELEASE REFDIR=/opt/4dfp_tools/REFDIR
ENV PATH=${PATH}:${RELEASE}:/opt/4dfp_tools/scripts
RUN apt-get update && apt-get install -y wget dirmngr tcsh curl make gfortran git unzip && \
    git clone https://github.com/DosenbachGreene/4dfp_tools.git && mkdir -p ${RELEASE} && \
    cd ${NILSRC} && git checkout dcm4dfpmod && \
    chmod u+x make_nil-tools.csh && ./make_nil-tools.csh && cd /opt/4dfp_tools && rm -r ${NILSRC} && \
    mkdir -p REFDIR && cd ${REFDIR} && \
	curl -L -o REFDIR.zip https://wustl.box.com/shared/static/q0sv1ugg3b3xmksz8z4w3k546nzleygp.zip && \
	unzip REFDIR.zip && rm REFDIR.zip && apt-get remove -y make gfortran && apt-get autoremove -y

### Install stuff from neurodebian: connectome-workbench, fsleyes, and afni ###
RUN wget -O- http://neuro.debian.net/lists/stretch.us-ca.full | tee /etc/apt/sources.list.d/neurodebian.sources.list && \
    apt-get update && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -yq --allow-unauthenticated connectome-workbench fsleyes afni && \
    ln -s $(which FSLeyes) /usr/bin/fsleyes
ENV PATH=${PATH}:/usr/lib/afni/bin

### Compile and install fsl from source ###
WORKDIR /opt
ENV FSLDIR=/opt/fsl
RUN curl -O https://fsl.fmrib.ox.ac.uk/fsldownloads/fsl-5.0.10-sources.tar.gz && \
	tar zxf fsl-5.0.10-sources.tar.gz && \
	rm fsl-5.0.10-sources.tar.gz && \
    apt-get install -y build-essential libexpat1-dev libx11-dev libgl1-mesa-dev libglu1-mesa-dev zlib1g-dev && \
    sed -i '52iFSLCONFDIR=$FSLDIR/config' ${FSLDIR}/etc/fslconf/fsl.sh && \
	sed -i '53iFSLMACHTYPE=`$FSLDIR/etc/fslconf/fslmachtype.sh`' ${FSLDIR}/etc/fslconf/fsl.sh && \
	sed -i '57iexport FSLCONFDIR FSLMACHTYPE' ${FSLDIR}/etc/fslconf/fsl.sh && \
	sed -i "13s/ mist-clean\";/\";/" ${FSLDIR}/build && \
    . ${FSLDIR}/etc/fslconf/fsl.sh && \
	cp -r ${FSLDIR}/config/linux_64-gcc4.8 ${FSLDIR}/config/${FSLMACHTYPE} && \
    sed -i '22s/c++/c++ -std=c++03/' ${FSLDIR}/config/${FSLMACHTYPE}/systemvars.mk && \
	sed -i "3s/LIBXMLXX_CFLAGS=\"/LIBXMLXX_CFLAGS=\"-std=c++03 /" ${FSLDIR}/extras/src/libxml++-2.34.0/fslconfigure
    cd ${FSLDIR} && ./build && \
    rm -r ${FSLDIR}/LICENCE ${FSLDIR}/README ${FSLDIR}/build ${FSLDIR}/build.log ${FSLDIR}/config ${FSLDIR}/extras ${FSLDIR}/include ${FSLDIR}/lib ${FSLDIR}/refdoc ${FSLDIR}/src && \
    apt-get remove -y build-essential && apt-get autoremove -y
ENV FSLOUTPUTTYPE=NIFTI_GZ FSLMULTIFILEQUIT=TRUE FSLTCLSH=${FSLDIR}/bin/fsltclsh FSLWISH=${FSLDIR}/fslwish PATH=${PATH}:${FSLDIR}/bin

### Install caret from my box link ###
RUN curl -L -o caret.zip https://wustl.box.com/shared/static/957c23jc3md68bgxskg7vgncq43j2aej.zip && apt-get install -y unzip && \
    unzip caret.zip && rm caret.zip && apt-get remove -y unzip
ENV PATH=${PATH}:/opt/caret/bin_linux64

# Remove neurodebian source & install python3 and nibabel
RUN rm /etc/apt/sources.list.d/neurodebian.sources.list && apt-get update && apt-get install -y python3 python3-pip && \
    pip3 install nibabel numpy nipype

# Make directories to mount MATLAB; install Matlab dependencies
RUN apt-get update && apt-get install -y libpng12-dev libfreetype6-dev libblas-dev liblapack-dev gfortran build-essential && \
    mkdir -p /opt/MATLAB
ENV PATH=${PATH}:/opt/MATLAB/bin

# install freesurfer
RUN wget -qO- https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/6.0.1/freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.1.tar.gz | tar zxv --no-same-owner -C /opt \
    --exclude='freesurfer/trctrain' \
    --exclude='freesurfer/subjects/fsaverage_sym' \
    --exclude='freesurfer/subjects/fsaverage3' \
    --exclude='freesurfer/subjects/fsaverage4' \
    --exclude='freesurfer/subjects/fsaverage5' \
    --exclude='freesurfer/subjects/fsaverage6' \
    --exclude='freesurfer/subjects/cvs_avg35' \
    --exclude='freesurfer/subjects/cvs_avg35_inMNI152' \
    --exclude='freesurfer/subjects/bert' \
    --exclude='freesurfer/subjects/V1_average' \
    --exclude='freesurfer/average/mult-comp-cor' \
    --exclude='freesurfer/lib/cuda' \
    --exclude='freesurfer/lib/qt'

# Configure environment
ENV POSSUMDIR=${FSLDIR}
ENV OS=Linux
ENV FS_OVERRIDE=0
ENV FIX_VERTEX_AREA=
ENV SUBJECTS_DIR=/opt/freesurfer/subjects
ENV FSF_OUTPUT_FORMAT=nii.gz
ENV MNI_DIR=/opt/freesurfer/mni
ENV LOCAL_DIR=/opt/freesurfer/local
ENV FREESURFER_HOME=/opt/freesurfer
ENV FSFAST_HOME=/opt/freesurfer/fsfast
ENV MINC_BIN_DIR=/opt/freesurfer/mni/bin
ENV MINC_LIB_DIR=/opt/freesurfer/mni/lib
ENV MNI_DATAPATH=/opt/freesurfer/mni/data
ENV FMRI_ANALYSIS_DIR=/opt/freesurfer/fsfast
ENV PERL5LIB=/opt/freesurfer/mni/lib/perl5/5.8.5
ENV MNI_PERL5LIB=/opt/freesurfer/mni/lib/perl5/5.8.5
ENV PATH=${PATH}:/opt/freesurfer/bin:/opt/freesurfer/fsfast/bin:/opt/freesurfer/tktools:/opt/freesurfer/mni/bin

# Goto Root
WORKDIR /
