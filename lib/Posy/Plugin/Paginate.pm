package Posy::Plugin::Paginate;
use strict;

=head1 NAME

Posy::Plugin::Paginate - Posy plugin to paginate multiple entries.

=head1 VERSION

This describes version B<0.20> of Posy::Plugin::Paginate.

=cut

our $VERSION = '0.20';

=head1 SYNOPSIS

    @plugins = qw(Posy::Core
	...
	Posy::Plugin::Paginate
	...
	));
    @actions = qw(init_params
	    ...
	    select_by_path
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
