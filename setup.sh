#!/bin/bash
done_message () {
    if [ $? == 0 ]; then
        echo " done."
        if [ "x$1" != "x" ]; then
            echo $1;
        fi
    else
        echo " failed.  See setup.log file for error messages." $2
        echo "    Please check INSTALL file for items that should be installed by a package manager"
        exit 1
    fi
}


if [ "$#" -ne "1" ] ; then
  echo "Please provide an installation path  such as /opt/ICGC"
  exit 0;
fi

INST_PATH=$1;

# get current directory
INIT_DIR=`pwd`

# cleanup inst_path
mkdir -p $INST_PATH/bin
cd $INST_PATH
INST_PATH=`pwd`
cd $INIT_DIR

# make sure that build is self contained
unset PERL5LIB;
ARCHNAME=`perl -e 'use Config; print $Config{archname};'`;
PERLROOT=$INST_PATH/lib/perl5
PERLARCH=$PERLROOT/$ARCHNAME
export PERL5LIB="$PERLROOT:$PERLARCH";

#create a location to build dependencies
SETUP_DIR=$INIT_DIR/install_tmp
mkdir -p $SETUP_DIR

# re-initialise log file
echo > $INIT_DIR/setup.log;

# log information about this system
(
    echo '============== System information ====';
    set -x;
    lsb_release -a;
    uname -a;
    sw_vers;
    system_profiler;
    grep MemTotal /proc/meminfo;
    set +x;
    echo; echo;
) >>$INIT_DIR/setup.log 2>&1;

perlmods=( "Module::Build" "File::ShareDir" "File::ShareDir::Install" "Const::Fast" )

for i in "${perlmods[@]}";
do
  echo -n "Installing build prerequisite $i..."
  if( perl -I$INST_PATH/lib/perl5 -Mlocal::lib=$INST_PATH -M$i -e 1 >& /dev/null); then
      echo $i already installed.
  else
    (
      set +e;
      $INIT_DIR/bin/cpanm  --notest -v -l $INST_PATH $i;
      set -e;
      $INIT_DIR/bin/cpanm  --notest -v -l $INST_PATH $i;
      echo; echo;
    ) >>$INIT_DIR/setup.log 2>&1;
    done_message "" "Failed during installation of $i.";
  fi
done

# figure out the upgrade path
COMPILE=`echo 'nothing' | perl -I lib -MPCAP -ne 'print PCAP::upgrade_path($_);'`
if [ -e "$INST_PATH/lib/perl5/PCAP.pm" ]; then
  COMPILE=`perl -I $INST_PATH/lib/perl5 -MPCAP -e 'print PCAP->VERSION,"\n";' | perl -I lib -MPCAP -ne 'print PCAP::upgrade_path($_);'`
fi

cd $SETUP_DIR;
if [[ ",$COMPILE," == *,bwa,* ]] ; then
  echo -n "Building BWA ..."
  if [ -e $SETUP_DIR/bwa.success ]; then
    echo -n " previously installed ..."
  else
    (
      set -e;
      if hash curl 2>/dev/null; then
        curl -sS -o 0.7.7.tar.gz -L https://github.com/lh3/bwa/archive/0.7.7.tar.gz;
      else
        wget -nv -O 0.7.7.tar.gz https://github.com/lh3/bwa/archive/0.7.7.tar.gz;
      fi
      tar zxf 0.7.7.tar.gz;
      cd $SETUP_DIR/bwa-0.7.7;
      make -j3;
      cp bwa $INST_PATH/bin/.
      cd $SETUP_DIR;
      rm -rf $SETUP_DIR/bwa-0.7.7;
      rm -f 0.7.7.tar.gz;
      touch $SETUP_DIR/bwa.success;
      set +e;
    ) >>$INIT_DIR/setup.log 2>&1;
  fi
  done_message "" "Failed to build bwa.";
else
  echo "BWA - No change between PCAP versions"
fi

