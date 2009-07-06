#!/usr/bin/perl

use strict;
use warnings;

package Flickr::WxPerlUploader::Photo;

our $NUM_DESCRIPTION_PARTS = 5;

use Class::XSAccessor
    accessors => {
        (map { $_ => $_ } 
        (qw(
            filename
            tags
            title
            description_parts
        )),
        )
    }
    ;

sub new
{
    my $class = shift;

    my $self = {};
    bless $self, $class;

    $self->_init(@_);

    return $self;
}

sub _init
{
    my $self = shift;
    my $args = shift;

    $self->filename($args->{'filename'});

    if (! -e $self->filename())
    {
        die "Unknown filename '" . $self->filename() . "'!";
    }

    $self->tags([ @{$args->{'tags'}} ]);

    $self->title($args->{'title'});

    $self->description_parts([ @{$args->{'description_parts'}}]);

    if (@{$self->description_parts()} != $NUM_DESCRIPTION_PARTS)
    {
        die ("Incorrect number of description parts - " 
            . scalar(@{$self->description_parts()}) . "!"
        );
    }

    return;
}

package Flickr::WxPerlUploader::App;

use base 'Wx::App';
use Wx ':everything';
use Wx::Event qw(EVT_LISTBOX_DCLICK);

use Class::XSAccessor
    accessors => {
        (map { $_ => $_ } 
        (qw(
            _common_tags
            _photo_files
        )),
        )
    }
    ;

use YAML::XS qw(LoadFile);

sub _read_photos {
    my $self = shift;

    my $filename = "upload-spec.yml";

    my $yaml = LoadFile($filename);

    $self->_common_tags($yaml->{'common_tags'});

    $self->_photo_files(
        [ map { 
            Flickr::WxPerlUploader::Photo->new(
                $_,
            )
            } @{$yaml->{'files'}},
        ]
    );

    return;
}

sub new
{
    my ($class, $args) = @_;

    my $self = $class->SUPER::new();

    return $self;
}

sub OnInit
{
    my( $self ) = @_;

    $self->_read_photos();

    my $frame = Wx::Frame->new( undef, -1, 'wxPerl', wxDefaultPosition, [ 200, 100 ] );

    my $menu_bar = Wx::MenuBar->new;

    my $file_menu = Wx::Menu->new;
    
    my $exit_item = $file_menu->Append(Wx::wxID_NEW, Wx::gettext("E&xit"));

    Wx::Event::EVT_MENU(
        $frame,
        $exit_item,
        sub {
            $_[0]->Close();
        },
    );

    $menu_bar->Append($file_menu, "&File");

    $frame->SetMenuBar($menu_bar);

    my $sizer = Wx::BoxSizer->new(wxHORIZONTAL());

    $frame->SetSizer($sizer);

    $sizer->Add($frame->{board}, 1, wxALL(), 10);
    $frame->{list} = Wx::ListBox->new(
        $frame,
        -1,
        wxDefaultPosition(),
        wxDefaultSize(),
        [ 
            map { $_->filename() } @{$self->_photo_files()}
        ],
    );
    $sizer->Add($frame->{list}, 1, wxALL(), 10);

    $frame->SetSize(Wx::Size->new(600,400));
    $frame->Show( 1 );

    $self->{frame} = $frame;

    EVT_LISTBOX_DCLICK($frame->{list}, wxID_ANY(), sub {
            my $list = shift;
            my $event = shift;

            my $sel = $event->GetSelection();
            my $string = $list->GetString($sel);
            $frame->{board}->perform_solve($string);
        }
    );

    return 1;
}

package main;

Flickr::WxPerlUploader::App->new(
    {
        argv => [@ARGV],
    }
)->MainLoop();
