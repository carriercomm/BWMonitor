#!/usr/bin/env perl
# Licence     : GPL
# Author      : Odd Eivind Ebbesen <odd@oddware.net>
# Date        : 2013-10-31 15:51:51
#
# Description :
# Main application frame/window.

use Modern::Perl;

package BWMonitor::GUI::Wx::MainFrame;

use Wx qw(:everything);

use BWMonitor::Cmd;
use BWMonitor::Client;
#use BWMonitor::Logger;

use base qw(Wx::Frame);

our $VERSION = $BWMonitor::Cmd::VERSION;

my %_str = (
   w_title        => 'BWMonitor GUI',
   sb_conn        => 'Connection',
   sb_data        => 'Data',
   sb_dir         => 'Directions',
   sb_opts        => 'Options',
   sb_out         => 'Output',
   sb_exec        => 'Execute',
   lbl_host       => 'Hostname / IP:',
   lbl_port       => 'Port:',
   lbl_data_size  => 'Data size (bytes):',
   lbl_chunk_size => 'Chunk size (bytes):',
   lbl_interval   => 'Interval (seconds):',
   chk_up         => 'Upload',
   chk_down       => 'Download',
   chk_inf        => 'Infinite',
   chk_rep        => 'Repeat',
   btn_start      => 'Start',
   btn_stop       => 'Stop',
   btn_clear      => 'Clear',
   btn_exit       => 'Exit',
);