if [[ ",$COMPILE," == *,biobambam,* ]] ; then
  echo -n "Building snappy ..."
  if [ -e $SETUP_DIR/snappy.success ]; then
    echo -n " previously installed ..."
  else
    (
      set -e;
      if hash curl 2>/dev/null; then
        curl -sS -o snappy-1.1.1.tar.gz -L https://snappy.googlecode.com/files/snappy-1.1.1.tar.gz;
      else
        wget -nv -O snappy-1.1.1.tar.gz https://snappy.googlecode.com/files/snappy-1.1.1.tar.gz;
      fi
      tar zxf snappy-1.1.1.tar.gz;
      cd $SETUP_DIR/snappy-1.1.1;
      ./configure --prefix=$INST_PATH;
      make -j3;
      make -j3 install;
      cd $SETUP_DIR;
      rm -rf $SETUP_DIR/snappy-1.1.1;
      rm -f snappy-1.1.1.tar.gz;
      touch $SETUP_DIR/snappy.success;
      set +e;
    ) >>$INIT_DIR/setup.log 2>&1;
  fi
  done_message "" "Failed to build snappy.";

  echo -n "Building io_lib ..."
  if [ -e $SETUP_DIR/io_lib.success ]; then
    echo -n " previously installed ... "
  else
    (
    set -e;
      if hash curl 2>/dev/null; then
        curl -sS -o io_lib-1.13.4.tar.gz -L http://downloads.sourceforge.net/project/staden/io_lib/1.13.4/io_lib-1.13.4.tar.gz;
      else
        wget -nv -O io_lib-1.13.4.tar.gz http://downloads.sourceforge.net/project/staden/io_lib/1.13.4/io_lib-1.13.4.tar.gz;
      fi
      tar zxf io_lib-1.13.4.tar.gz;
      cd $SETUP_DIR/io_lib-1.13.4;
      ./configure --prefix=$INST_PATH;
      make -j3;
      make -j3 install;
      cd $SETUP_DIR;
      rm -rf $SETUP_DIR/io_lib-1.13.4;
      rm -f io_lib-1.13.4.tar.gz;
      touch $SETUP_DIR/io_lib.success;
      set +e;
    ) >>$INIT_DIR/setup.log 2>&1;
  fi
  done_message "" "Failed to build io_lib.";

  echo -n "Building libmaus ..."
  if [ -e $SETUP_DIR/libmaus.success ]; then
    echo -n " previously installed ..."
  else
    (
      set -e;
      LIBMAUS_VERSION=0.0.108-release-20140319092837
      if hash curl 2>/dev/null; then
        curl -sS -o libmaus-$LIBMAUS_VERSION.tar.gz -L https://github.com/gt1/libmaus/archive/$LIBMAUS_VERSION.tar.gz;
      else
        wget -nv -O libmaus-$LIBMAUS_VERSION.tar.gz https://github.com/gt1/libmaus/archive/$LIBMAUS_VERSION.tar.gz;
      fi
      tar zxf libmaus-$LIBMAUS_VERSION.tar.gz;
      cd $SETUP_DIR/libmaus-$LIBMAUS_VERSION;
      autoreconf -i -f;
      ./configure --prefix=$INST_PATH --with-snappy=$INST_PATH --with-io_lib=$INST_PATH
      make -j3;
      make -j3 install;
      cd $SETUP_DIR;
      rm -rf $SETUP_DIR/libmaus-$LIBMAUS_VERSION;
      rm -f libmaus-$LIBMAUS_VERSION.tar.gz;
      touch $SETUP_DIR/libmaus.success;
      set +e;
    ) >>$INIT_DIR/setup.log 2>&1;
  fi
  done_message "" "Failed to build libmaus.";

  echo -n "Building biobambam ..."
  if [ -e $SETUP_DIR/biobambam.success ]; then
    echo -n " previously installed ..."
  else
    (
      set -e;
      BIOBAMBAM_VERSION=0.0.129-release-20140319092922
      if hash curl 2>/dev/null; then
        curl -sS -o $BIOBAMBAM_VERSION.tar.gz -L https://github.com/gt1/biobambam/archive/$BIOBAMBAM_VERSION.tar.gz;
      else
        wget -nv -O $BIOBAMBAM_VERSION.tar.gz https://github.com/gt1/biobambam/archive/$BIOBAMBAM_VERSION.tar.gz;
      fi
      tar zxf $BIOBAMBAM_VERSION.tar.gz;
      cd $SETUP_DIR/biobambam-$BIOBAMBAM_VERSION;
      autoreconf -i -f;
      ./configure --with-libmaus=$INST_PATH --prefix=$INST_PATH
      make -j3;
      make -j3 install;
      cd $SETUP_DIR;
      rm -rf $SETUP_DIR/biobambam-$BIOBAMBAM_VERSION;
      rm -f $BIOBAMBAM_VERSION.tar.gz;
      touch $SETUP_DIR/biobambam.success;
      set +e;
    ) >>$INIT_DIR/setup.log 2>&1;
  fi
  done_message "" "Failed to build biobambam.";
