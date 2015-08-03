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

use File::Spec;
use YAML::XS;

opendir my $cwd, ".";
my @paths = sort { $a cmp $b } grep { /\.(jpg|png)$/ } (File::Spec->no_upwards(readdir($cwd)));
closedir ($cwd);

my $yaml_fn = "upload-spec.yml";
if (-e $yaml_fn)
{
    die "YAML File already exists!";
}
YAML::XS::DumpFile(
    $yaml_fn,
    {
        common_tags => [],
        files =>
        [
            (map
            {
                {
                    'filename' => $_,
                    'tags' => [],
                    title => "",
                    description_parts =>
                    [ map { "" } (1 .. 5) ],
                }
            }
            @paths),
        ],
    },
);

