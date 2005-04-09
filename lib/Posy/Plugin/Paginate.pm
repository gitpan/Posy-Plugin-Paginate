package Posy::Plugin::Paginate;
use strict;

=head1 NAME

Posy::Plugin::Paginate - Posy plugin to paginate multiple entries.

=head1 VERSION

This describes version B<0.22> of Posy::Plugin::Paginate.

=cut

our $VERSION = '0.22';

=head1 SYNOPSIS

    @plugins = qw(Posy::Core
	...
	Posy::Plugin::Paginate
	...
	));
    @actions = qw(init_params
	    ...
	    select_entries
	    filter_by_date
	    sort_entries
	    filter_by_page
	    ...
	);

=head1 DESCRIPTION

This plugin enables categories or chronological listsing with multiple
entries in them, to be broken up into a number of pages, with previous and
next links.  Page length is defined by the 'num_entries' configuration
setting; it will select entries depending on the 'page' parameter.

This provides the following variables that can be used within your
flavour files.

=over

=item B<flow_paginate_prev_link>

Contains a link to the previous page, and is empty if this link is not valid.

=item B<flow_paginate_next_link>

Contains a link to the next page, and is empty if this link is not valid.

=item B<flow_paginate_page_list>

Contains links to all the pages, labelled by number.
For example, if there are four total pages, this would contain, by default,

    [1] [2] [3] [4]

See L</paginate_pnum_prefix> for information on formatting this.

=back

=head2 Activation

This plugin needs to be added to both the plugins list and the actions
list.

In the actions list, 'filter_by_page' needs to go somewhere after
B<sort_entries> and before B<head_render>, since the entries
need to have been sorted, and the selection needs to be done before
the head template is rendered, so that links could be put in the
head part of the page if required.

=head2 Configuration

This expects configuration settings in the $self->{config} hash,
which, in the default Posy setup, can be defined in the main "config"
file in the config directory.

=over 

=item B<paginate_prev_label>

The label for the "prev" link.
(default: '&lt;&lt;- prev')

=item B<paginate_next_label>

The label for the "next" link.
(default: 'next -&gt;&gt;')

=item B<paginate_pnum_prefix>

When listing all the pages in $flow_paginate_page_list, each link is given
a prefix and a suffix.  The default prefix is '['.

=item B<paginate_pnum_suffix>

The suffix for the links inside $flow_paginate_page_list.  The default
suffix is ']'.

=back

=cut

=head1 OBJECT METHODS

Documentation for developers and those wishing to write plugins.

=head2 init

Do some initialization; make sure that default config values are set.

=cut
sub init {
    my $self = shift;
    $self->SUPER::init();

    # set defaults
    $self->{config}->{paginate_prev_label} = '&lt;&lt;- prev'
	if (!defined $self->{config}->{paginate_prev_label});
    $self->{config}->{paginate_next_label} = 'next -&gt;&gt;'
	if (!defined $self->{config}->{paginate_next_label});
    $self->{config}->{paginate_pnum_prefix} = '['
	if (!defined $self->{config}->{paginate_pnum_prefix});
    $self->{config}->{paginate_pnum_suffix} = ']'
	if (!defined $self->{config}->{paginate_pnum_suffix});
} # init

=head1 Flow Action Methods

Methods implementing actions.

=head2 filter_by_page

$self->filter_by_page($flow_state);

Select entries by looking at the 'page' parameter.
Assumes that $flow_state->{entries} has already been
populated AND sorted; updates it.

Also sets $flow_paginate_prev_link and $flow_paginate_next_link
template variables.