sub new {
   my $class  = shift;
   my $wtitle = shift || $_str{w_title};
   my $parent = shift;
   my $self   = $class->SUPER::new($parent, wxID_ANY, $wtitle, wxDefaultPosition, wxDefaultSize);

   $self->{v} = {
      host       => '192.168.13.73',
      port       => BWMonitor::Cmd::PORT,
      data_size  => BWMonitor::Cmd::S_DATA,
      chunk_size => BWMonitor::Cmd::S_BUF,
      repeat     => 1,
      interval   => 0,
   };
   # same options for all spinners, so save typing by having an array
   my @spn_opts = (wxDefaultPosition, wxDefaultSize, wxSP_ARROW_KEYS | wxALIGN_RIGHT);

   ### Containers
   my $p = $self->{g}{pnl_main} = Wx::Panel->new($self, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL);
   $self->{g}{bs_frame} = Wx::BoxSizer->new(wxVERTICAL);
   $self->{g}{bs_panel} = Wx::BoxSizer->new(wxVERTICAL);
   $self->{g}{sbs_conn} = Wx::StaticBoxSizer->new(Wx::StaticBox->new($p, wxID_ANY, $_str{sb_conn}), wxHORIZONTAL);
   $self->{g}{sbs_data} = Wx::StaticBoxSizer->new(Wx::StaticBox->new($p, wxID_ANY, $_str{sb_data}), wxHORIZONTAL);
   $self->{g}{sbs_dir}  = Wx::StaticBoxSizer->new(Wx::StaticBox->new($p, wxID_ANY, $_str{sb_dir}),  wxHORIZONTAL);
   $self->{g}{sbs_opts} = Wx::StaticBoxSizer->new(Wx::StaticBox->new($p, wxID_ANY, $_str{sb_opts}), wxHORIZONTAL);
   $self->{g}{sbs_out}  = Wx::StaticBoxSizer->new(Wx::StaticBox->new($p, wxID_ANY, $_str{sb_out}),  wxHORIZONTAL);
   $self->{g}{sbs_exec} = Wx::StaticBoxSizer->new(Wx::StaticBox->new($p, wxID_ANY, $_str{sb_exec}), wxHORIZONTAL);

   ### Controls / widgets
   # Connection
   $self->{g}{lbl_host} = Wx::StaticText->new($p, wxID_ANY, $_str{lbl_host});
   $self->{g}{txt_host} = Wx::TextCtrl->new($p, wxID_ANY, $self->{v}{host});
   $self->{g}{lbl_port} = Wx::StaticText->new($p, wxID_ANY, $_str{lbl_port});
   $self->{g}{spn_port} = Wx::SpinCtrl->new($p, wxID_ANY, $self->{v}{port}, @spn_opts, 1, 65535);
   # Data
   $self->{g}{lbl_data_size} = Wx::StaticText->new($p, wxID_ANY, $_str{lbl_data_size});
   $self->{g}{spn_data_size} = Wx::SpinCtrl->new(
      $p,
      wxID_ANY,
      $self->{v}{data_size},
      @spn_opts,
      $self->{v}{chunk_size},
      $self->{v}{data_size} * 100
   );
   $self->{g}{lbl_chunk_size} = Wx::StaticText->new($p, wxID_ANY, $_str{lbl_chunk_size});
   $self->{g}{spn_chunk_size} = Wx::SpinCtrl->new(
      $p,
      wxID_ANY,
      $self->{v}{chunk_size},
      @spn_opts,
      1024,
      $self->{v}{data_size}
   );
   # Directions
   $self->{g}{chk_up}   = Wx::CheckBox->new($p, wxID_ANY, $_str{chk_up});
   $self->{g}{chk_down} = Wx::CheckBox->new($p, wxID_ANY, $_str{chk_down});
   # Options
   $self->{g}{chk_inf}  = Wx::CheckBox->new($p, wxID_ANY, $_str{chk_inf});
   $self->{g}{chk_rep}  = Wx::CheckBox->new($p, wxID_ANY, $_str{chk_rep});
   $self->{g}{spn_repeat} = Wx::SpinCtrl->new(
      $p,
      wxID_ANY,
      $self->{v}{repeat},
      @spn_opts,
      1,
      65535,
   );
   $self->{g}{lbl_interval}   = Wx::StaticText->new($p, wxID_ANY, $_str{lbl_interval});
   $self->{g}{spn_interval} = Wx::SpinCtrl->new(
      $p,
      wxID_ANY,
      $self->{v}{interval},
      @spn_opts,
      0,
      86400, # 24 hours in seconds
   );
   # Output
   $self->{g}{txt_out} = Wx::TextCtrl->new($p, wxID_ANY, '', wxDefaultPosition, wxDefaultSize, wxTE_MULTILINE);
   # Execute
   $self->{g}{btn_start} = Wx::Button->new($p, wxID_OK,     $_str{btn_start});
   $self->{g}{btn_stop}  = Wx::Button->new($p, wxID_CANCEL, $_str{btn_stop});
   $self->{g}{btn_clear} = Wx::Button->new($p, wxID_ANY,    $_str{btn_clear});
   $self->{g}{btn_exit}  = Wx::Button->new($p, wxID_ANY,    $_str{btn_exit});


   ### Layout
   $self->{g}{sbs_conn}->Add($self->{g}{lbl_host}, 0, wxALIGN_CENTER | wxALL,                          3);
   $self->{g}{sbs_conn}->Add($self->{g}{txt_host}, 1, wxEXPAND | wxALL,                                3);
   $self->{g}{sbs_conn}->Add($self->{g}{lbl_port}, 0, wxALIGN_CENTER | wxALL,                          3);
   $self->{g}{sbs_conn}->Add($self->{g}{spn_port}, 0, wxALIGN_CENTER_VERTICAL | wxALIGN_RIGHT | wxALL, 3);

   $self->{g}{sbs_data}->Add($self->{g}{lbl_data_size}, 0, wxALIGN_CENTER | wxALL, 3);
   $self->{g}{sbs_data}->Add($self->{g}{spn_data_size}, 0, wxALIGN_CENTER | wxALL, 3);
   $self->{g}{sbs_data}->AddStretchSpacer;
   $self->{g}{sbs_data}->Add($self->{g}{lbl_chunk_size}, 0, wxALIGN_CENTER | wxALL, 3);
   $self->{g}{sbs_data}->Add($self->{g}{spn_chunk_size}, 0, wxALIGN_CENTER | wxALL, 3);

   $self->{g}{sbs_dir}->Add($self->{g}{chk_up},   0, wxALIGN_CENTER | wxALL, 3);
   $self->{g}{sbs_dir}->Add($self->{g}{chk_down}, 0, wxALIGN_CENTER | wxALL, 3);

   $self->{g}{sbs_opts}->Add($self->{g}{chk_inf},    0, wxALIGN_CENTER | wxALL, 3);
   $self->{g}{sbs_opts}->Add($self->{g}{chk_rep},    0, wxALIGN_CENTER | wxALL, 3);
   $self->{g}{sbs_opts}->Add($self->{g}{spn_repeat}, 0, wxALIGN_CENTER | wxALL, 3);
   $self->{g}{sbs_opts}->AddStretchSpacer;
   $self->{g}{sbs_opts}->Add($self->{g}{lbl_interval}, 0, wxALIGN_CENTER | wxALL, 3);
   $self->{g}{sbs_opts}->Add($self->{g}{spn_interval}, 0, wxALIGN_CENTER | wxALL, 3);

   $self->{g}{sbs_out}->Add($self->{g}{txt_out}, 1, wxEXPAND);

   $self->{g}{sbs_exec}->Add($self->{g}{btn_start}, 0, wxALIGN_CENTER | wxALL, 3);
   $self->{g}{sbs_exec}->Add($self->{g}{btn_stop},  0, wxALIGN_CENTER | wxALL, 3);
   $self->{g}{sbs_exec}->Add($self->{g}{btn_clear}, 0, wxALIGN_CENTER | wxALL, 3);
   $self->{g}{sbs_exec}->AddStretchSpacer;
   $self->{g}{sbs_exec}->Add($self->{g}{btn_exit}, 0, wxALIGN_RIGHT | wxALL, 3);

   $self->{g}{bs_panel}->Add($self->{g}{sbs_conn}, 0, wxEXPAND);
   $self->{g}{bs_panel}->Add($self->{g}{sbs_data}, 0, wxEXPAND);
   $self->{g}{bs_panel}->Add($self->{g}{sbs_dir},  0, wxEXPAND);
   $self->{g}{bs_panel}->Add($self->{g}{sbs_opts}, 0, wxEXPAND);
   $self->{g}{bs_panel}->Add($self->{g}{sbs_out},  1, wxEXPAND);
   $self->{g}{bs_panel}->Add($self->{g}{sbs_exec}, 0, wxEXPAND);

   $p->SetSizer($self->{g}{bs_panel});
   $self->{g}{bs_frame}->Add($p, 1, wxEXPAND | wxALL, 5);
   $self->SetSizerAndFit($self->{g}{bs_frame});


   ### Events
   Wx::Event::EVT_BUTTON($self->{g}{btn_exit}, wxID_ANY, sub { $self->Close; });



   #...
   return $self;
}


1;
__END__
