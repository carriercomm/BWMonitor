#!/usr/bin/env perl
# Testing Tkx, for a better look
# Odd, 2013-08-31 00:10:31

package BWM_GUI_Tkx;

use strict;
use warnings;

# Themeable TK
use Tkx;
use FindBin;
use Data::Dumper;

use lib "$FindBin::Bin/../lib";
use BWMonitor::Cmd;
use BWMonitor::Client;
use BWMonitor::Logger;

our $VERSION = $BWMonitor::Cmd::VERSION;

# references to all GUI widgets/elements and strings/labels
my $g = {
   str => {
      win => { main => "BWMonitor Client GUI v$VERSION" },
      lf  => {
         conn => 'Connection',
         data => 'Data',
         dir  => 'Directions',
         opts => 'Options',
         out  => 'Output',
         exec => 'Execute',
      },
      lbl => {
         host    => 'Hostname / IP:',
         port    => 'Port:',
         s_data  => 'Data size (bytes):',
         s_chunk => 'Chunk size (bytes):',
         int     => 'Interval (seconds):',

      },
      txt => {
         host => '192.168.13.73',
         #out  => '',
      },
      spn => {
         port    => BWMonitor::Cmd::PORT,
         s_data  => BWMonitor::Cmd::S_DATA,
         s_chunk => BWMonitor::Cmd::S_BUF,
         rep     => 1,
         int     => 0,
      },
      chk => {
         up   => 'Upload',
         down => 'Download',
         inf  => 'Infinite',
         rep  => 'Repeat:',
      },
      btn => {
         start => 'Start',
         stop  => 'Stop',
         clear => 'Clear',
         exit  => 'Exit',
      },
   }
};

# create object
sub _c {
   my $category = shift;
   my $key      = shift;
   my $obj      = shift;

   # save ref in global hash
   $g->{$category}{$key} = $obj;
   return $obj;
}

# place obj in grid
sub _g {
   my $obj = shift;
   my $row = shift;
   my $col = shift;
   my $stc = shift;

   $obj->g_grid(-row => $row, -column => $col, -sticky => $stc);
   $obj->g_grid_configure(-padx => 3, -pady => 3);
   return $obj;
}

sub _lf {
   my $parent = shift;
   my $text   = shift;
   return $parent->new_ttk__labelframe(-text => $text, -labelanchor => 'nw', -relief => 'groove');
}

sub _log {
   my $fmt = shift;
   my $msg;
   if (scalar(@_) > 0) {
      $msg = sprintf($fmt, @_);
   }
   else {
      $msg = $fmt;
   }
   $g->{txt}{out}->insert('end', $msg);
}

