#!/usr/bin/env perl
# Testing GUI stuff
# Odd, 2013-08-30 14:55:26

package BWM_GUI;

use strict;
use warnings;

use Tk;
use Tk::LabFrame;
#use Tk::Pane;
#use Tk::HList;
#use Tk::Tree;
#use Tk::ItemStyle;

my $g = { 
   win => MainWindow->new(-title => "BWMonitor Client GUI"), 
};

sub initgui {
   #my ($dsize, $bsize, $port);
   my $dsize     = 1_048_57600;
   my $bsize     = 16384;
   my $port      = 3389;
   my $num_loops = 1;
   my $interval  = 5;
   my $d_up;
   my $d_down;
   my $rbt_loops;


   #$g->{win}->optionAdd('*BorderWidth' => 2);
   #$g->{win}->optionAdd('*Justify'     => 'left');
   #$g->{win}->optionAdd('*font'        => $g->{win}->fontCreate(-weight => 'normal', -size => 10));
   #$g->{win}->geometry("640x480");


   # connection
   $g->{frm}{conn} = $g->{win}->Frame->pack(-side => 'top', -fill => 'both');

   $g->{lf}{conn} = $g->{frm}{conn}->LabFrame(
      -label     => 'Connection',
      -labelside => 'acrosstop',
      -relief    => 'groove'
     )->pack(
        -side   => 'top',
        -fill   => 'both',
        -expand => 1,
   );

   $g->{lbl}{host} = $g->{lf}{conn}->Label(
      -text => 'Host/IP:'
   )->pack(
        -side => 'left',
        -fill => 'both'
   );
   $g->{txt}{host} = $g->{lf}{conn}->Entry(
   )->pack(
        -side   => 'left',
        -anchor => 'w',
        -fill   => 'both',
        -expand => 1
   );
   $g->{lbl}{port} = $g->{lf}{conn}->Label(
      -text => 'Port:'
   )->pack(
        -side => 'left',
        -fill => 'both'
   );
   $g->{spn}{port} = $g->{lf}{conn}->Spinbox(
      -textvariable => \$port,
      -from         => 1,
      -to           => 65535,
      -format       => '%2.0f',
      -width        => 5,
     )->pack(
        -side   => 'left',
        -anchor => 'w',
        -fill   => 'both'
   );


   # data
   $g->{frm}{data} = $g->{win}->Frame->pack(-side => 'top', -fill => 'both');

   $g->{lf}{data} = $g->{frm}{data}->LabFrame(
      -label     => 'Data',
      -labelside => 'acrosstop',
      -relief    => 'groove',
     )->pack(
        -side   => 'top',
        -fill   => 'both',
        -expand => 1,
   );

   $g->{lbl}{data_size} = $g->{lf}{data}->Label(
      -text => 'Data size (bytes):'
   )->pack(
        -side   => 'left',
        -fill   => 'both',
        -anchor => 'w',
        #-expand => 0,
   );
   $g->{spn}{data_size} = $g->{lf}{data}->Spinbox(
      -textvariable => \$dsize,
      -from         => 2,
      -to           => 1_048_57600,
      -format       => '%2.0f',
      -width        => 10,
   )->pack(
        -side   => 'left',
        -fill   => 'both',
        -anchor => 'w',
        #-expand => 0,
   );
   $g->{lbl}{buf_size} = $g->{lf}{data}->Label(
      -text => 'Chunk size (bytes):'
   )->pack(
        -side   => 'left',
        -fill   => 'both',
        -anchor => 'w',
        #-expand => 1,
   );
   $g->{spn}{buf_size} = $g->{lf}{data}->Spinbox(
      -textvariable => \$bsize,
      -from         => 1,
      -to           => 1_048_57600,
      -format       => '%2.0f',
      -width        => 7
   )->pack(
        -side   => 'left',
        -fill   => 'both',
        -anchor => 'w',
        #-expand => 0,
   );


   # Directions
   $g->{frm}{dir} = $g->{win}->Frame->pack(-side => 'top', -fill => 'both');

   $g->{lf}{dir} = $g->{frm}{dir}->LabFrame(
      -label     => 'Directions',
      -labelside => 'acrosstop',
      -relief    => 'groove',
     )->pack(
        -side   => 'top',
        -fill   => 'both',
        -expand => 1,
   );

   $g->{chk}{d_down} = $g->{lf}{dir}->Checkbutton(
      -text => 'Download', 
      -variable => \$d_down,
   )->pack(
      -side => 'left', 
      -fill => 'both',
   );
   $g->{chk}{d_up} = $g->{lf}{dir}->Checkbutton(
      -text => 'Upload', 
      -variable => \$d_up
   )->pack(
      -side => 'left', 
      -fill => 'both',
   );


   # Options
   $g->{frm}{opts} = $g->{win}->Frame->pack(-side => 'top', -fill => 'both');

   $g->{lf}{opts} = $g->{frm}{opts}->LabFrame(
      -label     => 'Options',
      -labelside => 'acrosstop',
      -relief    => 'groove',
     )->pack(
        -side   => 'top',
        -fill   => 'both',
        -expand => 1,
   );

   $g->{rbt}{inf} = $g->{lf}{opts}->Radiobutton(
      -text => 'Infinite',
      -variable => \$rbt_loops,
      -value => 2,
   )->pack(
      -side => 'left',
      -fill => 'both',
   );
   $g->{rbt}{loops} = $g->{lf}{opts}->Radiobutton(
      -text => 'Repeat',
      -variable => \$rbt_loops,
      -value => 1,
   )->pack(
      -side => 'left',
      -fill => 'both',
   );
   $g->{spn}{loops} = $g->{lf}{opts}->Spinbox(
      -textvariable => \$num_loops,
      -from         => 1,
      -to           => 65535,
      #-value => 1,
      -format       => '%2.0f',
      -width        => 7
   )->pack(
        -side   => 'left',
        -fill   => 'both',
        -anchor => 'w',
        #-expand => 0,
   );
   $g->{lbl}{interval} = $g->{lf}{opts}->Label(
      -text => 'Interval (seconds):'
   )->pack(
        -side   => 'left',
        -fill   => 'both',
        -anchor => 'w',
        #-expand => 1,
   );
   $g->{spn}{interval} = $g->{lf}{opts}->Spinbox(
      -textvariable => \$interval,
      -from         => 1,
      -to           => 65535,
      -format       => '%2.0f',
      -width        => 7
   )->pack(
        -side   => 'left',
        -fill   => 'both',
        -anchor => 'w',
        #-expand => 0,
   );


   # Output
   $g->{frm}{out}  = $g->{win}->Frame->pack(-side => 'top', -fill => 'both', -expand => 1);

   $g->{lf}{out} = $g->{frm}{out}->LabFrame(
      -label     => 'Output',
      -labelside => 'acrosstop',
      -relief    => 'groove',
     )->pack(
        -side   => 'top',
        -fill   => 'both',
        -expand => 1,
   );
   $g->{txt}{out} = $g->{lf}{out}->Scrolled(
      "Text", 
      -scrollbars => 'osoe',
   )->pack(
      -side => 'top',
      -fill => 'both',
      -expand => 1,
   );




   # Buttons
   $g->{frm}{bot}  = $g->{win}->Frame->pack(-side => 'top', -fill => 'both');

   $g->{lf}{bot} = $g->{frm}{bot}->LabFrame(
      -label     => 'Execute',
      -labelside => 'acrosstop',
      -relief    => 'groove',
     )->pack(
        -side   => 'top',
        -fill   => 'both',
        -expand => 1,
   );

   $g->{btn}{start} = $g->{lf}{bot}->Button(
      -text    => 'Start',
      #-command => [ $g->{win} => 'destroy' ]
     )->pack(
        -side   => 'left',
        -anchor => 'w'
   );
   $g->{btn}{stop} = $g->{lf}{bot}->Button(
      -text    => 'Stop',
      #-command => [ $g->{win} => 'destroy' ]
     )->pack(
        -side   => 'left',
        -anchor => 'w'
   );
   $g->{lf}{bot}->Label()->pack(-side => 'left', -fill => 'both', -expand => 1);
   $g->{btn}{exit} = $g->{lf}{bot}->Button(
      -text    => 'Exit',
      -command => [ $g->{win} => 'destroy' ]
     )->pack(
        -side   => 'left',
        -anchor => 'e'
   );



   MainLoop();
}

__PACKAGE__->initgui;

__END__
