package Math::Fraction;

# Purpose: To Manipulate Exact Fractions
#
# Copyright 1997 by Kevin Atkinson (kevina@cark.net)
# Version .4a  (24 Mar 1997)
# Alpha Release: Not Very Well Tested
# Developed with Perl v 5.003_37 for Win32.
# Has been testing on Perl Ver 5.003 on a solaris machine.
#
# By using this software you have become an Alpha tester.  By becoming an
# Alpha tester you have agreeded to give be some sort of feedback.
#
# See the files MANUAL and README for more information

require Exporter;
$VERSION = ".3";
@ISA = qw(Exporter);
@EXPORT = qw(frac);
@EXPORT_OK = qw(reduce string decimal num list is_tag);
%EXPORT_TAGS = (
  STR_NUM => [qw(string decimal num)],
);

use Carp;
use strict;
use Math::BigInt;
use Math::BigFloat;
use overload
   "+"   => "add",
   "-"   => "sub",
   "*"   => "mul",
   "/"   => "div",
   "abs" => "abs",
   "**"  => "pow",
   "sqrt"=> "sqrt",
   "<=>" => "cmp",
   '""'  => "string",
   "0+"  => "decimal";
   "fallback" => 1;

my %DEF = (
  CURRENT => {TAGS => ['NORMAL','REDUCE','SMALL','AUTO'], DIGITS => undef, SYSTEM => 1, NAME => 'DEFAULT'},
  DEFAULT => {TAGS => ['NORMAL','REDUCE','SMALL','AUTO'], DIGITS => undef, READONLY=>1, SYSTEM=>1},
  BLANK   => {TAGS => ['','','']                 , DIGITS => ''   , READONLY=>1, SYSTEM=>1},
);

my ($OUTFORMAT, $REDUCE, $SIZE, $AUTO, $INTERNAL, $RED_STATE) = (0..5);
my $TAG_END = 3;          #Last index of tags ment to be kept.

my %TAGS = (
  NORMAL     => [$OUTFORMAT, 'NORMAL'],
  MIXED      => [$OUTFORMAT, 'MIXED'],
  MIXED_RAW  => [$OUTFORMAT, 'MIXED_RAW'],
  DEF_MIXED  => [$OUTFORMAT, undef],
  REDUCE     => [$REDUCE, 'REDUCE'],
  NO_REDUCE  => [$REDUCE, 'NO_REDUCE'],
  DEF_REDUCE => [$REDUCE, undef],
  SMALL      => [$SIZE, 'SMALL'],
  BIG        => [$SIZE, 'BIG'],
  DEF_BIG    => [$SIZE, undef],
  AUTO       => [$AUTO, 'AUTO'],
  NO_AUTO    => [$AUTO, 'NO_AUTO'],
  DEF_AUTO   => [$AUTO, undef],
  CONVERTED  => [$INTERNAL, 'CONVERTED'],
  IS_REDUCED => [$RED_STATE, 'IS_REDUCED'],
);

my @DEF_TAG = qw(DEF_MIXED DEF_REDUCE DEF_BIG DEF_AUTO);