else
  echo "biobambam - No change between PCAP versions"
fi

cd $INIT_DIR;

if [[ ",$COMPILE," == *,biobambam,* ]] ; then
echo -n "Building samtools ..."
if [ -e $SETUP_DIR/samtools.success ]; then
  echo -n " previously installed ...";
else
  cd $SETUP_DIR
  if( [ "x$SAMTOOLS" == "x" ] ); then
    (
      set -e;
      set -x;
      if [ ! -e samtools-0.1.19 ]; then
        if hash curl 2>/dev/null; then
            curl -sS -L https://github.com/samtools/samtools/archive/0.1.19.tar.gz -o 0.1.19.tar.gz;
        else
            wget -nv -O 0.1.19.tar.gz https://github.com/samtools/samtools/archive/0.1.19.tar.gz;
        fi
        tar zxf 0.1.19.tar.gz;
        rm -f 0.1.19.tar.gz;
        perl -i -pe 's/^CFLAGS=\s*/CFLAGS=-fPIC / unless /\b-fPIC\b/' samtools-0.1.19/Makefile;
      fi;
      make -C samtools-0.1.19 -j3;
      cp samtools-0.1.19/samtools $INST_PATH/bin/.;
      touch $SETUP_DIR/samtools.success;
      set +e;
      set +x;
    )>>$INIT_DIR/setup.log 2>&1;
  fi
fi
done_message "" "Failed to build samtools.";
else
  echo "samtools - No change between PCAP versions"
fi

export SAMTOOLS="$SETUP_DIR/samtools-0.1.19";

#add bin path for PCAP install tests
export PATH="$INST_PATH/bin:$PATH";

cd $INIT_DIR;

echo -n "Installing Perl prerequisites ..."
if ! ( perl -MExtUtils::MakeMaker -e 1 >/dev/null 2>&1); then
    echo;
    echo "WARNING: Your Perl installation does not seem to include a complete set of core modules.  Attempting to cope with this, but if installation fails please make sure that at least ExtUtils::MakeMaker is installed.  For most users, the best way to do this is to use your system's package manager: apt, yum, fink, homebrew, or similar.";
fi;
(
  set -x;
  $INIT_DIR/bin/cpanm -v --notest -l $INST_PATH/ --installdeps . < /dev/null;
  $INIT_DIR/bin/cpanm -v --notest -l $INST_PATH/ --installdeps . < /dev/null;
  set -e;
  $INIT_DIR/bin/cpanm -v --notest -l $INST_PATH/ --installdeps . < /dev/null;
  set +x;
) >>$INIT_DIR/setup.log 2>&1;
done_message "" "Failed during installation of core dependencies.";

echo -n "Installing PCAP ..."
(
  cd $INIT_DIR;
  set -e;
  perl Makefile.PL INSTALL_BASE=$INST_PATH;
  make;
  make test;
  make install;
) >>$INIT_DIR/setup.log 2>&1;
done_message "" "PCAP install failed.";

# cleanup all junk
rm -rf $SETUP_DIR;

echo;
echo;
echo "Please add the following to beginning of path:";
echo "  $INST_PATH/bin";
echo "Please add the following to beginning of PERL5LIB:";
echo "  $PERLROOT";
echo "  $PERLARCH";
echo;

exit 0;
