#!/usr/bin/perl

##########LICENCE##########
# PCAP - NGS reference implementations and helper code for the ICGC/TCGA Pan-Cancer Analysis Project
# Copyright (C) 2014 ICGC PanCancer Project
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not see:
#   http://www.gnu.org/licenses/gpl-2.0.html
##########LICENCE##########


use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share module => 'PCAP::SRA', 'share';

WriteMakefile(
  NAME          => 'PCAP',
  VERSION_FROM  => 'lib/PCAP.pm',
  EXE_FILES     => [qw( bin/bam_to_sra_sub.pl
                        bin/bwa_aln.pl
                        bin/bwa_mem.pl
                        bin/diff_bams.pl
                        bin/monitor.pl)],
  PREREQ_PM     => {
                     'IPC::System::Simple' => 1.25,
                     'Capture::Tiny' => 0.24,
                     'Const::Fast' => 0.014,
                     'Bio::DB::Sam' => 1.39,
                     'Bio::Perl' => 0, # can't specify as make manifest can't parse the version string
                                       # cpanmdb also doesn't have 1.6.923 indexed for some reason
                     'Try::Tiny' => 0.19,
                     'File::Which' => 0.05,
                     'List::Util' => 1.38,
                     'Proc::ProcessTable' => 0.50,
                     'Data::UUID' => 1.219,
                     'Test::Fatal' => 0.013,
                   }
);

package MY;
use File::ShareDir::Install qw( postamble );