sub init_gui {
   my $mw = $g->{w} = Tkx::widget->new(".");

   $mw->g_wm_title($g->{str}{win}{main});
   $mw->g_grid_columnconfigure(0, -weight => 1);
   $mw->g_grid_rowconfigure(0, -weight => 1);
   my $mf = $g->{mf} = $mw->new_ttk__frame(-padding => "3 3 3 3");    #, -width => 640, -height => 480);
   _g($mf, 0, 0, 'nwse');
   $mf->configure(-borderwidth => 2, -relief => 'groove');
   $mf->g_grid_columnconfigure(0, -weight => 1);

   #my $lbl_status = _g(_c('lbl', 'status', $mw->new_ttk__label(-text => 'Gris', -anchor => 'w')), 1, 0, 'we');
   #my $sg = _g(_c('size', 'grip', $mw->new_ttk__sizegrip()), 1, 1, 'se');

   my $lf_conn = _g(_c('lf', 'conn', _lf($mf, $g->{str}{lf}{conn})), 0, 0, 'we');
   my $lbl_host = _g(_c('lbl', 'host', $lf_conn->new_ttk__label(-textvariable => \$g->{str}{lbl}{host})), 0, 0, 'w');
   my $txt_host = _g(_c('txt', 'host', $lf_conn->new_ttk__entry(-textvariable => \$g->{str}{txt}{host})), 0, 1, 'we');
   my $lbl_port = _g(_c('lbl', 'port', $lf_conn->new_ttk__label(-textvariable => \$g->{str}{lbl}{port})), 0, 3, 'w');
   my $spn_port =
     _g(_c('spn', 'port', $lf_conn->new_ttk__spinbox(-textvariable => \$g->{str}{spn}{port}, -width => 5)), 0, 4, 'w');
   $lf_conn->g_grid_columnconfigure(1, -weight => 1);

   my $lf_data = _g(_c('lf', 'data', _lf($mf, $g->{str}{lf}{data})), 1, 0, 'we');
   my $lbl_data_size = _g(
      _c('lbl', 'data_size', 
         $lf_data->new_ttk__label(
            -textvariable => \$g->{str}{lbl}{s_data}
         )
      ), 
      0, 0, 'w'
   );
   my $spn_data_size = _g(
      _c('spn',
         'data_size',
         $lf_data->new_ttk__spinbox(
            -textvariable => \$g->{str}{spn}{s_data},
            -width        => 7
         )
      ),
      0, 1, 'w'
   );
   my $lbl_chunk_size = _g(
      _c('lbl', 'chunk_size', 
         $lf_data->new_ttk__label(
            -textvariable => \$g->{str}{lbl}{s_chunk}
         )
      ), 
      0, 2, 'e'
   );
   my $spn_chunk_size = _g(
      _c('spn', 'chunk_size',
         $lf_data->new_ttk__spinbox(
            -textvariable => \$g->{str}{spn}{s_chunk},
            -width        => 7
         )
      ),
      0, 3, 'w'
   );
   $lf_data->g_grid_columnconfigure(2, -weight => 1);

   my $lf_dir = _g(_c('lf', 'dir', _lf($mf, $g->{str}{lf}{dir})), 2, 0, 'we');
   my $chk_up = _g(_c('chk', 'up', $lf_dir->new_ttk__checkbutton(-textvariable => \$g->{str}{chk}{up})), 0, 0, 'w');
   my $chk_down =
     _g(_c('chk', 'down', $lf_dir->new_ttk__checkbutton(-textvariable => \$g->{str}{chk}{down})), 0, 1, 'w');

   my $lf_opts = _g(_c('lf', 'opts', _lf($mf, $g->{str}{lf}{opts})), 3, 0, 'we');
   my $chk_inf = _g(_c('chk', 'inf', $lf_opts->new_ttk__checkbutton(-textvariable => \$g->{str}{chk}{inf})), 0, 0, 'w');
   my $chk_rep = _g(_c('chk', 'rep', $lf_opts->new_ttk__checkbutton(-textvariable => \$g->{str}{chk}{rep})), 0, 1, 'w');
   my $spn_rep =
     _g(_c('spn', 'rep', $lf_opts->new_ttk__spinbox(-textvariable => \$g->{str}{spn}{rep}, -width => 4)), 0, 2, 'w');
   my $lbl_int = _g(_c('lbl', 'int', $lf_opts->new_ttk__label(-textvariable => \$g->{str}{lbl}{int})), 0, 3, 'e');
   my $spn_int =
     _g(_c('spn', 'int', $lf_opts->new_ttk__spinbox(-textvariable => \$g->{str}{spn}{int}, -width => 4)), 0, 4, 'w');
   $lf_opts->g_grid_columnconfigure(3, -weight => 1);

   my $lf_out = _g(_c('lf', 'out', _lf($mf, $g->{str}{lf}{out})), 4, 0, 'nwse');
   my $txt_out = _g(_c('txt', 'out', $lf_out->new_tk__text(-width => 80, -height => 20)), 0, 0, 'nwse');
   my $scr_out =
     _g(_c('scr', 'out_y', $lf_out->new_ttk__scrollbar(-command => [ $txt_out, 'yview' ], -orient => 'vertical')),
      0, 1, 'ns');
   $txt_out->configure(-yscrollcommand => [ $scr_out, 'set' ]);
   $lf_out->g_grid_columnconfigure(0, -weight => 1);
   $lf_out->g_grid_rowconfigure(0, -weight => 1);
   $mf->g_grid_rowconfigure(4, -weight => 1);

   my $lf_exec = _g(_c('lf', 'exec', _lf($mf, $g->{str}{lf}{exec})), 5, 0, 'we');
   my $btn_start = _g(
      _c('btn', 'start',
         $lf_exec->new_ttk__button(
            -textvariable => \$g->{str}{btn}{start},
            -command      => sub {
               _log(Dumper($g));
            }
         )
      ),
      0, 0, 'w'
   );
   my $btn_stop = _g(
      _c('btn', 'stop',
         $lf_exec->new_ttk__button(
            -textvariable => \$g->{str}{btn}{stop},
            -command      => sub {
            }
         )
      ),
      0, 1, 'w'
   );
   my $btn_clear = _g(
      _c('btn', 'clear',
         $lf_exec->new_ttk__button(
            -textvariable => \$g->{str}{btn}{clear},
            -command      => sub {
               $txt_out->delete('1.0', 'end');
            }
         )
      ),
      0, 2, 'w'
   );
   my $btn_exit = _g(
      _c('btn', 'exit',
         $lf_exec->new_ttk__button(
            -textvariable => \$g->{str}{btn}{exit},
            -command      => sub {
               exit;
            }
         )
      ),
      0, 3, 'e'
   );
   $lf_exec->g_grid_columnconfigure(3, -weight => 1);

   # ...
   Tkx::MainLoop();
}

__PACKAGE__->init_gui;

__END__

