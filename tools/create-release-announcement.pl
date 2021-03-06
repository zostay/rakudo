use v6;

my $template = q:to/END_TEMPLATE/;
# Announce: Rakudo Perl 6 compiler, Release #«release-num» («release-name»)

On behalf of the Rakudo development team, I’m very happy to announce the
«month» «year» release of Rakudo Perl 6 #«release-num». Rakudo is an implementation of
Perl 6 on the Moar Virtual Machine[^1].

This release implements the 6.c version of the Perl 6 specifications.
It includes bugfixes and optimizations on top of
the 2015.12 release of Rakudo, but no new features.

Upcoming releases in 2016 will include new functionality that is not
part of the 6.c specification, available with a lexically scoped
pragma. Our goal is to ensure that anything that is tested as part of the
6.c specification will continue to work unchanged. There may be incremental
spec releases this year as well.

The tarball for this release is available from <http://rakudo.org/downloads/rakudo/>.

Please note: This announcement is not for the Rakudo Star
distribution[^2] --- it’s announcing a new release of the compiler
only. For the latest Rakudo Star release, see
<http://rakudo.org/downloads/star/>.

The changes in this release are outlined below:

New in «release-name»:
«changes»

These are only some of the changes in this release. For a more
detailed list, see “docs/ChangeLog”.

The following people contributed to this release:

«contributors»

If you would like to contribute or find out more information, visit
<http://perl6.org>, <http://rakudo.org/how-to-help>, ask on the
<perl6-compiler@perl.org> mailing list, or ask on IRC #perl6 on freenode.

The next release of Rakudo (#«next-release-num»), is tentatively scheduled for «next-release-date».

A list of the other planned release dates is available in the
“docs/release_guide.pod” file.

The development team appreciates feedback! If you’re using Rakudo, do
get back to us. Questions, comments, suggestions for improvements, cool
discoveries, incredible hacks, or any other feedback -- get in touch with
us through (the above-mentioned) mailing list or IRC channel. Enjoy!

Please note that recent releases have known issues running on the JVM.
We are working to get the JVM backend working again but do not yet have
an estimated delivery date.

[^1]: See <http://moarvm.org/>

[^2]: What’s the difference between the Rakudo compiler and the Rakudo
Star distribution?

The Rakudo compiler is a compiler for the Perl 6 language.
Not much more.

The Rakudo Star distribution is the Rakudo compiler plus a selection
of useful Perl 6 modules, a module installer, the most recent
incarnation of the “Using Perl 6” book, and other software that can
be used with the Rakudo compiler to enhance its utility.
END_TEMPLATE

my @ENGLISH-MONTHS = flat Any,
    <January February March April
     May June July August September
     October November December>;

sub prompt-with-default(Str $prompt, Str $default-value) returns Str {
    my $value = prompt("$prompt [$default-value]");
    if $value.defined && $value == '' {
        $value = $default-value;
    }

    $value
}

sub find-release-num() {
    my $offset = 14; # 14 releases aren't tagged with a year-month or
                     # year.month pattern
    my $proc = run('git', 'tag', '--list', '????.??', '--list', '????-??', :out);

    my $num-releases = $proc.out.lines.elems;
    $num-releases += $offset;

    $num-releases + 1
}

sub find-changes() {
    unless 'docs/ChangeLog'.IO.e {
        fail "Couldn't find docs/ChangeLog; are you running this from the Rakudo repository root?";
    }

    my $today = Date.today;
    my $last-month = $today.earlier(:1month);
    my $current-month = $today.month;
    my $current-year = $today.year;

    my $start = sprintf('%04d.%02d', $today.year, $today.month);
    my $end = sprintf('%04d.%02d', $last-month.year, $last-month.month);

    my @lines = do
        gather for 'docs/ChangeLog'.IO.lines -> $line {
            if $line ~~ m:s/New in "$start"/ ^ff^ $line ~~ m:s/New in "$end"/ {
                take $line;
            }
        };
    @lines ?? @lines.join("\n") !! '(no changes yet)'
}

sub find-release-name() {
    my $today = Date.today;
    sprintf('%04d.%02d', $today.year, $today.month)
}

sub find-contributors() {
    my $proc = run('./perl6-m', 'tools/contributors.pl6', :out);

    my @lines = $proc.out.lines;
    shift @lines;
    @lines.join("\n")
}

sub find-next-release-date() {
    unless 'docs/release_guide.pod'.IO.e {
        fail "Couldn't find docs/release_guide.pod; are you running this from the Rakudo repository root?";
    }

    my @lines = 'docs/release_guide.pod'.IO.lines;
    my $this-release = sprintf('%04d-%02d', Date.today.year, Date.today.month);
    my $this-release-index = @lines.first: /^ \s*"$this-release"/, :k;
    my $next-release = @lines[$this-release-index + 1];
    if $next-release ~~ /^ \s* (\d\d\d\d '-' \d\d '-' \d\d)/ {
        ~$0
    } else {
        fail "Could not find next release date in a correct format";
    }
}

my %template-vars;

%template-vars<release-num> = find-release-num();
%template-vars<next-release-num> = %template-vars<release-num> + 1;
%template-vars<release-name> = find-release-name();
%template-vars<year> = Date.today.year;
%template-vars<month> = @ENGLISH-MONTHS[Date.today.month];
%template-vars<changes> = find-changes();
%template-vars<contributors> = find-contributors();
%template-vars<next-release-date> = find-next-release-date();

my $content = $template.subst(/'«' $<ident>=[[\w| '-']+] '»'/, -> $/ {
    my $key = ~$<ident>;
    my $value = %template-vars{$key};

    die "Undefined template variable '$key'" unless $value;
    $value
}, :g);

say $content;