my $ID = 01;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my ($self, @frac, @tags, $tag, $decimal, $p1, $p2, $p3);
  if (&_is_decimal($_[0]) and &_is_decimal($_[1]) and &_is_decimal($_[2]) ) {
      my $sign = $_[0]/abs($_[0]);
      @tags = &_tags(@_[3..$#_]);
      ($decimal, $p1, $p2, $p3) = &_fix_num(\@tags, @_[0..2]);
      ($p1, $p2, $p3) = (abs($p1),abs($p2),abs($p3) );
      @frac = ($p1*$p3+$p2, $sign*$p3);
      @frac = &_de_decimal(@frac, \@tags) if $decimal;
  } elsif (&_is_decimal($_[0]) and &_is_decimal($_[1]) ) {
      @tags = &_tags(@_[2..$#_]);
      ($decimal, @frac) = &_fix_num(\@tags, @_[0..1]);
      @frac = &_de_decimal(@frac, \@tags) if $decimal;
      @frac = &_simplify_sign(@frac);
  } elsif (&_is_decimal($_[0]) ) {
    {
      @tags = &_tags(@_[1..$#_]);
      ($decimal, $p1) = &_fix_num(\@tags, $_[0]);
      @frac=($p1,1), last if not $decimal;
      (@frac[0..1], $tag) = &_from_decimal($p1);
      @tags = &_tags(@tags, $tag);
      ($decimal,@frac) = &_fix_num(\@tags, @frac);
      @frac = &_de_decimal(@frac, \@tags) if $decimal;
    }
  } elsif ($_[0] =~ /\s*([\+\-]?)\s*([0-9e\.\+\-]+)\s+([0-9e\.\+\-]+)\s*\/\s*([0-9e\.\+\-]+)/) {
      my $sign = $1.'1';
      @tags = &_tags(@_[1..$#_]);
      ($decimal, $p1, $p2, $p3) = &_fix_num(\@tags, $2, $3, $4);
      ($p1, $p2, $p3) = (abs($p1),abs($p2),abs($p3) );
      @frac = ($p1*$p3+$p2, $sign*$p3);
      @frac = &_de_decimal($p1*$p3+$p2, $sign*$p3, \@tags) if $decimal;
  } elsif ($_[0] =~ /\s*([0-9e\.\+\-]+)\s*\/\s*([0-9e\.\+\-]+)/) {
      @tags = &_tags(@_[1..$#_]);
      ($decimal, @frac) = &_fix_num(\@tags, $1, $2);
      @frac = &_de_decimal(@frac, \@tags) if $decimal;
      @frac = &_simplify_sign(@frac);
  } else {
      croak("\"$_[0]\" is of unknown format");
  }
  croak ("Can not have 0 as the denominator") if $frac[1] == 0;

  if ( &_tag($REDUCE, \@tags) ne 'NO_REDUCE'
       and &_tag($RED_STATE, \@tags) ne 'IS_REDUCED' )
  {
    my $not_reduced;
    ($not_reduced, @frac) = &_reduce(@frac);
    @frac = &_fix_auto('DOWN',\@tags, @frac) if $not_reduced
                                       and &_tag($AUTO, \@tags) eq 'AUTO';
  }
                         
  @tags[$RED_STATE] = undef if &_tag($RED_STATE, \@tags) eq 'IS_REDUCED';

  $self->{'frac'}=\@frac;
  $self->{'tags'}=\@tags;
  bless ($self, $class);
  return $self;
}

# The following functions are met to be exported as shortcuts to method
# operations.

sub frac {
  #special exported function to simplify defining fractions
  return Math::Fraction->new(@_);
}

# Now are the methodes

sub string {
  my $self = shift;
  my @frac;
  my $mixed = &_tag ($OUTFORMAT, [$_[0]], $self->{'tags'} );
  if ($mixed eq 'MIXED') {
      @frac = $self->list('MIXED');
      my $string = "";
      $string .= "$frac[0]"           if $frac[0] != 0;
      $string .= " "                  if $frac[0] != 0 and $frac[1] !=0;
      $string .= "$frac[1]/$frac[2]"  if $frac[1] != 0;
      return $string;
  } elsif ($mixed eq 'MIXED_RAW') {
      @frac = $self->list('MIXED');
      return "$frac[0] $frac[1]/$frac[2]";
  } else {
      @frac = $self->list;
      return "$frac[0]/$frac[1]";
  }
}

sub list {
  my $self = shift;
  my @frac = @{$self->{'frac'}};
  if ($_[0] eq "MIXED") {
    my $whole=$frac[0]/$frac[1];
    $whole=int($whole) if not ref($frac[0]);
    $frac[0] = $frac[0] - $frac[1]*$whole;
    @frac = ($whole, @frac);
  }
  foreach (@frac) {s/^\+//;};
  return @frac;
}

sub reduce {
  my $self = shift;
  my ($undef, @frac) = &_reduce(@{$self->{'frac'}});
  return Math::Fraction->new(@frac, @{$self->{'tags'}});
}


sub decimal {
  my $self = shift;
  my @frac = @{$self->{'frac'}};
  return $frac[0]/$frac[1] if not ref($frac[0]);
  return Math::BigFloat->new(Math::BigFloat::fdiv($frac[0], $frac[1], $DEF{CURRENT}{DIGITS}) ) if ref($frac[0]);
}

sub num {
  my $self = shift;
  my @frac = @{$self->{'frac'}};
  return $frac[0]/$frac[1] if not ref($frac[0]);
  return Math::BigFloat->new(Math::BigFloat::fdiv($frac[0], $frac[1], $DEF{CURRENT}{DIGITS}) ) if ref($frac[0]);
}

## For the next three methods:
# If used on the object use the tags of the object
# If given a class use the dafault tags,
# .... if a default set is specified then return for that set.

sub is_tag {
  my $self = shift;
  my $tag = shift;
  my $default = 1 if $_[0] eq 'INC_DEF';
  my $is_tag = 0;
  my @tags;
  {
    $is_tag = 0, last if not $TAGS{$tag}; #if there is no such tag ret=0
    my ($num, $tag) = @{$TAGS{$tag}};
    if (ref($self) eq "Math::Fraction") {
      @tags = @{$self->{'tags'}};
      $is_tag = 1    , last if $tags[$num] eq $tag;
      $is_tag = undef, last if $tags[$num] eq undef and not $default;
      $is_tag = -1   , last if $DEF{CURRENT}{TAGS}[$num] eq $tag
                             and $tags[$num] eq undef and $default;
      $is_tag = 0; 
    } else {
      my $set;
      $set = 'CURRENT' unless $set = $_[0];
      $set = 'BLANK'   unless exists $DEF{$set};
      $is_tag = 1   , last if $DEF{$set}{TAGS}[$num] eq $tag;
      $is_tag = 0;
    }
  }
  return $is_tag;
}

sub tags {
  my $self = shift;
  my @tags;
  if (ref($self) eq "Math::Fraction") {
    my $inc_def = 1 if @_[0] eq 'INC_DEF';
    @tags = @{$self->{'tags'}}[0..$TAG_END];
    my $num;
    foreach $num (0 .. $#tags) {
      $tags[$num] = $DEF_TAG[$num]  if $tags[$num] eq undef and not $inc_def;
      $tags[$num] = $DEF{CURRENT}{TAGS}[$num] if $tags[$num] eq undef and $inc_def;
    }
  } elsif (ref($self) ne "Math::Fraction") {
    my $set;
    $set = 'CURRENT' unless $set = @_[0];
    $set = 'BLANK'   unless exists $DEF{$set};
    @tags = @{$DEF{$set}{TAGS}};
  }
  return @tags;
}

sub digits {
  my $self = shift;
  my $set;
  $set = 'CURRENT' unless $set = @_[0];
  $set = 'BLANK'   unless exists $DEF{$set};
  return $DEF{$set}{DIGITS};
}

##
# These mehods are used form managing default sets.

sub sets {
  my $self = shift;
  return keys %DEF;
}

sub name_set {
  shift; 
  return $DEF{CURRENT}{NAME}  if not $_[0];
  $DEF{CURRENT}{NAME} = $_[0] if     $_[0];
}

sub exists_set {
  return exists $DEF{$_[1]};
}

sub use_set {
  my $self = shift;
  my $name = shift;
  if (exists $DEF{$name} and not $DEF{$name}{READONLY}) {
    $DEF{CURRENT} = $DEF{$name};
    return $name;
  } else {
    return undef;
  }
}

sub temp_set {
  my $self = shift;
  my $name = shift;
  if (not $name) {
    $ID++;
    $name = "\cI\cD$ID";
    $self->copy_set('CURRENT', $name);
    $self->copy_set('DEFAULT', 'CURRENT');
    return $name;
  } else { #if $name;
    my $return = $self->copy_set($name, 'CURRENT');
    $self->del_set($name);
    return $return
  }
}


sub load_set {
  my $self = shift;
  if (exists $DEF{$_[0]}) {
    $self->copy_set($_[0],'CURRENT') if exists $DEF{$_[0]};
    return $_[0]
  } else {
    return undef;
  }
}

sub save_set {
  my $self = shift;
  my $name;
  $name = $DEF{CURRENT}{NAME} unless $name = shift;
  ++$ID, $name = "\cI\cD:$ID" if not $name or $name eq 'RAND';
  return $self->copy_set('CURRENT', $name) && $name;
}

sub copy_set {
  shift;
  my ($name1, $name2) = @_;
  if ($DEF{$name2}{READONLY} or $name2 eq 'BLANK' or not exists $DEF{$name1}) {
    return 0;
  } else {
    $DEF{$name2} = {};                         # kill any links from use;
    $DEF{$name2}{TAGS} = [@{$DEF{$name1}{TAGS}}];
    $DEF{$name2}{DIGITS} = $DEF{$name1}{DIGITS};
    $DEF{$name2}{NAME} = $name2 unless $name2 eq 'CURRENT';
    $DEF{$name2}{NAME} = $name1   if   $name2 eq 'CURRENT';
    return 1;
  }
}

sub del_set {
  if (exists $DEF{$_[1]} and not $DEF{$_[1]}{SYSTEM}) {
    delete $DEF{$_[1]};
    return $_[1];
  }
}

# All of the modify methods are not meant to return anything, they modify
# the object being referenced too.

sub modify {
  # This method works almost like the new method except that it takes an
  # object as an argement and will modify it instead of creating a new
  # object, also any tags assosated with the object are left in tact
  # unless a new tag is given to override the old.

  my $me = shift;
  my $self;
  my @tags = @{$me->{'tags'}};
  $self = Math::Fraction->new(@_, @tags, @_);  # The extra @_ is their to override tags
  $me->{'frac'} = $self->{'frac'};
  $me->{'tags'} = $self->{'tags'};
}

sub modify_digits {
  my $self = shift;
  $DEF{CURRENT}{DIGITS} = shift;
}

sub modify_reduce {
  my $me = shift;
  my $self = $me->reduce;
  $me->{'frac'} = $self->{'frac'};
  $me->{'tags'} = $self->{'tags'};
}


sub modify_num {
  my $self = shift;
  $self->[0] = $_[0]
}

sub modify_den {
  my $self = shift;
  $self->[1] = $_[0]
}

sub modify_tag {
  my $self = shift;
  my ($return, @return);
  my $newtag;
 foreach $newtag (@_) {
  my $tagnum = &_tagnum($newtag);
  if ($tagnum == -1) {
    push @return, undef;
  } elsif (ref($self) eq "Math::Fraction") {
    my @frac = @{$self->{'frac'}};
    my @tags = @{$self->{'tags'}};
    my @newtags = &_tags(@tags,$newtag);
    # Now transform the Fraction based on the new tag.
    if ($tagnum == $SIZE) {
      my $newtag = &_tag($SIZE, \@newtags);
      @frac = map { "$_"+0 } @frac                if $newtag eq 'SMALL';
      @frac = map { Math::BigInt->new($_) } @frac if $newtag eq 'BIG';
    } elsif ($tagnum == $REDUCE) {
      (undef, @frac) = &_reduce(@frac) if &_tag($REDUCE, \@newtags) eq 'REDUCE';
    }
    # Finally Modify the Fraction
    $self->{'frac'} = \@frac; 
    $self->{'tags'} = \@newtags;
  } else {  
    $DEF{CURRENT}{TAGS}[$tagnum] = $newtag;
  }
  push @return, $newtag;
 }
 return @return;
}
    
# These methods are meant to be called with the overload operators.

sub add {
  my @frac1 = @{$_[0]->{'frac'}};
  my @tags1 = @{$_[0]->{'tags'}};
  my (@frac2, @frac, @tags2, $frac);
  my $skipauto = 0;
  @frac2 = @{$_[1]->{'frac'}}, @tags2 = @{$_[1]->{'tags'}} if ref($_[1]) eq "Math::Fraction";
  @frac2 = &_from_decimal($_[1]), $tags2[$INTERNAL] = 'CONVERTED' if ref($_[1]) ne "Math::Fraction";
  my @tags = &_tags_preserve([@tags1],[@tags2]);

 LOOP: {
  if (&_tag($REDUCE, \@tags) eq 'NO_REDUCE') {
    @frac = ($frac1[0]*$frac2[1]+$frac2[0]*$frac1[1],$frac1[1]*$frac2[1]);
  } else {
    # Taken from Knuth v2 (rev 2), p313.
    # It will always return a reduced fraction.
    my $gcd1 = &_gcd($frac1[1],$frac2[1]);
    my $tmp = $frac1[0]*($frac2[1]/$gcd1) + $frac2[0]*($frac1[1]/$gcd1);
    my $gcd2 = &_gcd($tmp,$gcd1);
    @frac = ( $tmp/$gcd2, ($frac1[1]/$gcd1)*($frac2[1]/$gcd2) );
    $tags[$RED_STATE] = 'IS_REDUCED';
  }
  if ( (&_tag($AUTO, \@tags) eq 'AUTO') and (not $skipauto) and
     ($tags[$SIZE] eq 'SMALL') and ($frac[0]=~/[eE]/ or $frac[1]=~/[eE]/) )
  {
    (@frac1[0..1], @frac2[0..1]) = map { Math::BigInt->new($_) } (@frac1, @frac2);
    $tags[$SIZE] = 'BIG';
    $skipauto = 1;
    redo LOOP;
  }
 }
  return Math::Fraction->new(@frac, @tags);
}

sub sub {
  my ($frac1, $frac2) = ($_[$_[2]], $_[not $_[2]]);  # swap if needed
  $frac1 = Math::Fraction->new($frac1, 'CONVERTED')  if ref($frac1) ne "Math::Fraction";
  $frac2 = Math::Fraction->new($frac2, 'CONVERTED')  if ref($frac2) ne "Math::Fraction";

  $frac2 = Math::Fraction->new($frac2->{'frac'}[0], -$frac2->{'frac'}[1], @{$frac2->{'tags'}});

  return $frac1 + $frac2;
}

sub mul {
  my @frac1 = @{$_[0]{'frac'}};
  my @tags1 = @{$_[0]{'tags'}};
  my (@frac2, @frac, @tags2);
  @frac2 = @{$_[1]->{'frac'}}, @tags2 = @{$_[1]->{'tags'}} if ref($_[1]) eq "Math::Fraction";
  @frac2 = (&_from_decimal($_[1])), $tags2[$INTERNAL] = 'CONVERTED' if ref($_[1]) ne "Math::Fraction";
  my @tags = &_tags_preserve([@tags1],[@tags2]);
  my $skipauto = 0;
 LOOP: {
  if (&_tag($REDUCE, \@tags) eq 'NO_REDUCE') {
    @frac = ($frac1[0]*$frac2[0],$frac1[1]*$frac2[1]);
  } else {
    my($gcd1, $gcd2)=(&_gcd($frac1[0],$frac2[1]),&_gcd($frac2[0],$frac1[1]));
    $frac[0] = ($frac1[0]/$gcd1)*($frac2[0]/$gcd2);
    $frac[1] = ($frac1[1]/$gcd2)*($frac2[1]/$gcd1);
    $tags[$RED_STATE] =  'IS_REDUCED';
  }
  if ( (&_tag($AUTO, \@tags) eq 'AUTO') and (not $skipauto) and
       ($tags[$SIZE] eq 'SMALL') and ($frac[0]=~/[eE]/ or $frac[1]=~/[eE]/) )
  {
    (@frac1[0..1], @frac2[0..1]) = map { Math::BigInt->new($_) } (@frac1, @frac2);
    $tags[$SIZE] = 'BIG';
    $skipauto = 1;
    redo LOOP;
  }
 }
  return Math::Fraction->new(@frac, @tags);
}

sub div {
  my ($frac1, $frac2) = ($_[$_[2]], $_[not $_[2]]);  # swap if needed
  $frac1 = Math::Fraction->new($frac1, 'CONVERTED')  if ref($frac1) ne "Math::Fraction";
  $frac2 = Math::Fraction->new($frac2, 'CONVERTED')  if ref($frac2) ne "Math::Fraction";

  $frac2 = Math::Fraction->new($frac2->{'frac'}[1], $frac2->{'frac'}[0], @{$frac2->{'tags'}});
      #Makes a copy of the fraction with the num and den switched.

  return $frac1 * $frac2;
}

sub pow {
  my (@frac, @frac1, @tags1);
  @frac1 = @{$_[$_[2]]->{'frac'}}, @tags1 = @{$_[$_[2]]->{'tags'}} if ref($_[$_[2]]) eq "Math::Fraction";
  @frac1 = &_from_decimal($_[$_[2]])                       if ref($_[$_[2]]) ne "Math::Fraction";
  my $frac2;
  $frac2 = $_[not $_[2]]->decimal        if ref($_[not $_[2]]) eq "Math::Fraction";
  $frac2 = $_[not $_[2]]                 if ref($_[not $_[2]]) ne "Math::Fraction";
  my @tags = @tags1;
  my $skipauto = 0;

 LOOP: { 
  @frac = ($frac1[0]**$frac2,$frac1[1]**$frac2);

  if ( (&_tag($AUTO, \@tags) eq 'AUTO') and (not $skipauto) and
     ($tags[$SIZE] eq 'SMALL') and ($frac[0]=~/[eE]/ or $frac[1]=~/[eE]/) )
  {
    @frac1 = map { Math::BigInt->new($_) } @frac1;
    $tags[$SIZE] = 'BIG';
    $skipauto = 1;
    redo LOOP;
  }
 }

  return Math::Fraction->new(@frac, @tags);
}

sub sqrt {
  my $self = shift;
  my @frac = @{$self->{'frac'}};
  my @tags = @{$self->{'tags'}};
  my $ans;
  if ( ref($frac[0]) ) {
    $frac[0] = Math::BigFloat->new( Math::BigFloat::fsqrt($frac[0], $DEF{CURRENT}{DIGITS}) );
    $frac[1] = Math::BigFloat->new( Math::BigFloat::fsqrt($frac[1], $DEF{CURRENT}{DIGITS}) );
  } else {
    @frac = (sqrt($frac[0]) , sqrt($frac[1]));
  }
  return Math::Fraction->new(@frac, @tags);
}


sub abs {
  my $self = shift;
  my @frac = @{$self->{'frac'}};
  my @tags = @{$self->{'tags'}};
  return Math::Fraction->new(abs($frac[0]),abs($frac[1]),@tags,'IS_REDUCED');
}

sub cmp {
  my @frac1 = @{$_[0]->{'frac'}};
  my @tags1 = @{$_[0]->{'tags'}};
  my (@frac2, @frac, @tags2, $x, $y);
  @frac2 = @{$_[1]->{'frac'}}, @tags2 = @{$_[1]->{'tags'}} if ref($_[1]) eq "Math::Fraction";
  @frac2 = &_from_decimal($_[1]), @tags2 = qw(CONVERTED)   if ref($_[1]) ne "Math::Fraction";
  my @tags = &_tags_preserve([@tags1],[@tags2]);
  if (&_tag($REDUCE, \@tags) == 'NO_REDUCE') {
    $x = $frac1[0]*$frac2[1];
    $y = $frac2[0]*$frac1[1];
  } else {
    my $gcd1 = &_gcd($frac1[1],$frac2[1]);
    $x = $frac1[0]*($frac2[1]/$gcd1);
    $y = $frac2[0]*($frac1[1]/$gcd1);
  }
  return $x <=> $y;
}

# These function are that functions and not ment to be used as methods

sub _fix_num {
  my $tagsref = shift;
  my @return = @_;
  my $auto = &_tag($AUTO, $tagsref) eq 'AUTO';
  $tagsref->[$SIZE] = &_tag($SIZE, $tagsref); 
  $tagsref->[$SIZE] = 'SMALL'  if $auto;
  my $num;
  my $decimal = 0;
  foreach $num (@return) {
    if (ref($num) eq "Math::BigFloat") {
      $tagsref->[$SIZE] = 'BIG' unless $auto;
      $decimal = 1;
    } elsif (ref($num) eq "Math::BigInt") {
      $tagsref->[$SIZE] = 'BIG' unless $auto;
    } elsif (ref($num)) {
      # do nothing
    } elsif ($num =~ /[\.\e\E]/) {
      $decimal = 1;
    }
    if ($auto) {
      $num =~ /[\+\-]?\s*0*([0-9]*)\s*\.?\s*([0-9]*)0*/;
      my $length = length($1)+length($2);
      $tagsref->[$SIZE] = 'BIG' if $length > 15;
    }
  }
  if ($tagsref->[$SIZE] eq 'BIG') {
    @return = map {Math::BigInt->new("$_")}   @return  if not $decimal;
    @return = map {Math::BigFloat->new("$_")} @return  if     $decimal;
  }
  if ($tagsref->[$SIZE] eq 'SMALL' and $auto) {
    @return = map {"$_"+0} @return;
  }
  return ($decimal, @return);
}

sub _fix_auto {
  my $direction = shift;
  my $tagsref = shift;
  my @return = @_;
  $tagsref->[$SIZE] = 'SMALL';
  my $num;
  foreach $num (@return) {
    $num =~ /[\+\-]?\s*0*([0-9]*)\s*\.?\s*([0-9]*)0*/;
    my $length = length($1)+length($2);
    $tagsref->[$SIZE] = 'BIG' if $length > 15;
  }
  if ($tagsref->[$SIZE] eq 'BIG' and $direction eq 'BOTH') {
    @return = map {Math::BigInt->new("$_")} @return;
  } elsif ($tagsref->[$SIZE] eq 'SMALL') {
    @return = map {"$_"+0} @return;
  }
  return (@return);
}

sub _is_decimal {
  my $return = $_[0] =~ /^\s*[\+\-0-9eE\.]+\s*$/;
  return $return;
}

sub _reduce {
  my @frac = @_;
  my $gcd = &_gcd(@frac);
  if ($gcd == 1 ) {
    return (0, @frac)
  } else {
    return (1, $frac[0]/$gcd, $frac[1]/$gcd);
  }
}  

sub _simplify_sign {
  my @frac = @_;
  my $sign = 1;
  $sign = ($frac[0]/abs($frac[0]))*($frac[1]/abs($frac[1])) if $frac[0];
  @frac = ($sign*abs($frac[0]), abs($frac[1]) );
  return @frac;
}

sub _tags {
  my @return = (undef, undef);
  my ($NUM, $VALUE) = (0, 1);

  foreach (@_) {
    next if not $TAGS{$_};
    my ($num, $value) = @{$TAGS{$_}};
    $return[$num] = $value;
  }

  return @return;
}


sub _tag {
  my $item = shift;
  my $return;
  my $ref;
  foreach $ref (@_, $DEF{CURRENT}{TAGS}) {
    last if $return = ${$ref}[$item];
  }
  return $return
}

sub _tagnum {
  my $item = shift;
  if (exists $TAGS{$item}) {
    return $TAGS{$item}[0];
  } else {
    return -1;
  }
}

sub _tags_preserve {
  my @tags1 = @{$_[0]};
  my @tags2 = @{$_[1]};
  my @tags;
  if ($tags1[$INTERNAL] eq 'CONVERTED') {
    @tags = @tags2;
  } elsif ($tags2[$INTERNAL] eq 'CONVERTED') {
    @tags = @tags1;
  } else {
    @tags = map {$tags1[$_] eq $tags2[$_] and $tags1[$_]} (0 .. $#tags1) ;
  }
  return @tags;
}

sub _gcd {
  # Using Euclid's method found in Knuth v2 (rev 2) p320 brought to my
  # attention from the BigInt module

  my ($x, $y) = (abs($_[0]), abs($_[1]));
  if ( ref($x) ) {
    $x = Math::BigInt->new( $x->bgcd($y) );
  } else {
    {
      $x=1, last if $y > 1e17; # If this is so % will thinks its a zero so if
                               # $y>1e17 will simply will basicly give up and
                               # have it return 1 as the GCD.
      my ($x0);
      while ($y != 0) {
        $x0 = $x;
        ($x, $y) = ($y, $x % $y);
        # Note $x0 = $x, $x = $y, $y= $x % $y   Before the Swith
        $x=1, last  if ($x0>99999999 or $x>999999999) and int($x0/$x)*$x+$y != $x0;
        # This is to see if the mod operater through up on us when dealing with
        # large numbers.  If it did set the gcd = 1 and quit.
      }
    }
  }
  return $x;
}

sub _de_decimal {
    my @frac = @_;
    my @return;
    my $big = &_tag($SIZE, $_[2]);
    my (@int_part, @decimal_part);
    if ($big eq "BIG") {
      my @digits = (1,1);
      ($int_part[0], $digits[0]) = $frac[0]->fnorm =~ /(\d+)E\-(\d+)/;
      ($int_part[1], $digits[1]) = $frac[1]->fnorm =~ /(\d+)E\-(\d+)/;
      @digits = sort {$a <=> $b} @digits;
      my $factor = 10**$digits[1];
      @frac = (($_[0]*$factor),($_[1]*$factor));
      chop $frac[0]; chop $frac[1];
      @frac = (Math::BigInt->new($frac[0]), Math::BigInt->new($frac[1]) );
   } else {
      ($int_part[0], $decimal_part[0]) = $frac[0] =~ /(\d+)\.(\d+)/;
      ($int_part[1], $decimal_part[1]) = $frac[1] =~ /(\d+)\.(\d+)/;
      @decimal_part = sort {$a <=> $b} (length($decimal_part[0]),length($decimal_part[1]) );
      my $factor = 10**$decimal_part[1];
      @frac = ($_[0]*$factor, $_[1]*$factor);
   }
   return @frac;
}

sub _from_decimal {
  my $decimal = shift;       # the decimal (1.312671267127)
  my $big = 'BIG' if ref($decimal);
  my ($repeat);              # flag to keep track if it is repeating or not
  my ($sign);
  my ($factor, $int_factor);
  my ($factor2);
  my ($whole_num, $whole_num_len);
  my ($int_part);                        # integer part (1)
  my ($decimal_part, $decimal_part_len); # decimal part (312671267127)
  my ($decimal_part2);               # decimal part - last bit \/ (312671267)
  my ($pat, $pat_len);               # repeating pat (1267)
  my ($pat_lastb);                   # last bit of repeating pat (127)
  my ($beg_part, $beg_part_len);       # non-repeating part (3)
  my ($other_part, $other_part_len);   # repeating part     (1267126712127)
  my ($frac1, $frac2, $frac3);

  my $rnd_mode = $Math::BigFloat::rnd_mode;  # to avoid problems with incon.
  $Math::BigFloat::rnd_mode = 'trunc';       # rounding

  $decimal = "$decimal";
  $decimal =~ s/\s//g;
  ($sign, $int_part, $decimal_part) = $decimal =~ /([\+\-]?)\s*(\d*)\.(\d+)$/;
  $sign .= '1';
  $decimal_part_len = length($decimal_part);
  $int_part = "" unless $int_part;
  $factor = '1'.'0'x(length($decimal_part));
  $factor = Math::BigFloat->new($factor) if $big;
     # Make it a BigFloat now to simplfy latter
  $int_factor = '1'.'0'x(length($int_part));
  $beg_part_len = 0;
 OuterBlock:
  while ($beg_part_len < $decimal_part_len) {
    $beg_part = substr($decimal_part, 0, $beg_part_len);
    $other_part = substr($decimal_part, $beg_part_len);
    $other_part_len = length($other_part);
    my $i;
    for ($i = 1; $i < ($other_part_len/2+1); $i++) {
      $pat = substr($other_part, 0, $i);
      $pat_len = $i;
      local $_ = $other_part;
      $repeat = undef;
      while (1) {
        ($_) = /^$pat(.*)/;
        my $length = length($_);

        if ( $length <= $pat_len) {
          last unless $length;
          $pat_lastb = substr($pat, 0, $length);
          $repeat=1 ,last OuterBlock if $pat_lastb eq $_;
          if ($pat_lastb eq $_ - 1) {
             # this is needed to see if it really is the repeating fracton
             # we intented it to be.  If we don't do this 1.1212 would become
             # 1120/999 = 1.1211211211.
             # The first three lines converts it to a fraction and the
             # rests tests it to the actual repeating decimal/
             # The NO_REDUCE flag is their to save time as reducing large
             # fraction can take a bit of time which is unnecessary as we will
             # be converting it to a decimal.
            $decimal_part2 = substr($decimal_part, 0, $decimal_part_len - length($pat_lastb));
            $factor2 = '1'.'0'x(length($decimal_part2));
            $frac1 = Math::Fraction->new('0'.$beg_part,"1"."0"x$beg_part_len, 'NO_REDUCE', $big);
            $frac2 = Math::Fraction->new('0'.$pat,"9"x$pat_len."0"x$beg_part_len, 'NO_REDUCE', $big);
            $frac3 = $frac1 + $frac2;
            my $what_i_get = $frac3->decimal;
            my $places = length($what_i_get);
            my $decimal_p_tmp = $decimal_part2                      if not $big;
               $decimal_p_tmp = Math::BigFloat->new($decimal_part2) if  $big;
            my $what_i_should_get = (($decimal_p_tmp)/$factor2)."$pat"x($places);
              # The rest of this is doing nothing more but trying to compare
              # the what_i_get and what_i_should_get but becuse the stupid
              # BigFloat module is so pragmentic all this hopla is nessary
            $what_i_should_get = Math::BigFloat->new($what_i_should_get)           if $big;
            $what_i_should_get = $what_i_should_get->fround(length($what_i_get)-1) if $big;
            $what_i_should_get = Math::BigFloat->new($what_i_should_get)           if $big;
              # ^^ Needed because the dam fround method does not return a
              #    BigFloat object!!!!!!
            my $pass = "$what_i_get" eq "$what_i_should_get" if $big;
               $pass = $what_i_get == $what_i_should_get  if  not $big;
            $repeat=1, last OuterBlock if ($pass);
          }
        }
      }
    }
    $beg_part_len++;
  }

  if ($repeat) {
    $frac1 = Math::Fraction->new('0'.$beg_part,"1"."0"x$beg_part_len, $big);
    $frac2 = Math::Fraction->new('0'.$pat,"9"x$pat_len."0"x$beg_part_len, $big);
    my $int_part = Math::Fraction->new('0'.$int_part, 1, 'BIG') if $big;
    $frac3 = $sign*($int_part + $frac1 + $frac2);
    return @{$frac3->{frac}};
  } else {
    return ($decimal*$factor, $factor, $big);
  }
  $Math::BigFloat::rnd_mode = $rnd_mode;   # set it back to what it was.
}

1;
