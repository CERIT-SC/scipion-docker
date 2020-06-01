#!/bin/bash
set -x

echo $USE_DISPLAY
export WEBPORT=590${USE_DISPLAY}
export DISPLAY=:${USE_DISPLAY}

echo $WEBPORT
echo $DISPLAY

# install all installed plugins
#/opt/scipion/scipion installp -p scipion-em-eman2 -j 12
#/opt/scipion/scipion installp -p scipion-em-xmipp -j 12
#/opt/scipion/scipion installb xmippBin_Debian -j 12

#/opt/scipion/scipion installp -p scipion-em-chimera -j 12
#/opt/scipion/scipion installp -p scipion-em-empiar -j 12
#/opt/scipion/scipion installp -p scipion-em-gctf -j 12
#/opt/scipion/scipion installp -p scipion-em-gautomatch -j 12
#/opt/scipion/scipion installp -p scipion-em-motioncorr -j 12
#/opt/scipion/scipion installp -p scipion-em-relion -j 12

mkdir /home/scipionuser/.vnc
echo $MYVNCPASSWORD
echo $MYVNCPASSWORD | vncpasswd -f > /home/scipionuser/.vnc/passwd
chmod 0600 /home/scipionuser/.vnc/passwd
/opt/websockify/run ${WEBPORT} --cert=/self.pem --ssl-only --web=/opt/noVNC --wrap-mode=ignore -- vncserver ${DISPLAY} -xstartup /tmp/xsession

