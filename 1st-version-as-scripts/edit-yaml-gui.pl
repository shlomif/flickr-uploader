#!/usr/bin/perl
# Copyright (c) 2009 Shlomi Fish
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

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

    my $controls_sizer = Wx::GridSizer->new(2, 10, 10);

    $sizer->Add($controls_sizer, 1, wxALL(), 10);

    my $title_label = Wx::StaticText->new(
        $frame, -1, "Title:",
        Wx::wxDefaultPosition,
        Wx::wxDefaultSize,
        Wx::wxALIGN_LEFT,
    );


    my $title_box = Wx::TextCtrl->new(
        $frame, -1, "", 
        Wx::wxDefaultPosition,
        Wx::wxDefaultSize,
        Wx::wxTE_PROCESS_ENTER
    );

    $self->{title_box} = $title_box;

    $controls_sizer->Add($title_label, 1, wxALL(), 10);
    $controls_sizer->Add($title_box, 1, wxALL(), 10);

    $frame->SetSize(Wx::Size->new(600,400));
    $frame->Show( 1 );

    $self->{frame} = $frame;

    $self->{_prev_image} = undef;

    Wx::Event::EVT_LISTBOX( $self, $frame->{list}, 
        sub {
            my $list = shift;
            my $event = shift;

            if (defined($self->{_prev_image}))
            {
                $self->_photo_files->[$self->{_prev_image}]->title(
                    $title_box->GetValue()
                );
            }

            my $idx = $event->GetSelection();

            $self->{_prev_image} = $idx;

            $title_box->SetValue(
                $self->_photo_files->[$idx]->title()
            );

            return;
        },
    );
=begin Hello

    EVT_LISTBOX_DCLICK($frame->{list}, wxID_ANY(), sub {
            my $list = shift;
            my $event = shift;

            my $sel = $event->GetSelection();
            my $string = $list->GetString($sel);
        }
    );

=end Hello

=cut

    return 1;
}

package main;

Flickr::WxPerlUploader::App->new(
    {
        argv => [@ARGV],
    }
)->MainLoop();