=cut
sub filter_by_page {
    my $self = shift;
    my $flow_state = shift;

    if ($self->{config}->{num_entries})
    {
	my $num_files = @{$flow_state->{entries}};
	my $pages = ($num_files / $self->{config}->{num_entries}) + 1;
	$flow_state->{pages} = $pages;
	# Make sure the page number param is in the valid range;
	$self->param('page') =~ /(\d+)/;
	my $page = $1;
	$page ||= 1;
	$flow_state->{page} = $page;
	# Determine number of entries to skip
	my $skip = $self->{config}->{num_entries} * ($page-1);
	# index of last entry to include
	my $last = $skip + $self->{config}->{num_entries};
	$last = @{$flow_state->{entries}}
	    if ($last > @{$flow_state->{entries}});
	$last--; # need the index, not the count

	# set the selected entries
	my @entries = @{$flow_state->{entries}}[$skip .. $last];
	@{$flow_state->{entries}} = @entries;

	# set the prev link
	$flow_state->{paginate_prev_link} = '';
	my $label = '';
	# preserve the current query string, sans page param
	my $qstr = $ENV{QUERY_STRING};
	$qstr =~ s/page=\d+//;
	$qstr =~ s/^\&amp;//;
	$qstr =~ s/^\&//;
	$qstr =~ s/\&$//;
	$qstr =~ s/\&amp;$//;
	if ($page > 1)
	{
	    $label = $self->{config}->{paginate_prev_label};
	    $flow_state->{paginate_prev_link} =
		join('', '<a href="', $self->{url},
		     $self->{path}->{info},
		     '?page=', $page - 1,
		     ($qstr ? "&amp;$qstr" : ''), '">',
		     $label, '</a>');
	}
	# set the all-the-pages links
	my $page_list = '';
	if ($page > 1 || (($page+1) < $pages))
	{
	    for (my $i=1; $i <= $pages; $i++)
	    {
		$page_list .=
		join('', ' ', $self->{config}->{paginate_pnum_prefix},
		    '<a href="', $self->{url},
		     $self->{path}->{info},
		     '?page=', $i,
		     ($qstr ? "&amp;$qstr" : ''), '">',
		     $i, '</a>',
		     $self->{config}->{paginate_pnum_suffix}, ' ');
	    }
	}
	$flow_state->{paginate_page_list} = $page_list;
	# set the next link
	$flow_state->{paginate_next_link} = '';
	if (($page+1) < $pages)
	{
	    $label = $self->{config}->{paginate_next_label};
	    $flow_state->{paginate_next_link} =
		join('', '<a href="', $self->{url},
		     $self->{path}->{info},
		     '?page=', $page + 1, 
		     ($qstr ? "&amp;$qstr" : ''), '">',
		     $label, '</a>');
	}
    }
} # filter_by_page

=head1 INSTALLATION

Installation needs will vary depending on the particular setup a person
has.

=head2 Administrator, Automatic

If you are the administrator of the system, then the dead simple method of
installing the modules is to use the CPAN or CPANPLUS system.

    cpanp -i Posy::Plugin::Paginate

This will install this plugin in the usual places where modules get
installed when one is using CPAN(PLUS).

=head2 Administrator, By Hand

If you are the administrator of the system, but don't wish to use the
CPAN(PLUS) method, then this is for you.  Take the *.tar.gz file
and untar it in a suitable directory.

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you're on a platform (like DOS or Windows) that doesn't like the
"./" notation, you can do this:

   perl Build.PL
   perl Build
   perl Build test
   perl Build install

=head2 User With Shell Access

If you are a user on a system, and don't have root/administrator access,
you need to install Posy somewhere other than the default place (since you
don't have access to it).  However, if you have shell access to the system,
then you can install it in your home directory.

Say your home directory is "/home/fred", and you want to install the
modules into a subdirectory called "perl".

Download the *.tar.gz file and untar it in a suitable directory.

    perl Build.PL --install_base /home/fred/perl
    ./Build
    ./Build test
    ./Build install

This will install the files underneath /home/fred/perl.

You will then need to make sure that you alter the PERL5LIB variable to
find the modules, and the PATH variable to find the scripts (posy_one,
posy_static).

Therefore you will need to change:
your path, to include /home/fred/perl/script (where the script will be)

	PATH=/home/fred/perl/script:${PATH}

the PERL5LIB variable to add /home/fred/perl/lib

	PERL5LIB=/home/fred/perl/lib:${PERL5LIB}

=head1 REQUIRES

    Posy
    Posy::Core

    Test::More

=head1 SEE ALSO

perl(1).
Posy
YAML

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    perlkat AT katspace dot com
    http://www.katspace.com

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2005 by Kathryn Andersen

Parts of this taken from the original 'paginate' blosxom plugin
copyright (c) 2003 by l.m.orchard http://www.decafbad.com

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

1; # End of Posy::Plugin::Paginate
__END__
