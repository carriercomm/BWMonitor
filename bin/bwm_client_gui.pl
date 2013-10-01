#!/usr/bin/env perl
# Testing Tkx, for a better look
# Odd, 2013-08-31 00:10:31

package BWM_GUI_Tkx;

use strict;
use warnings;

use Tkx;

my $g = {};

# create object
sub _c {
   my $category = shift;
   my $key      = shift;
   my $obj      = shift;

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

sub init_gui {
   my $mw = $g->{w} = Tkx::widget->new(".");

   $mw->g_wm_title("BWMonitor Client GUI");
   $mw->g_grid_columnconfigure(0, -weight => 1);
   $mw->g_grid_rowconfigure(0, -weight => 1);
   my $mf = $g->{mf} = $mw->new_ttk__frame(-padding => "3 3 3 3");    #, -width => 640, -height => 480);
   _g($mf, 0, 0, 'news');
   $mf->configure(-borderwidth => 2, -relief => 'groove');
   $mf->g_grid_columnconfigure(0, -weight => 1);

   #my $lbl_status = _g(_c('lbl', 'status', $mw->new_ttk__label(-text => 'Gris', -anchor => 'w')), 1, 0, 'we');
   #my $sg = _g(_c('size', 'grip', $mw->new_ttk__sizegrip()), 1, 1, 'se');

   my $lf_conn =
     _g(_c('lf', 'conn', $mf->new_ttk__labelframe(-text => 'Connection', -labelanchor => 'nw', -relief => 'groove')),
      0, 0, 'we');
   my $lbl_host = _g(_c('lbl', 'host', $lf_conn->new_ttk__label(-text => "Hostname / IP:")), 0, 0, 'w');
   my $txt_host = _g(_c('txt', 'host', $lf_conn->new_ttk__entry), 0, 1, 'we');
   my $lbl_port = _g(_c('lbl', 'port', $lf_conn->new_ttk__label(-text => 'Port:')), 0, 3, 'w');
   my $spn_port = _g(_c('spn', 'port', $lf_conn->new_ttk__spinbox(-width => 5)), 0, 4, 'w');
   $lf_conn->g_grid_columnconfigure(1, -weight => 1);

   my $lf_data =
     _g(_c('lf', 'data', $mf->new_ttk__labelframe(-text => 'Data', -labelanchor => 'nw', -relief => 'groove')),
      1, 0, 'we');
   my $lbl_data_size = _g(_c('lbl', 'data_size', $lf_data->new_ttk__label(-text => 'Data size (bytes):')), 0, 0, 'w');
   my $spn_data_size = _g(_c('spn', 'data_size', $lf_data->new_ttk__spinbox(-width => 7)), 0, 1, 'w');
   my $lbl_chunk_size =
     _g(_c('lbl', 'chunk_size', $lf_data->new_ttk__label(-text => 'Chunk size (bytes):')), 0, 2, 'e');
   my $spn_chunk_size = _g(_c('spn', 'chunk_size', $lf_data->new_ttk__spinbox(-width => 7)), 0, 3, 'w');
   $lf_data->g_grid_columnconfigure(2, -weight => 1);

   my $lf_dir = _g(_c('lf', 'dir', _lf($mf, 'Directions')), 2, 0, 'we');
   my $chk_up   = _g(_c('chk', 'up',   $lf_dir->new_ttk__checkbutton(-text => 'Upload')),   0, 0, 'w');
   my $chk_down = _g(_c('chk', 'down', $lf_dir->new_ttk__checkbutton(-text => 'Download')), 0, 1, 'w');

   my $lf_opts = _g(_c('lf', 'opts', _lf($mf, 'Options')), 3, 0, 'we');
   my $chk_inf = _g(_c('chk', 'inf', $lf_opts->new_ttk__checkbutton(-text => 'Infinite')), 0, 0, 'w');
   my $chk_rep = _g(_c('chk', 'rep', $lf_opts->new_ttk__checkbutton(-text => 'Repeat:')),  0, 1, 'w');
   my $spn_rep = _g(_c('spn', 'rep', $lf_opts->new_ttk__spinbox(-width => 4)), 0, 2, 'w');
   my $lbl_int = _g(_c('lbl', 'int', $lf_opts->new_ttk__label(-text => 'Interval (seconds):')), 0, 3, 'e');
   my $spn_int = _g(_c('spn', 'int', $lf_opts->new_ttk__spinbox(-width => 4)), 0, 4, 'w');
   $lf_opts->g_grid_columnconfigure(3, -weight => 1);

   my $lf_out = _g(_c('lf', 'out', _lf($mf, 'Output')), 4, 0, 'nwse');
   my $txt_out = _g(_c('txt', 'out', $lf_out->new_tk__text(-width => 80, -height => 20)), 0, 0, 'nwse');
   my $scr_out =
     _g(_c('scr', 'out_y', $lf_out->new_ttk__scrollbar(-command => [ $txt_out, 'yview' ], -orient => 'vertical')),
      0, 1, 'ns');
   $txt_out->configure(-yscrollcommand => [ $scr_out, 'set' ]);
   $lf_out->g_grid_columnconfigure(0, -weight => 1);
   $lf_out->g_grid_rowconfigure(0, -weight => 1);
   $mf->g_grid_rowconfigure(4, -weight => 1);

   my $lf_exec = _g(_c('lf', 'exec', _lf($mf, 'Execute')), 5, 0, 'we');
   my $btn_start = _g(_c('btn', 'start', $lf_exec->new_ttk__button(-text => 'Start', -command => sub { })), 0, 0, 'w');
   my $btn_stop  = _g(_c('btn', 'stop',  $lf_exec->new_ttk__button(-text => 'Stop',  -command => sub { })), 0, 1, 'w');
   my $btn_exit =
     _g(_c('btn', 'exit', $lf_exec->new_ttk__button(-text => 'Exit', -command => sub { exit; })), 0, 2, 'e');
   $lf_exec->g_grid_columnconfigure(2, -weight => 1);



   # ...
   Tkx::MainLoop();
}

__PACKAGE__->init_gui;

__END__

